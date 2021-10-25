{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DerivingStrategies    #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NamedFieldPuns        #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeApplications      #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE TypeOperators         #-}

module PSGenerator
    ( generate
    ) where

import qualified Auth
import           Control.Applicative                       ((<|>))
import           Control.Lens                              (itraverse, set, (&))
import           Control.Monad                             (void)
import           Control.Monad.Catch                       (MonadMask)
import           Control.Monad.Except                      (MonadError, runExceptT)
import           Control.Monad.Except.Extras               (mapError)
import qualified Control.Monad.Freer.Extras.Log            as Log
import           Control.Monad.IO.Class                    (MonadIO)
import qualified Crowdfunding
import qualified CrowdfundingSimulations
import           Data.Aeson                                (ToJSON, toJSON)
import qualified Data.Aeson                                as JSON
import qualified Data.Aeson.Encode.Pretty                  as JSON
import qualified Data.ByteString                           as BS
import qualified Data.ByteString.Lazy                      as BSL
import           Data.Monoid                               ()
import           Data.Proxy                                (Proxy (Proxy))
import           Data.Text                                 (Text)
import qualified Data.Text.Encoding                        as T (decodeUtf8, encodeUtf8)
import           Data.Time.Units                           (Second)
import qualified ErrorHandling
import qualified ErrorHandlingSimulations
import qualified Game
import qualified GameSimulations
import qualified HelloWorld
import qualified HelloWorldSimulations
import qualified Interpreter                               as Webghc
import           Language.Haskell.Interpreter              (CompilationError, InterpreterError,
                                                            InterpreterResult (InterpreterResult),
                                                            SourceCode (SourceCode), Warning, result, warnings)
import           Language.PureScript.Bridge                (BridgePart, Language (Haskell), SumType, buildBridge, equal,
                                                            genericShow, mkSumType, order, writePSTypes)
import           Language.PureScript.Bridge.TypeParameters (A)
import qualified Ledger.CardanoWallet                      as CW
import           Ledger.Tx.CardanoAPI                       (ToCardanoError)
import qualified PSGenerator.Common
import qualified Playground.API                            as API
import qualified Playground.Interpreter                    as PI
import           Playground.Types                          (CompilationResult (CompilationResult), ContractCall,
                                                            ContractDemo (ContractDemo), Evaluation (Evaluation),
                                                            EvaluationResult, FunctionSchema, KnownCurrency,
                                                            PlaygroundError (InterpreterError), Simulation (Simulation),
                                                            SimulatorAction, SimulatorWallet, contractDemoContext,
                                                            contractDemoEditorContents, contractDemoName,
                                                            contractDemoSimulations, functionSchema, knownCurrencies,
                                                            program, simulationActions, simulationWallets, sourceCode,
                                                            wallets)
import           Playground.Usecases                       (crowdFunding, errorHandling, game, starter, vesting)
import qualified Playground.Usecases                       as Usecases
import           Plutus.Contract.Checkpoint                (CheckpointKey, CheckpointLogMsg)
import           Schema                                    (FormSchema, formArgumentToJson)
import           Servant                                   ((:<|>))
import           Servant.PureScript                        (HasBridge, Settings, apiModuleName, defaultBridge,
                                                            defaultSettings, languageBridge, writeAPIModuleWithSettings)
import qualified Starter
import qualified StarterSimulations
import           System.FilePath                           ((</>))
import qualified Vesting
import qualified VestingSimulations
import           Wallet.API                                (WalletAPIError)
import qualified Wallet.Emulator.Chain                     as EM
import qualified Wallet.Emulator.LogMessages               as EM
import qualified Wallet.Emulator.MultiAgent                as EM
import qualified Wallet.Emulator.NodeClient                as EM
import qualified Wallet.Emulator.Wallet                    as EM
import           Wallet.Rollup.Types                       (AnnotatedTx, BeneficialOwner, DereferencedInput, SequenceId,
                                                            TxKey)

myBridge :: BridgePart
myBridge =
    PSGenerator.Common.aesonBridge <|>
    PSGenerator.Common.containersBridge <|>
    PSGenerator.Common.languageBridge <|>
    PSGenerator.Common.ledgerBridge <|>
    PSGenerator.Common.servantBridge <|>
    PSGenerator.Common.miscBridge <|>
    defaultBridge

data MyBridge

myBridgeProxy :: Proxy MyBridge
myBridgeProxy = Proxy

instance HasBridge MyBridge where
    languageBridge _ = buildBridge myBridge

myTypes :: [SumType 'Haskell]
myTypes =
    PSGenerator.Common.ledgerTypes <>
    PSGenerator.Common.playgroundTypes <>
    [ genericShow $ equal $ mkSumType @CompilationResult
    , genericShow $ equal $ mkSumType @Warning
    , genericShow $ equal $ mkSumType @SourceCode
    , equal $ genericShow $ mkSumType @EM.Wallet
    , equal $ genericShow $ mkSumType @CW.WalletNumber
    , genericShow $ equal $ mkSumType @Simulation
    , genericShow $ equal $ mkSumType @ContractDemo
    , genericShow $ equal $ mkSumType @SimulatorWallet
    , genericShow $ mkSumType @CompilationError
    , genericShow $ mkSumType @Evaluation
    , genericShow $ mkSumType @EvaluationResult
    , genericShow $ mkSumType @EM.EmulatorEvent'
    , genericShow $ mkSumType @(EM.EmulatorTimeEvent A)
    , genericShow $ mkSumType @EM.ChainEvent
    , genericShow $ mkSumType @Log.LogLevel
    , genericShow $ mkSumType @(Log.LogMessage A)
    , genericShow $ mkSumType @EM.WalletEvent
    , genericShow $ mkSumType @EM.NodeClientEvent
    , genericShow $ mkSumType @PlaygroundError
    , equal $ genericShow $ mkSumType @WalletAPIError
    , equal $ genericShow $ mkSumType @ToCardanoError
    , order $ genericShow $ mkSumType @SequenceId
    , equal $ genericShow $ mkSumType @AnnotatedTx
    , equal $ genericShow $ mkSumType @DereferencedInput
    , order $ genericShow $ mkSumType @BeneficialOwner
    , equal $ genericShow $ mkSumType @TxKey
    , genericShow $ mkSumType @InterpreterError
    , genericShow $ equal $ mkSumType @(InterpreterResult A)
    , genericShow $ mkSumType @CheckpointLogMsg
    , genericShow $ mkSumType @CheckpointKey
    , genericShow $ mkSumType @EM.RequestHandlerLogMsg
    , genericShow $ mkSumType @EM.TxBalanceMsg
    ]

mySettings :: Settings
mySettings = defaultSettings & set apiModuleName "Playground.Server"

multilineString :: Text -> Text -> Text
multilineString name value =
    "\n\n" <> name <> " :: String\n" <> name <> " = \"\"\"" <> value <> "\"\"\""

jsonExport :: ToJSON a => Text -> a -> Text
jsonExport name value =
    multilineString name (T.decodeUtf8 . BSL.toStrict $ JSON.encodePretty value)

sourceCodeExport :: Text -> SourceCode -> Text
sourceCodeExport name (SourceCode value) = multilineString name value

psModule :: Text -> Text -> Text
psModule name body = "module " <> name <> " where" <> body

------------------------------------------------------------
writeUsecases :: FilePath -> IO ()
writeUsecases outputDir = do
    let usecases =
            sourceCodeExport "vesting" vesting <>
            sourceCodeExport "game" game <>
            sourceCodeExport "crowdFunding" crowdFunding <>
            sourceCodeExport "errorHandling" errorHandling <>
            sourceCodeExport "starter" starter <>
            jsonExport "contractDemos" contractDemos
        usecasesModule = psModule "Playground.Usecases" usecases
    BS.writeFile
        (outputDir </> "Playground" </> "Usecases.purs")
        (T.encodeUtf8 usecasesModule)

------------------------------------------------------------
writeTestData :: FilePath -> IO ()
writeTestData outputDir = do
    let ContractDemo { contractDemoContext
                     , contractDemoSimulations
                     , contractDemoEditorContents
                     } = head contractDemos
    BSL.writeFile
        (outputDir </> "compilation_response.json")
        (JSON.encodePretty contractDemoContext)
    void $
        itraverse
            (\index ->
                 writeSimulation
                     (outputDir </> "evaluation_response" <>
                      show index <> ".json")
                     contractDemoEditorContents)
            contractDemoSimulations

writeSimulation :: FilePath -> SourceCode -> Simulation -> IO ()
writeSimulation filename sourceCode simulation = do
    result <- runExceptT $ runSimulation sourceCode simulation
    case result of
        Left err   -> fail $ "Error evaluating simulation: " <> show err
        Right json -> BSL.writeFile filename json

maxInterpretationTime :: Second
maxInterpretationTime = 80

runSimulation ::
       (MonadMask m, MonadError PlaygroundError m, MonadIO m)
    => SourceCode
    -> Simulation
    -> m BSL.ByteString
runSimulation sourceCode Simulation {simulationActions, simulationWallets} = do
    let evaluation =
            Evaluation
                { sourceCode
                , wallets = simulationWallets
                , program =
                      toJSON . encodeToText $ toExpression <$> simulationActions
                }
    expr <- PI.evaluationToExpr evaluation
    result <- mapError InterpreterError $ Webghc.compile maxInterpretationTime False (SourceCode expr)
    interpreterResult <- PI.decodeEvaluation result
    pure $ JSON.encodePretty interpreterResult

encodeToText :: ToJSON a => a -> Text
encodeToText = T.decodeUtf8 . BSL.toStrict . JSON.encode

toExpression :: SimulatorAction -> Maybe (ContractCall Text)
toExpression = traverse (fmap encodeToText . formArgumentToJson)

------------------------------------------------------------
generate :: FilePath -> IO ()
generate outputDir = do
    writePSTypes outputDir (buildBridge myBridge) myTypes
    writeAPIModuleWithSettings
        mySettings
        outputDir
        myBridgeProxy
        (Proxy
             @(API.API
               :<|> Auth.FrontendAPI))
    writeUsecases outputDir
    writeTestData outputDir
    putStrLn $ "Done: " <> outputDir

------------------------------------------------------------
contractDemos :: [ContractDemo]
contractDemos =
    [ mkContractDemo
        "Hello, world"
        Usecases.helloWorld
        HelloWorldSimulations.simulations
        HelloWorld.schemas
        HelloWorld.registeredKnownCurrencies
    , mkContractDemo
          "Starter"
          Usecases.starter
          StarterSimulations.simulations
          Starter.schemas
          Starter.registeredKnownCurrencies
    , mkContractDemo
          "Game"
          Usecases.game
          GameSimulations.simulations
          Game.schemas
          Game.registeredKnownCurrencies
    , mkContractDemo
          "Vesting"
          Usecases.vesting
          VestingSimulations.simulations
          Vesting.schemas
          Vesting.registeredKnownCurrencies
    , mkContractDemo
          "Crowd Funding"
          Usecases.crowdFunding
          CrowdfundingSimulations.simulations
          Crowdfunding.schemas
          Crowdfunding.registeredKnownCurrencies
    , mkContractDemo
          "Error Handling"
          Usecases.errorHandling
          ErrorHandlingSimulations.simulations
          ErrorHandling.schemas
          ErrorHandling.registeredKnownCurrencies
    ]

mkContractDemo ::
       Text
    -> SourceCode
    -> [Simulation]
    -> [FunctionSchema FormSchema]
    -> [KnownCurrency]
    -> ContractDemo
mkContractDemo contractDemoName contractDemoEditorContents contractDemoSimulations functionSchema knownCurrencies =
    ContractDemo
        { contractDemoName
        , contractDemoEditorContents
        , contractDemoSimulations
        , contractDemoContext =
              InterpreterResult
                  { warnings = []
                  , result =
                        CompilationResult
                            {functionSchema, knownCurrencies}
                  }
        }
