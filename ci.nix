{
  # 'supportedSystems' restricts the set of systems that we will evaluate for. Useful when you're evaluting
  # on a machine with e.g. no way to build the Darwin IFDs you need!
  supportedSystems ? [ "x86_64-linux" "x86_64-darwin" ]
, rootsOnly ? false
  # We explicitly pass true here in the GitHub action but don't want to slow down hydra
, checkMaterialization ? false
, sourcesOverride ? { }
, sources ? import ./nix/sources.nix { system = builtins.currentSystem; } // sourcesOverride
, plutus-apps-commit ? { outPath = ./.; rev = "abcdef"; }
}:
let
  inherit (import (sources.plutus-core + "/nix/lib/ci.nix")) dimension platformFilterGeneric filterAttrsOnlyRecursive filterSystems;
  # limit supportedSystems to what the CI can actually build
  # currently that is linux and darwin.
  systems = builtins.listToAttrs (builtins.map (name: { inherit name; value = name; }) supportedSystems);
  crossSystems =
    let pkgs = (import ./default.nix { }).pkgs;
    in { inherit (pkgs.lib.systems.examples) ghcjs; }; # mingwW64; }; # we can't support windows right now, as cross compilation of plugins doesn't work.

  # Collects haskell derivations and builds an attrset:
  #
  # { library = { ... }
  # , tests = { ... }
  # , benchmarks = { ... }
  # , exes = { ... }
  # , checks = { ... }
  # }
  #  Where each attribute contains an attribute set
  #  with all haskell components of that type
  mkHaskellDimension = pkgs: haskellProjects:
    let
      # retrieve all checks from a Haskell package
      collectChecks = _: ps: pkgs.haskell-nix.haskellLib.collectChecks' ps;
      # retrieve all components of a Haskell package
      collectComponents = type: ps: pkgs.haskell-nix.haskellLib.collectComponents' type ps;
      # Given a component type and the retrieve function, retrieve components from haskell packages
      select = type: selector: (selector type) haskellProjects;
      # { component-type : retriever-fn }
      attrs = {
        "library" = collectComponents;
        "tests" = collectComponents;
        "benchmarks" = collectComponents;
        "exes" = collectComponents;
        "checks" = collectChecks;
      };
    in
    dimension "Haskell component" attrs select;

  # Collects all project derivations to build grouped by system:
  #
  # { linux = { ... }
  # , darwin = { ... }
  # }
  mkSystemDimension = systems:
    let
      # given a system ("x86_64-linux") return an attrset of derivations to build
      _select = _: system: crossSystem:
        let
          packages = import ./default.nix { inherit system crossSystem checkMaterialization; };
          pkgs = packages.pkgs;
          plutus-apps = packages.plutus-apps;
          # Map `crossSystem.config` to a name used in `lib.platforms`
          platformString =
            if crossSystem == null then system
            else if crossSystem.config == "x86_64-w64-mingw32" then "x86_64-windows"
            else if crossSystem.config == "js-unknown-ghcjs" then "js-ghcjs"
            else crossSystem.config;
          isBuildable = platformFilterGeneric pkgs platformString;
          filterCross = x:
            if crossSystem == null
            then x
            else {
              # When cross compiling only include haskell for now
              inherit (x) haskell;
            };
          forceNewEval = pkgs.runCommand "forceNewEval"
            {
              text = plutus-apps-commit.rev;
              meta.platforms = [ "x86_64-linux" ];
              preferLocalBuild = true;
              allowSubstitutes = false;
            } ''
            n=$out
            mkdir -p "$(dirname "$n")"
            echo -n "$text" > "$n"
          '';
        in
        filterAttrsOnlyRecursive (_: drv: isBuildable drv) ({
          # The haskell.nix IFD roots for the Haskell project. We include these so they won't be GCd and will be in the
          # cache for users
          inherit (plutus-apps.haskell.project) roots;

          # forceNewEval will generate at least one new job based off the commit hash.
          # This ensures no eval failures because hydra has nothing new to build.
          inherit forceNewEval;
        } // pkgs.lib.optionalAttrs (!rootsOnly) (filterCross {
          # build relevant top level attributes from default.nix
          inherit (packages) docs tests plutus-playground plutus-use-cases;

          # Build the shell expression to be sure it works on all platforms
          #
          # The shell should never depend on any of our Haskell packages, which can
          # sometimes happen by accident. In practice, everything depends transitively
          # on 'plutus-ledger', so this does the job.
          # FIXME: this should simply be set on the main shell derivation, but this breaks
          # lorri: https://github.com/target/lorri/issues/489. In the mean time, we set it
          # only on the CI version, so that we still catch it, but lorri doesn't see it.
          shell = (import ./shell.nix { inherit packages; }).overrideAttrs (attrs: attrs // {
            disallowedRequisites = [ plutus-apps.haskell.packages.plutus-ledger.components.library ];
          });

          # build all haskell packages and tests
          haskell = pkgs.recurseIntoAttrs (mkHaskellDimension pkgs plutus-apps.haskell.projectPackages);
        }));
    in
    dimension "System" systems (name: sys: _select name sys null)
    // dimension "Cross System" crossSystems (name: crossSys: _select name "x86_64-linux" crossSys);
in
mkSystemDimension systems
