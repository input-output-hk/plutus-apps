-- File auto generated by purescript-bridge! --
module Ledger.Blockchain where

import Prelude

import Control.Lazy (defer)
import Data.Argonaut (encodeJson, jsonNull)
import Data.Argonaut.Decode (class DecodeJson)
import Data.Argonaut.Decode.Aeson ((</$\>), (</*\>), (</\>))
import Data.Argonaut.Encode (class EncodeJson)
import Data.Argonaut.Encode.Aeson ((>$<), (>/\<))
import Data.Generic.Rep (class Generic)
import Data.Lens (Iso', Lens', Prism', iso, prism')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype, unwrap)
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested ((/\))
import Ledger.Tx.Types.Tx (Tx)
import Type.Proxy (Proxy(Proxy))
import Data.Argonaut.Decode.Aeson as D
import Data.Argonaut.Encode.Aeson as E
import Data.Map as Map

newtype BlockId = BlockId { getBlockId :: String }

derive instance Eq BlockId

derive instance Ord BlockId

instance Show BlockId where
  show a = genericShow a

instance EncodeJson BlockId where
  encodeJson = defer \_ -> E.encode $ unwrap >$<
    ( E.record
        { getBlockId: E.value :: _ String }
    )

instance DecodeJson BlockId where
  decodeJson = defer \_ -> D.decode $ (BlockId <$> D.record "BlockId" { getBlockId: D.value :: _ String })

derive instance Generic BlockId _

derive instance Newtype BlockId _

--------------------------------------------------------------------------------

_BlockId :: Iso' BlockId { getBlockId :: String }
_BlockId = _Newtype

--------------------------------------------------------------------------------

data OnChainTx
  = Invalid Tx
  | Valid Tx

derive instance Eq OnChainTx

instance Show OnChainTx where
  show a = genericShow a

instance EncodeJson OnChainTx where
  encodeJson = defer \_ -> case _ of
    Invalid a -> E.encodeTagged "Invalid" a E.value
    Valid a -> E.encodeTagged "Valid" a E.value

instance DecodeJson OnChainTx where
  decodeJson = defer \_ -> D.decode
    $ D.sumType "OnChainTx"
    $ Map.fromFoldable
        [ "Invalid" /\ D.content (Invalid <$> D.value)
        , "Valid" /\ D.content (Valid <$> D.value)
        ]

derive instance Generic OnChainTx _

--------------------------------------------------------------------------------

_Invalid :: Prism' OnChainTx Tx
_Invalid = prism' Invalid case _ of
  (Invalid a) -> Just a
  _ -> Nothing

_Valid :: Prism' OnChainTx Tx
_Valid = prism' Valid case _ of
  (Valid a) -> Just a
  _ -> Nothing
