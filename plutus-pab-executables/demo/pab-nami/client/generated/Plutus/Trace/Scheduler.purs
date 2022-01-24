-- File auto generated by purescript-bridge! --
module Plutus.Trace.Scheduler where

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
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested ((/\))
import Plutus.Trace.Tag (Tag)
import Type.Proxy (Proxy(Proxy))
import Data.Argonaut.Decode.Aeson as D
import Data.Argonaut.Encode.Aeson as E
import Data.Map as Map

newtype SchedulerLog
  = SchedulerLog
  { slEvent :: ThreadEvent
  , slThread :: ThreadId
  , slTag :: Tag
  , slPrio :: Priority
  }

derive instance eqSchedulerLog :: Eq SchedulerLog

instance showSchedulerLog :: Show SchedulerLog where
  show a = genericShow a

instance encodeJsonSchedulerLog :: EncodeJson SchedulerLog where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$<
          ( E.record
              { slEvent: E.value :: _ ThreadEvent
              , slThread: E.value :: _ ThreadId
              , slTag: E.value :: _ Tag
              , slPrio: E.value :: _ Priority
              }
          )

instance decodeJsonSchedulerLog :: DecodeJson SchedulerLog where
  decodeJson =
    defer \_ ->
      D.decode
        $
          ( SchedulerLog
              <$> D.record "SchedulerLog"
                { slEvent: D.value :: _ ThreadEvent
                , slThread: D.value :: _ ThreadId
                , slTag: D.value :: _ Tag
                , slPrio: D.value :: _ Priority
                }
          )

derive instance genericSchedulerLog :: Generic SchedulerLog _

derive instance newtypeSchedulerLog :: Newtype SchedulerLog _

--------------------------------------------------------------------------------
_SchedulerLog :: Iso' SchedulerLog { slEvent :: ThreadEvent, slThread :: ThreadId, slTag :: Tag, slPrio :: Priority }
_SchedulerLog = _Newtype

--------------------------------------------------------------------------------
data ThreadEvent
  = Stopped StopReason
  | Resumed
  | Suspended
  | Started
  | Thawed

derive instance eqThreadEvent :: Eq ThreadEvent

instance showThreadEvent :: Show ThreadEvent where
  show a = genericShow a

instance encodeJsonThreadEvent :: EncodeJson ThreadEvent where
  encodeJson =
    defer \_ -> case _ of
      Stopped a -> E.encodeTagged "Stopped" a E.value
      Resumed -> encodeJson { tag: "Resumed", contents: jsonNull }
      Suspended -> encodeJson { tag: "Suspended", contents: jsonNull }
      Started -> encodeJson { tag: "Started", contents: jsonNull }
      Thawed -> encodeJson { tag: "Thawed", contents: jsonNull }

instance decodeJsonThreadEvent :: DecodeJson ThreadEvent where
  decodeJson =
    defer \_ ->
      D.decode
        $ D.sumType "ThreadEvent"
        $ Map.fromFoldable
            [ "Stopped" /\ D.content (Stopped <$> D.value)
            , "Resumed" /\ pure Resumed
            , "Suspended" /\ pure Suspended
            , "Started" /\ pure Started
            , "Thawed" /\ pure Thawed
            ]

derive instance genericThreadEvent :: Generic ThreadEvent _

--------------------------------------------------------------------------------
_Stopped :: Prism' ThreadEvent StopReason
_Stopped =
  prism' Stopped case _ of
    (Stopped a) -> Just a
    _ -> Nothing

_Resumed :: Prism' ThreadEvent Unit
_Resumed =
  prism' (const Resumed) case _ of
    Resumed -> Just unit
    _ -> Nothing

_Suspended :: Prism' ThreadEvent Unit
_Suspended =
  prism' (const Suspended) case _ of
    Suspended -> Just unit
    _ -> Nothing

_Started :: Prism' ThreadEvent Unit
_Started =
  prism' (const Started) case _ of
    Started -> Just unit
    _ -> Nothing

_Thawed :: Prism' ThreadEvent Unit
_Thawed =
  prism' (const Thawed) case _ of
    Thawed -> Just unit
    _ -> Nothing

--------------------------------------------------------------------------------
newtype ThreadId
  = ThreadId { unThreadId :: Int }

derive instance eqThreadId :: Eq ThreadId

instance showThreadId :: Show ThreadId where
  show a = genericShow a

instance encodeJsonThreadId :: EncodeJson ThreadId where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$<
          ( E.record
              { unThreadId: E.value :: _ Int }
          )

instance decodeJsonThreadId :: DecodeJson ThreadId where
  decodeJson = defer \_ -> D.decode $ (ThreadId <$> D.record "ThreadId" { unThreadId: D.value :: _ Int })

derive instance genericThreadId :: Generic ThreadId _

derive instance newtypeThreadId :: Newtype ThreadId _

--------------------------------------------------------------------------------
_ThreadId :: Iso' ThreadId { unThreadId :: Int }
_ThreadId = _Newtype

--------------------------------------------------------------------------------
data Priority
  = Normal
  | Sleeping
  | Frozen

derive instance eqPriority :: Eq Priority

derive instance ordPriority :: Ord Priority

instance showPriority :: Show Priority where
  show a = genericShow a

instance encodeJsonPriority :: EncodeJson Priority where
  encodeJson = defer \_ -> E.encode E.enum

instance decodeJsonPriority :: DecodeJson Priority where
  decodeJson = defer \_ -> D.decode D.enum

derive instance genericPriority :: Generic Priority _

instance enumPriority :: Enum Priority where
  succ = genericSucc
  pred = genericPred

instance boundedPriority :: Bounded Priority where
  bottom = genericBottom
  top = genericTop

--------------------------------------------------------------------------------
_Normal :: Prism' Priority Unit
_Normal =
  prism' (const Normal) case _ of
    Normal -> Just unit
    _ -> Nothing

_Sleeping :: Prism' Priority Unit
_Sleeping =
  prism' (const Sleeping) case _ of
    Sleeping -> Just unit
    _ -> Nothing

_Frozen :: Prism' Priority Unit
_Frozen =
  prism' (const Frozen) case _ of
    Frozen -> Just unit
    _ -> Nothing

--------------------------------------------------------------------------------
data StopReason
  = ThreadDone
  | ThreadExit

derive instance eqStopReason :: Eq StopReason

derive instance ordStopReason :: Ord StopReason

instance showStopReason :: Show StopReason where
  show a = genericShow a

instance encodeJsonStopReason :: EncodeJson StopReason where
  encodeJson = defer \_ -> E.encode E.enum

instance decodeJsonStopReason :: DecodeJson StopReason where
  decodeJson = defer \_ -> D.decode D.enum

derive instance genericStopReason :: Generic StopReason _

instance enumStopReason :: Enum StopReason where
  succ = genericSucc
  pred = genericPred

instance boundedStopReason :: Bounded StopReason where
  bottom = genericBottom
  top = genericTop

--------------------------------------------------------------------------------
_ThreadDone :: Prism' StopReason Unit
_ThreadDone =
  prism' (const ThreadDone) case _ of
    ThreadDone -> Just unit
    _ -> Nothing

_ThreadExit :: Prism' StopReason Unit
_ThreadExit =
  prism' (const ThreadExit) case _ of
    ThreadExit -> Just unit
    _ -> Nothing
