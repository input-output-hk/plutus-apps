-- File auto generated by purescript-bridge! --
module Wallet.Types where

import Prelude
import Control.Lazy (defer)
import Data.Argonaut.Core (jsonNull)
import Data.Argonaut.Decode (class DecodeJson)
import Data.Argonaut.Decode.Aeson ((</$\>), (</*\>), (</\>))
import Data.Argonaut.Encode (class EncodeJson, encodeJson)
import Data.Argonaut.Encode.Aeson ((>$<), (>/\<))
import Data.Bounded.Generic (genericBottom, genericTop)
import Data.Enum (class Enum)
import Data.Enum.Generic (genericPred, genericSucc)
import Data.Generic.Rep (class Generic)
import Data.Lens (Iso', Lens', Prism', iso, prism')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype, unwrap)
import Data.RawJson (RawJson)
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested ((/\))
import Data.UUID.Argonaut (UUID)
import Ledger.Constraints.OffChain (MkTxError)
import Plutus.Contract.Checkpoint (CheckpointError)
import Type.Proxy (Proxy(Proxy))
import Wallet.Emulator.Error (WalletAPIError)
import Data.Argonaut.Decode.Aeson as D
import Data.Argonaut.Encode.Aeson as E
import Data.Map as Map

data ContractError
  = WalletError WalletAPIError
  | EmulatorAssertionError AssertionError
  | OtherError String
  | ConstraintResolutionError MkTxError
  | ResumableError MatchingError
  | CCheckpointError CheckpointError

derive instance eqContractError :: Eq ContractError

instance showContractError :: Show ContractError where
  show a = genericShow a

instance encodeJsonContractError :: EncodeJson ContractError where
  encodeJson =
    defer \_ -> case _ of
      WalletError a -> E.encodeTagged "WalletError" a E.value
      EmulatorAssertionError a -> E.encodeTagged "EmulatorAssertionError" a E.value
      OtherError a -> E.encodeTagged "OtherError" a E.value
      ConstraintResolutionError a -> E.encodeTagged "ConstraintResolutionError" a E.value
      ResumableError a -> E.encodeTagged "ResumableError" a E.value
      CCheckpointError a -> E.encodeTagged "CCheckpointError" a E.value

instance decodeJsonContractError :: DecodeJson ContractError where
  decodeJson =
    defer \_ ->
      D.decode
        $ D.sumType "ContractError"
        $ Map.fromFoldable
            [ "WalletError" /\ D.content (WalletError <$> D.value)
            , "EmulatorAssertionError" /\ D.content (EmulatorAssertionError <$> D.value)
            , "OtherError" /\ D.content (OtherError <$> D.value)
            , "ConstraintResolutionError" /\ D.content (ConstraintResolutionError <$> D.value)
            , "ResumableError" /\ D.content (ResumableError <$> D.value)
            , "CCheckpointError" /\ D.content (CCheckpointError <$> D.value)
            ]

derive instance genericContractError :: Generic ContractError _

--------------------------------------------------------------------------------
_WalletError :: Prism' ContractError WalletAPIError
_WalletError =
  prism' WalletError case _ of
    (WalletError a) -> Just a
    _ -> Nothing

_EmulatorAssertionError :: Prism' ContractError AssertionError
_EmulatorAssertionError =
  prism' EmulatorAssertionError case _ of
    (EmulatorAssertionError a) -> Just a
    _ -> Nothing

_OtherError :: Prism' ContractError String
_OtherError =
  prism' OtherError case _ of
    (OtherError a) -> Just a
    _ -> Nothing

_ConstraintResolutionError :: Prism' ContractError MkTxError
_ConstraintResolutionError =
  prism' ConstraintResolutionError case _ of
    (ConstraintResolutionError a) -> Just a
    _ -> Nothing

_ResumableError :: Prism' ContractError MatchingError
_ResumableError =
  prism' ResumableError case _ of
    (ResumableError a) -> Just a
    _ -> Nothing

_CCheckpointError :: Prism' ContractError CheckpointError
_CCheckpointError =
  prism' CCheckpointError case _ of
    (CCheckpointError a) -> Just a
    _ -> Nothing

--------------------------------------------------------------------------------
newtype Notification
  = Notification
  { notificationContractID :: ContractInstanceId
  , notificationContractEndpoint :: EndpointDescription
  , notificationContractArg :: RawJson
  }

derive instance eqNotification :: Eq Notification

instance showNotification :: Show Notification where
  show a = genericShow a

instance encodeJsonNotification :: EncodeJson Notification where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$< ( E.record
              { notificationContractID: E.value :: _ ContractInstanceId
              , notificationContractEndpoint: E.value :: _ EndpointDescription
              , notificationContractArg: E.value :: _ RawJson
              }
          )

instance decodeJsonNotification :: DecodeJson Notification where
  decodeJson =
    defer \_ ->
      D.decode
        $ ( Notification
              <$> D.record "Notification"
                  { notificationContractID: D.value :: _ ContractInstanceId
                  , notificationContractEndpoint: D.value :: _ EndpointDescription
                  , notificationContractArg: D.value :: _ RawJson
                  }
          )

derive instance genericNotification :: Generic Notification _

derive instance newtypeNotification :: Newtype Notification _

--------------------------------------------------------------------------------
_Notification :: Iso' Notification { notificationContractID :: ContractInstanceId, notificationContractEndpoint :: EndpointDescription, notificationContractArg :: RawJson }
_Notification = _Newtype

--------------------------------------------------------------------------------
data NotificationError
  = EndpointNotAvailable ContractInstanceId EndpointDescription
  | MoreThanOneEndpointAvailable ContractInstanceId EndpointDescription
  | InstanceDoesNotExist ContractInstanceId
  | OtherNotificationError ContractError
  | NotificationJSONDecodeError EndpointDescription RawJson String

derive instance eqNotificationError :: Eq NotificationError

instance showNotificationError :: Show NotificationError where
  show a = genericShow a

instance encodeJsonNotificationError :: EncodeJson NotificationError where
  encodeJson =
    defer \_ -> case _ of
      EndpointNotAvailable a b -> E.encodeTagged "EndpointNotAvailable" (a /\ b) (E.tuple (E.value >/\< E.value))
      MoreThanOneEndpointAvailable a b -> E.encodeTagged "MoreThanOneEndpointAvailable" (a /\ b) (E.tuple (E.value >/\< E.value))
      InstanceDoesNotExist a -> E.encodeTagged "InstanceDoesNotExist" a E.value
      OtherNotificationError a -> E.encodeTagged "OtherNotificationError" a E.value
      NotificationJSONDecodeError a b c -> E.encodeTagged "NotificationJSONDecodeError" (a /\ b /\ c) (E.tuple (E.value >/\< E.value >/\< E.value))

instance decodeJsonNotificationError :: DecodeJson NotificationError where
  decodeJson =
    defer \_ ->
      D.decode
        $ D.sumType "NotificationError"
        $ Map.fromFoldable
            [ "EndpointNotAvailable" /\ D.content (D.tuple $ EndpointNotAvailable </$\> D.value </*\> D.value)
            , "MoreThanOneEndpointAvailable" /\ D.content (D.tuple $ MoreThanOneEndpointAvailable </$\> D.value </*\> D.value)
            , "InstanceDoesNotExist" /\ D.content (InstanceDoesNotExist <$> D.value)
            , "OtherNotificationError" /\ D.content (OtherNotificationError <$> D.value)
            , "NotificationJSONDecodeError" /\ D.content (D.tuple $ NotificationJSONDecodeError </$\> D.value </*\> D.value </*\> D.value)
            ]

derive instance genericNotificationError :: Generic NotificationError _

--------------------------------------------------------------------------------
_EndpointNotAvailable :: Prism' NotificationError { a :: ContractInstanceId, b :: EndpointDescription }
_EndpointNotAvailable =
  prism' (\{ a, b } -> (EndpointNotAvailable a b)) case _ of
    (EndpointNotAvailable a b) -> Just { a, b }
    _ -> Nothing

_MoreThanOneEndpointAvailable :: Prism' NotificationError { a :: ContractInstanceId, b :: EndpointDescription }
_MoreThanOneEndpointAvailable =
  prism' (\{ a, b } -> (MoreThanOneEndpointAvailable a b)) case _ of
    (MoreThanOneEndpointAvailable a b) -> Just { a, b }
    _ -> Nothing

_InstanceDoesNotExist :: Prism' NotificationError ContractInstanceId
_InstanceDoesNotExist =
  prism' InstanceDoesNotExist case _ of
    (InstanceDoesNotExist a) -> Just a
    _ -> Nothing

_OtherNotificationError :: Prism' NotificationError ContractError
_OtherNotificationError =
  prism' OtherNotificationError case _ of
    (OtherNotificationError a) -> Just a
    _ -> Nothing

_NotificationJSONDecodeError :: Prism' NotificationError { a :: EndpointDescription, b :: RawJson, c :: String }
_NotificationJSONDecodeError =
  prism' (\{ a, b, c } -> (NotificationJSONDecodeError a b c)) case _ of
    (NotificationJSONDecodeError a b c) -> Just { a, b, c }
    _ -> Nothing

--------------------------------------------------------------------------------
newtype MatchingError
  = WrongVariantError { unWrongVariantError :: String }

derive instance eqMatchingError :: Eq MatchingError

instance showMatchingError :: Show MatchingError where
  show a = genericShow a

instance encodeJsonMatchingError :: EncodeJson MatchingError where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$< ( E.record
              { unWrongVariantError: E.value :: _ String }
          )

instance decodeJsonMatchingError :: DecodeJson MatchingError where
  decodeJson = defer \_ -> D.decode $ (WrongVariantError <$> D.record "WrongVariantError" { unWrongVariantError: D.value :: _ String })

derive instance genericMatchingError :: Generic MatchingError _

derive instance newtypeMatchingError :: Newtype MatchingError _

--------------------------------------------------------------------------------
_WrongVariantError :: Iso' MatchingError { unWrongVariantError :: String }
_WrongVariantError = _Newtype

--------------------------------------------------------------------------------
newtype AssertionError
  = GenericAssertion { unAssertionError :: String }

derive instance eqAssertionError :: Eq AssertionError

instance showAssertionError :: Show AssertionError where
  show a = genericShow a

instance encodeJsonAssertionError :: EncodeJson AssertionError where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$< ( E.record
              { unAssertionError: E.value :: _ String }
          )

instance decodeJsonAssertionError :: DecodeJson AssertionError where
  decodeJson = defer \_ -> D.decode $ (GenericAssertion <$> D.record "GenericAssertion" { unAssertionError: D.value :: _ String })

derive instance genericAssertionError :: Generic AssertionError _

derive instance newtypeAssertionError :: Newtype AssertionError _

--------------------------------------------------------------------------------
_GenericAssertion :: Iso' AssertionError { unAssertionError :: String }
_GenericAssertion = _Newtype

--------------------------------------------------------------------------------
newtype ContractInstanceId
  = ContractInstanceId { unContractInstanceId :: UUID }

derive instance eqContractInstanceId :: Eq ContractInstanceId

derive instance ordContractInstanceId :: Ord ContractInstanceId

instance showContractInstanceId :: Show ContractInstanceId where
  show a = genericShow a

instance encodeJsonContractInstanceId :: EncodeJson ContractInstanceId where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$< ( E.record
              { unContractInstanceId: E.value :: _ UUID }
          )

instance decodeJsonContractInstanceId :: DecodeJson ContractInstanceId where
  decodeJson = defer \_ -> D.decode $ (ContractInstanceId <$> D.record "ContractInstanceId" { unContractInstanceId: D.value :: _ UUID })

derive instance genericContractInstanceId :: Generic ContractInstanceId _

derive instance newtypeContractInstanceId :: Newtype ContractInstanceId _

--------------------------------------------------------------------------------
_ContractInstanceId :: Iso' ContractInstanceId { unContractInstanceId :: UUID }
_ContractInstanceId = _Newtype

--------------------------------------------------------------------------------
data ContractActivityStatus
  = Active
  | Stopped
  | Done

derive instance eqContractActivityStatus :: Eq ContractActivityStatus

derive instance ordContractActivityStatus :: Ord ContractActivityStatus

instance showContractActivityStatus :: Show ContractActivityStatus where
  show a = genericShow a

instance encodeJsonContractActivityStatus :: EncodeJson ContractActivityStatus where
  encodeJson = defer \_ -> E.encode E.enum

instance decodeJsonContractActivityStatus :: DecodeJson ContractActivityStatus where
  decodeJson = defer \_ -> D.decode D.enum

derive instance genericContractActivityStatus :: Generic ContractActivityStatus _

instance enumContractActivityStatus :: Enum ContractActivityStatus where
  succ = genericSucc
  pred = genericPred

instance boundedContractActivityStatus :: Bounded ContractActivityStatus where
  bottom = genericBottom
  top = genericTop

--------------------------------------------------------------------------------
_Active :: Prism' ContractActivityStatus Unit
_Active =
  prism' (const Active) case _ of
    Active -> Just unit
    _ -> Nothing

_Stopped :: Prism' ContractActivityStatus Unit
_Stopped =
  prism' (const Stopped) case _ of
    Stopped -> Just unit
    _ -> Nothing

_Done :: Prism' ContractActivityStatus Unit
_Done =
  prism' (const Done) case _ of
    Done -> Just unit
    _ -> Nothing

--------------------------------------------------------------------------------
newtype EndpointValue a
  = EndpointValue { unEndpointValue :: a }

derive instance eqEndpointValue :: (Eq a) => Eq (EndpointValue a)

instance showEndpointValue :: (Show a) => Show (EndpointValue a) where
  show a = genericShow a

instance encodeJsonEndpointValue :: (EncodeJson a) => EncodeJson (EndpointValue a) where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$< ( E.record
              { unEndpointValue: E.value :: _ a }
          )

instance decodeJsonEndpointValue :: (DecodeJson a) => DecodeJson (EndpointValue a) where
  decodeJson = defer \_ -> D.decode $ (EndpointValue <$> D.record "EndpointValue" { unEndpointValue: D.value :: _ a })

derive instance genericEndpointValue :: Generic (EndpointValue a) _

derive instance newtypeEndpointValue :: Newtype (EndpointValue a) _

--------------------------------------------------------------------------------
_EndpointValue :: forall a. Iso' (EndpointValue a) { unEndpointValue :: a }
_EndpointValue = _Newtype

--------------------------------------------------------------------------------
newtype EndpointDescription
  = EndpointDescription { getEndpointDescription :: String }

instance showEndpointDescription :: Show EndpointDescription where
  show a = genericShow a

derive instance eqEndpointDescription :: Eq EndpointDescription

derive instance ordEndpointDescription :: Ord EndpointDescription

instance encodeJsonEndpointDescription :: EncodeJson EndpointDescription where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$< ( E.record
              { getEndpointDescription: E.value :: _ String }
          )

instance decodeJsonEndpointDescription :: DecodeJson EndpointDescription where
  decodeJson = defer \_ -> D.decode $ (EndpointDescription <$> D.record "EndpointDescription" { getEndpointDescription: D.value :: _ String })

derive instance genericEndpointDescription :: Generic EndpointDescription _

derive instance newtypeEndpointDescription :: Newtype EndpointDescription _

--------------------------------------------------------------------------------
_EndpointDescription :: Iso' EndpointDescription { getEndpointDescription :: String }
_EndpointDescription = _Newtype
