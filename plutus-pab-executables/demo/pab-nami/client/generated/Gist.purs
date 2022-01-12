-- File auto generated by purescript-bridge! --
module Gist where

import Prelude
import Control.Lazy (defer)
import Data.Argonaut.Core (jsonNull)
import Data.Argonaut.Decode (class DecodeJson)
import Data.Argonaut.Decode.Aeson ((</$\>), (</*\>), (</\>))
import Data.Argonaut.Encode (class EncodeJson, encodeJson)
import Data.Argonaut.Encode.Aeson ((>$<), (>/\<))
import Data.Generic.Rep (class Generic)
import Data.Lens (Iso', Lens', Prism', iso, prism')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Map (Map)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype, unwrap)
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested ((/\))
import Type.Proxy (Proxy(Proxy))
import Data.Argonaut.Decode.Aeson as D
import Data.Argonaut.Encode.Aeson as E
import Data.Map as Map

newtype GistId
  = GistId String

derive instance eqGistId :: Eq GistId

derive instance ordGistId :: Ord GistId

instance showGistId :: Show GistId where
  show a = genericShow a

instance encodeJsonGistId :: EncodeJson GistId where
  encodeJson = defer \_ -> E.encode $ unwrap >$< E.value

instance decodeJsonGistId :: DecodeJson GistId where
  decodeJson = defer \_ -> D.decode $ (GistId <$> D.value)

derive instance genericGistId :: Generic GistId _

derive instance newtypeGistId :: Newtype GistId _

--------------------------------------------------------------------------------
_GistId :: Iso' GistId String
_GistId = _Newtype

--------------------------------------------------------------------------------
newtype Gist
  = Gist
  { _gistId :: GistId
  , _gistGitPushUrl :: String
  , _gistHtmlUrl :: String
  , _gistOwner :: Owner
  , _gistFiles :: Map String GistFile
  , _gistTruncated :: Boolean
  , _gistCreatedAt :: String
  , _gistUpdatedAt :: String
  , _gistDescription :: String
  }

derive instance eqGist :: Eq Gist

instance showGist :: Show Gist where
  show a = genericShow a

instance encodeJsonGist :: EncodeJson Gist where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$< ( E.record
              { _gistId: E.value :: _ GistId
              , _gistGitPushUrl: E.value :: _ String
              , _gistHtmlUrl: E.value :: _ String
              , _gistOwner: E.value :: _ Owner
              , _gistFiles: (E.dictionary E.value E.value) :: _ (Map String GistFile)
              , _gistTruncated: E.value :: _ Boolean
              , _gistCreatedAt: E.value :: _ String
              , _gistUpdatedAt: E.value :: _ String
              , _gistDescription: E.value :: _ String
              }
          )

instance decodeJsonGist :: DecodeJson Gist where
  decodeJson =
    defer \_ ->
      D.decode
        $ ( Gist
              <$> D.record "Gist"
                  { _gistId: D.value :: _ GistId
                  , _gistGitPushUrl: D.value :: _ String
                  , _gistHtmlUrl: D.value :: _ String
                  , _gistOwner: D.value :: _ Owner
                  , _gistFiles: (D.dictionary D.value D.value) :: _ (Map String GistFile)
                  , _gistTruncated: D.value :: _ Boolean
                  , _gistCreatedAt: D.value :: _ String
                  , _gistUpdatedAt: D.value :: _ String
                  , _gistDescription: D.value :: _ String
                  }
          )

derive instance genericGist :: Generic Gist _

derive instance newtypeGist :: Newtype Gist _

--------------------------------------------------------------------------------
_Gist :: Iso' Gist { _gistId :: GistId, _gistGitPushUrl :: String, _gistHtmlUrl :: String, _gistOwner :: Owner, _gistFiles :: Map String GistFile, _gistTruncated :: Boolean, _gistCreatedAt :: String, _gistUpdatedAt :: String, _gistDescription :: String }
_Gist = _Newtype

gistId :: Lens' Gist GistId
gistId = _Newtype <<< prop (Proxy :: _ "_gistId")

gistGitPushUrl :: Lens' Gist String
gistGitPushUrl = _Newtype <<< prop (Proxy :: _ "_gistGitPushUrl")

gistHtmlUrl :: Lens' Gist String
gistHtmlUrl = _Newtype <<< prop (Proxy :: _ "_gistHtmlUrl")

gistOwner :: Lens' Gist Owner
gistOwner = _Newtype <<< prop (Proxy :: _ "_gistOwner")

gistFiles :: Lens' Gist (Map String GistFile)
gistFiles = _Newtype <<< prop (Proxy :: _ "_gistFiles")

gistTruncated :: Lens' Gist Boolean
gistTruncated = _Newtype <<< prop (Proxy :: _ "_gistTruncated")

gistCreatedAt :: Lens' Gist String
gistCreatedAt = _Newtype <<< prop (Proxy :: _ "_gistCreatedAt")

gistUpdatedAt :: Lens' Gist String
gistUpdatedAt = _Newtype <<< prop (Proxy :: _ "_gistUpdatedAt")

gistDescription :: Lens' Gist String
gistDescription = _Newtype <<< prop (Proxy :: _ "_gistDescription")

--------------------------------------------------------------------------------
newtype GistFile
  = GistFile
  { _gistFileFilename :: String
  , _gistFileLanguage :: Maybe String
  , _gistFileType :: String
  , _gistFileTruncated :: Maybe Boolean
  , _gistFileContent :: Maybe String
  }

derive instance eqGistFile :: Eq GistFile

instance showGistFile :: Show GistFile where
  show a = genericShow a

instance encodeJsonGistFile :: EncodeJson GistFile where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$< ( E.record
              { _gistFileFilename: E.value :: _ String
              , _gistFileLanguage: (E.maybe E.value) :: _ (Maybe String)
              , _gistFileType: E.value :: _ String
              , _gistFileTruncated: (E.maybe E.value) :: _ (Maybe Boolean)
              , _gistFileContent: (E.maybe E.value) :: _ (Maybe String)
              }
          )

instance decodeJsonGistFile :: DecodeJson GistFile where
  decodeJson =
    defer \_ ->
      D.decode
        $ ( GistFile
              <$> D.record "GistFile"
                  { _gistFileFilename: D.value :: _ String
                  , _gistFileLanguage: (D.maybe D.value) :: _ (Maybe String)
                  , _gistFileType: D.value :: _ String
                  , _gistFileTruncated: (D.maybe D.value) :: _ (Maybe Boolean)
                  , _gistFileContent: (D.maybe D.value) :: _ (Maybe String)
                  }
          )

derive instance genericGistFile :: Generic GistFile _

derive instance newtypeGistFile :: Newtype GistFile _

--------------------------------------------------------------------------------
_GistFile :: Iso' GistFile { _gistFileFilename :: String, _gistFileLanguage :: Maybe String, _gistFileType :: String, _gistFileTruncated :: Maybe Boolean, _gistFileContent :: Maybe String }
_GistFile = _Newtype

gistFileFilename :: Lens' GistFile String
gistFileFilename = _Newtype <<< prop (Proxy :: _ "_gistFileFilename")

gistFileLanguage :: Lens' GistFile (Maybe String)
gistFileLanguage = _Newtype <<< prop (Proxy :: _ "_gistFileLanguage")

gistFileType :: Lens' GistFile String
gistFileType = _Newtype <<< prop (Proxy :: _ "_gistFileType")

gistFileTruncated :: Lens' GistFile (Maybe Boolean)
gistFileTruncated = _Newtype <<< prop (Proxy :: _ "_gistFileTruncated")

gistFileContent :: Lens' GistFile (Maybe String)
gistFileContent = _Newtype <<< prop (Proxy :: _ "_gistFileContent")

--------------------------------------------------------------------------------
newtype NewGist
  = NewGist
  { _newGistDescription :: String
  , _newGistPublic :: Boolean
  , _newGistFiles :: Array NewGistFile
  }

instance encodeJsonNewGist :: EncodeJson NewGist where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$< ( E.record
              { _newGistDescription: E.value :: _ String
              , _newGistPublic: E.value :: _ Boolean
              , _newGistFiles: E.value :: _ (Array NewGistFile)
              }
          )

instance decodeJsonNewGist :: DecodeJson NewGist where
  decodeJson =
    defer \_ ->
      D.decode
        $ ( NewGist
              <$> D.record "NewGist"
                  { _newGistDescription: D.value :: _ String
                  , _newGistPublic: D.value :: _ Boolean
                  , _newGistFiles: D.value :: _ (Array NewGistFile)
                  }
          )

derive instance genericNewGist :: Generic NewGist _

derive instance newtypeNewGist :: Newtype NewGist _

--------------------------------------------------------------------------------
_NewGist :: Iso' NewGist { _newGistDescription :: String, _newGistPublic :: Boolean, _newGistFiles :: Array NewGistFile }
_NewGist = _Newtype

newGistDescription :: Lens' NewGist String
newGistDescription = _Newtype <<< prop (Proxy :: _ "_newGistDescription")

newGistPublic :: Lens' NewGist Boolean
newGistPublic = _Newtype <<< prop (Proxy :: _ "_newGistPublic")

newGistFiles :: Lens' NewGist (Array NewGistFile)
newGistFiles = _Newtype <<< prop (Proxy :: _ "_newGistFiles")

--------------------------------------------------------------------------------
newtype NewGistFile
  = NewGistFile
  { _newGistFilename :: String
  , _newGistFileContent :: String
  }

instance encodeJsonNewGistFile :: EncodeJson NewGistFile where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$< ( E.record
              { _newGistFilename: E.value :: _ String
              , _newGistFileContent: E.value :: _ String
              }
          )

instance decodeJsonNewGistFile :: DecodeJson NewGistFile where
  decodeJson =
    defer \_ ->
      D.decode
        $ ( NewGistFile
              <$> D.record "NewGistFile"
                  { _newGistFilename: D.value :: _ String
                  , _newGistFileContent: D.value :: _ String
                  }
          )

derive instance genericNewGistFile :: Generic NewGistFile _

derive instance newtypeNewGistFile :: Newtype NewGistFile _

--------------------------------------------------------------------------------
_NewGistFile :: Iso' NewGistFile { _newGistFilename :: String, _newGistFileContent :: String }
_NewGistFile = _Newtype

newGistFilename :: Lens' NewGistFile String
newGistFilename = _Newtype <<< prop (Proxy :: _ "_newGistFilename")

newGistFileContent :: Lens' NewGistFile String
newGistFileContent = _Newtype <<< prop (Proxy :: _ "_newGistFileContent")

--------------------------------------------------------------------------------
newtype Owner
  = Owner
  { _ownerLogin :: String
  , _ownerHtmlUrl :: String
  }

derive instance eqOwner :: Eq Owner

instance showOwner :: Show Owner where
  show a = genericShow a

instance encodeJsonOwner :: EncodeJson Owner where
  encodeJson =
    defer \_ ->
      E.encode $ unwrap
        >$< ( E.record
              { _ownerLogin: E.value :: _ String
              , _ownerHtmlUrl: E.value :: _ String
              }
          )

instance decodeJsonOwner :: DecodeJson Owner where
  decodeJson =
    defer \_ ->
      D.decode
        $ ( Owner
              <$> D.record "Owner"
                  { _ownerLogin: D.value :: _ String
                  , _ownerHtmlUrl: D.value :: _ String
                  }
          )

derive instance genericOwner :: Generic Owner _

derive instance newtypeOwner :: Newtype Owner _

--------------------------------------------------------------------------------
_Owner :: Iso' Owner { _ownerLogin :: String, _ownerHtmlUrl :: String }
_Owner = _Newtype

ownerLogin :: Lens' Owner String
ownerLogin = _Newtype <<< prop (Proxy :: _ "_ownerLogin")

ownerHtmlUrl :: Lens' Owner String
ownerHtmlUrl = _Newtype <<< prop (Proxy :: _ "_ownerHtmlUrl")
