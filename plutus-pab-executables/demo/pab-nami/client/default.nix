{ purs-tidy, pkgs, gitignore-nix, haskell, webCommon, buildPursPackage, buildNodeModules, filterNpm }:
let
  pab-nami-demo-invoker = haskell.packages.plutus-pab-executables.components.exes.plutus-pab-nami-demo;
  pab-nami-demo-generator = haskell.packages.plutus-pab-executables.components.exes.plutus-pab-nami-demo-generator;

  pab-setup-invoker = haskell.packages.plutus-pab-executables.components.exes.plutus-pab-setup;

  generate-purescript = pkgs.writeShellScript "pab-nami-demo-generate-purs" ''
    if [ "$#" -ne 1 ]; then
      echo usage: pab-nami-demo-generate-purs GENERATED_DIR
      exit 1
    fi

    generatedDir="$1"
    rm -rf $generatedDir

    echo Generating purescript files in $generatedDir
    ${pab-nami-demo-generator}/bin/plutus-pab-nami-demo-generator --output-dir $generatedDir
    echo Done generating purescript files
    echo
    echo Formatting purescript files in $generatedDir
    ${purs-tidy}/bin/purs-tidy format-in-place $generatedDir
    echo Done formatting purescript files
  '';

  purescript-generated = pkgs.runCommand "pab-nami-demo-generate-purs" { } ''
    ${generate-purescript} $out
  '';

  start-backend = pkgs.writeShellScriptBin "pab-nami-demo-server" ''
    if [ ! -d plutus-pab-executables ]; then 
      echo Please run pab-nami-demo-server from the root of the repository
      exit 1
    fi

    generatedDir=./plutus-pab-executables/demo/pab-nami/client/generated

    if [ ! -d $generatedDir ] || [ "$1" == "-g" ]; then 
      ${generate-purescript} $generatedDir
    fi 

    dirAge=$(datediff now $(date -r $generatedDir +%F))
    echo
    echo "*** Using Purescript files in $generatedDir which are $dirAge days old."
    echo "*** To regenerate, run pab-nami-demo-server -g"
    echo
    echo
    echo pab-nami-demo-server: for development use only

    configFile=./plutus-pab-executables/demo/pab-nami/pab/plutus-pab.yaml

    ${pab-nami-demo-invoker}/bin/plutus-pab-nami-demo --config $configFile migrate
    ${pab-nami-demo-invoker}/bin/plutus-pab-nami-demo --config $configFile webserver
  '';

  # Note that this ignores the generated folder too, but it's fine since it is 
  # added via extraSrcs 
  cleanSrc = gitignore-nix.gitignoreSource ./.;

  nodeModules = buildNodeModules {
    projectDir = filterNpm cleanSrc;
    packageJson = ./package.json;
    packageLockJson = ./package-lock.json;
    githubSourceHashMap = { };
  };

  client = pkgs.lib.overrideDerivation
    (buildPursPackage {
      inherit pkgs nodeModules;
      src = cleanSrc;
      extraSrcs = {
        generated = purescript-generated;
      };
      checkPhase = ''
        node -e 'require("./output/Test.Main").main()'
      '';
      name = "pab-nami-demo";
      spagoPackages = pkgs.callPackage ./spago-packages.nix { };
    })
    (_: {
      WEB_COMMON_SRC = webCommon.cleanSrc;
    });
in
{
  inherit client pab-nami-demo-invoker pab-setup-invoker start-backend;
}
