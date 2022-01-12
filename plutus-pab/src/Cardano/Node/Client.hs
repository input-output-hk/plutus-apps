{-# LANGUAGE DataKinds        #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs            #-}
{-# LANGUAGE NamedFieldPuns   #-}
{-# LANGUAGE RankNTypes       #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators    #-}

module Cardano.Node.Client where

import Control.Monad.Freer
import Control.Monad.Freer.Reader (Reader, ask)
import Control.Monad.IO.Class
import Data.Proxy (Proxy (Proxy))
import Ledger.TimeSlot (SlotConfig)
import Servant (NoContent, (:<|>) (..))
import Servant.Client (ClientM, client)

import Cardano.Api.NetworkId.Extra (NetworkIdWrapper (..))
import Cardano.Node.API (API)
import Cardano.Node.Types (ChainSyncHandle, NodeMode (..), PABServerConfig (..), PABServerLogMsg)
import Cardano.Protocol.Socket.Client qualified as Client
import Cardano.Protocol.Socket.Mock.Client qualified as MockClient
import Control.Monad.Freer.Extras.Log (LogMessage)
import Wallet.Effects (NodeClientEffect (..))

healthcheck :: ClientM NoContent
consumeEventHistory :: ClientM [LogMessage PABServerLogMsg]
(healthcheck, consumeEventHistory) =
    ( healthcheck_
    , consumeEventHistory_
    )
  where
    healthcheck_ :<|> consumeEventHistory_ =
        client (Proxy @API)

handleNodeClientClient ::
    forall m effs.
    ( LastMember m effs
    , MonadIO m
    , Member (Reader MockClient.TxSendHandle) effs
    , Member (Reader ChainSyncHandle) effs
    )
    => SlotConfig
    -> NodeClientEffect
    ~> Eff effs
handleNodeClientClient slotCfg e = do
    txSendHandle <- ask @MockClient.TxSendHandle
    chainSyncHandle <- ask @ChainSyncHandle
    case e of
        PublishTx tx  -> liftIO $ MockClient.queueTx txSendHandle tx
        GetClientSlot ->
            either (liftIO . MockClient.getCurrentSlot) (liftIO . Client.getCurrentSlot) chainSyncHandle
        GetClientSlotConfig -> pure slotCfg

-- | This does not seem to support resuming so it means that the slot tick will
-- be behind everything else. This is due to having 2 connections to the node
-- one for chainSync/block transfer and one for chainSync/currentSlot information.
-- TODO: Think about merging the two functionalities, or keep them in sync.
runChainSyncWithCfg ::
     PABServerConfig
  -> IO ChainSyncHandle
runChainSyncWithCfg PABServerConfig { pscSocketPath
                                    , pscNodeMode
                                    , pscNetworkId
                                    , pscSlotConfig } =
    case pscNodeMode of
      AlonzoNode ->
          Right <$> Client.runChainSync' pscSocketPath
                                         pscSlotConfig
                                         (unNetworkIdWrapper pscNetworkId)
                                         []
      MockNode   ->
          Left <$> MockClient.runChainSync' pscSocketPath pscSlotConfig
