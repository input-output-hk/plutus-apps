{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE LambdaCase          #-}
{-# LANGUAGE MonoLocalBinds      #-}
{-# LANGUAGE NamedFieldPuns      #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE RankNTypes          #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications    #-}

module Playground.Interpreter.Util
    ( stage
    , renderInstanceTrace
    ) where

import Control.Foldl qualified as L
import Control.Lens (Traversal', preview)
import Control.Monad (void)
import Control.Monad.Freer (run)
import Control.Monad.Freer.Error (Error, runError, throwError)
import Data.Aeson (FromJSON, eitherDecode)
import Data.Aeson qualified as JSON
import Data.Bifunctor (first)
import Data.ByteString.Lazy (ByteString)
import Data.ByteString.Lazy.Char8 qualified as BSL
import Data.Foldable (traverse_)
import Data.Map (Map)
import Data.Map qualified as Map
import Data.Maybe (isJust)
import Data.Text (Text)

import Data.Default (Default (def))
import Data.Text.Encoding qualified as Text
import Data.Text.Prettyprint.Doc (defaultLayoutOptions, layoutPretty, pretty, vsep)
import Data.Text.Prettyprint.Doc.Render.Text (renderStrict)
import Ledger.Value (Value)
import Playground.Types (ContractCall (AddBlocks, AddBlocksUntil, CallEndpoint, PayToWallet), EvaluationResult,
                         Expression, FunctionSchema (FunctionSchema), PlaygroundError (JsonDecodingError, OtherError),
                         SimulatorWallet (SimulatorWallet), amount, argument, argumentValues, caller, decodingError,
                         endpointDescription, expected, input, recipient, sender, simulatorWalletWallet)
import Playground.Types qualified
import Plutus.Contract (Contract)
import Plutus.Trace (ContractConstraints, ContractInstanceTag)
import Plutus.Trace.Emulator.Types (EmulatorRuntimeError (EmulatorJSONDecodingError), _ContractLog,
                                    _ReceiveEndpointCall, cilMessage)
import Plutus.Trace.Playground (PlaygroundTrace, runPlaygroundStream, walletInstanceTag)
import Plutus.Trace.Playground qualified
import Plutus.Trace.Playground qualified as Trace
import Streaming.Prelude (fst')
import Wallet.Emulator.Folds (EmulatorEventFoldM)
import Wallet.Emulator.Folds qualified as Folds
import Wallet.Emulator.MultiAgent (EmulatorEvent, chainEvent, eteEvent, instanceEvent)
import Wallet.Emulator.Stream (foldEmulatorStreamM)
import Wallet.Emulator.Types (Wallet, WalletNumber, fromWalletNumber, walletPubKeyHash)
import Wallet.Types (EndpointDescription (getEndpointDescription))

-- | Unfortunately any uncaught errors in the interpreter kill the
-- thread that is running it rather than returning the error. This
-- means we need to handle all expected errors in the expression we
-- are interpreting. This gets a little tricky because we have to
-- decode JSON inside the interpreter (since we don't have access to
-- it's type outside) so we need to wrap the @apply functions up in
-- something that can throw errors.
playgroundDecode ::
       FromJSON a => String -> ByteString -> Either PlaygroundError a
playgroundDecode expected input =
    first
        (\err ->
             JsonDecodingError
                 {expected, input = BSL.unpack input, decodingError = err}) $
    eitherDecode input

funds :: [WalletNumber] -> EmulatorEventFoldM effs (Map WalletNumber Value)
funds = L.generalize . sequenceA . Map.fromList . fmap (\w -> (w, Folds.walletFunds (fromWalletNumber w)))

fees :: [WalletNumber] -> EmulatorEventFoldM effs (Map WalletNumber Value)
fees = L.generalize . sequenceA . Map.fromList . fmap (\w -> (w, Folds.walletFees (fromWalletNumber w)))

renderInstanceTrace :: [ContractInstanceTag] -> EmulatorEventFoldM effs Text
renderInstanceTrace =
    L.generalize
    . fmap (renderStrict . layoutPretty defaultLayoutOptions . vsep . fmap pretty)
    . traverse Folds.instanceLog

-- Events that are of interest to users of the Playground
isInteresting :: EmulatorEvent -> Bool
isInteresting x =
    let matches :: Traversal' s a -> s -> Bool
        matches p = isJust . preview p in
    matches (eteEvent . chainEvent) x
    || matches (eteEvent . instanceEvent . cilMessage . _ReceiveEndpointCall) x
    || matches (eteEvent . instanceEvent . cilMessage . _ContractLog) x

evaluationResultFold :: [WalletNumber] -> EmulatorEventFoldM effs EvaluationResult
evaluationResultFold wallets =
    let pkh wallet = (walletPubKeyHash $ fromWalletNumber wallet, wallet)
    in Playground.Types.EvaluationResult
            <$> L.generalize (reverse <$> Folds.annotatedBlockchain)
            <*> L.generalize (filter isInteresting <$> Folds.emulatorLog)
            <*> renderInstanceTrace (walletInstanceTag . fromWalletNumber <$> wallets)
            <*> fmap (fmap (uncurry SimulatorWallet) . Map.toList) (funds wallets)
            <*> fmap (fmap (uncurry SimulatorWallet) . Map.toList) (fees wallets)
            <*> pure (fmap pkh wallets)

-- | Evaluate a JSON payload from the Playground frontend against a given contract schema.
stage ::
       forall w s a.
       ( ContractConstraints s
       , JSON.ToJSON w
       , Monoid w
       )
    => Contract w s Text a
    -> BSL.ByteString
    -> BSL.ByteString
    -> Either PlaygroundError EvaluationResult
stage contract programJson simulatorWalletsJson = do
    simulationJson :: String <- playgroundDecode "String" programJson
    simulation :: [Expression] <-
        playgroundDecode "[Expression schema]" . BSL.pack $ simulationJson
    simulatorWallets :: [SimulatorWallet] <-
        playgroundDecode "[SimulatorWallet]" simulatorWalletsJson
    let config = Plutus.Trace.Playground.EmulatorConfig (Left $ toInitialDistribution simulatorWallets) def def
        allWallets = simulatorWalletWallet <$> simulatorWallets
        final = run
            $ runError
            $ foldEmulatorStreamM @'[Error PlaygroundError] (evaluationResultFold allWallets)
            $ runPlaygroundStream config (void contract) (traverse_ expressionToTrace simulation)

    case final of
        Left err     -> Left . OtherError . show $ err
        Right result -> Right (fst' result)

toInitialDistribution :: [SimulatorWallet] -> Map Wallet Value
toInitialDistribution = Map.fromList . fmap (\(SimulatorWallet w v) -> (fromWalletNumber w, v))

expressionToTrace :: Expression -> PlaygroundTrace ()
expressionToTrace = \case
    AddBlocks blcks -> void $ Trace.waitNSlots $ fromIntegral blcks
    AddBlocksUntil slot -> void $ Trace.waitUntilSlot slot
    PayToWallet {sender, recipient, amount} -> void $ Trace.payToWallet (fromWalletNumber sender) (fromWalletNumber recipient) amount
    CallEndpoint {caller, argumentValues=FunctionSchema { endpointDescription, argument = rawArgument}} ->
        let fromString (JSON.String string) = Just $ BSL.fromStrict $ Text.encodeUtf8 string
            fromString _                    = Nothing
        in case fromString rawArgument of
            Just string ->
                case JSON.eitherDecode string of
                    Left errs ->
                        throwError
                            $ EmulatorJSONDecodingError
                              ("Error extracting JSON from arguments. Expected an array of JSON strings. " <>
                        show errs)
                              rawArgument
                    Right argument -> do
                        Trace.callEndpoint (fromWalletNumber caller) (getEndpointDescription endpointDescription) argument
            Nothing ->
                throwError
                    $ EmulatorJSONDecodingError
                      ("Expected a String, but got: " <> show rawArgument)
                      rawArgument
