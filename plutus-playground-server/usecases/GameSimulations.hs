{-# LANGUAGE NamedFieldPuns     #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings  #-}

module GameSimulations where

import Game (GuessParams (GuessParams), LockParams (LockParams), amount, guessWord, registeredKnownCurrencies,
             secretWord)
import Ledger.Ada qualified as Ada
import Playground.Types (ContractCall (AddBlocks), Simulation (Simulation), SimulatorAction, simulationActions,
                         simulationId, simulationName, simulationWallets)
import SimulationUtils (callEndpoint, simulatorWallet)
import Wallet.Emulator.Types (WalletNumber (..))

simulations :: [Simulation]
simulations = [basicGame, badGuess]
  where
    wallet1 = WalletNumber 1
    wallet2 = WalletNumber 2
    wallet3 = WalletNumber 3
    basicGame =
        Simulation
            { simulationName = "Basic Game"
            , simulationId = 1
            , simulationWallets = simulatorWallet registeredKnownCurrencies 100_000_000 <$> [wallet1, wallet2]
            , simulationActions =
                  [ lock wallet1 "Plutus" 50_000_000
                  , AddBlocks 1
                  , guess wallet2 "Plutus"
                  , AddBlocks 1
                  ]
            }
    badGuess =
        Simulation
            { simulationName = "One Bad Guess"
            , simulationId = 2
            , simulationWallets = simulatorWallet registeredKnownCurrencies 100_000_000 <$> [wallet1, wallet2, wallet3]
            , simulationActions =
                  [ lock wallet1 "Plutus" 50_000_000
                  , AddBlocks 1
                  , guess wallet2 "Marlowe"
                  , AddBlocks 1
                  , guess wallet3 "Plutus"
                  , AddBlocks 1
                  ]
            }

lock :: WalletNumber -> String -> Integer -> SimulatorAction
lock caller secretWord balance =
    callEndpoint
        caller
        "lock"
        LockParams {secretWord, amount = Ada.lovelaceValueOf balance}

guess :: WalletNumber -> String -> SimulatorAction
guess caller guessWord = callEndpoint caller "guess" (GuessParams {guessWord})
