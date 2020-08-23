{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Orphans where

import Arkham.Types.GameJson
import ClassyPrelude
import Control.Error.Util (hush)
import Data.Aeson
import Data.Aeson.Types
import qualified Data.ByteString.Char8 as BS8
import qualified Data.Text as T
import Data.UUID (UUID)
import qualified Data.UUID as UUID
import Database.Persist.Postgresql.JSON ()
import Database.Persist.Sql
import Web.HttpApiData
import Web.PathPieces
import Yesod.Core.Content

fmapLeft :: (a -> b) -> Either a c -> Either b c
fmapLeft f (Left a) = Left (f a)
fmapLeft _ (Right a) = Right a -- Rewrap to fix types.

instance PersistFieldSql GameJson where
  sqlType _ = SqlString

instance PersistField GameJson where
  toPersistValue = toPersistValue . toJSON
  fromPersistValue val =
    fromPersistValue val >>= fmapLeft pack . parseEither parseJSON

instance PathPiece UUID where
  toPathPiece = toUrlPiece
  fromPathPiece = hush . parseUrlPiece

instance PersistField UUID where
  toPersistValue u = PersistDbSpecific . BS8.pack . UUID.toString $ u
  fromPersistValue (PersistDbSpecific t) =
    case UUID.fromString $ BS8.unpack t of
      Just x -> Right x
      Nothing -> Left "Invalid UUID"
  fromPersistValue _ = Left "Not PersistDBSpecific"

instance PersistFieldSql UUID where
  sqlType _ = SqlOther "uuid"

-- Entity (and Key)
deriving stock instance Typeable Key
deriving stock instance Typeable Entity

instance {-# OVERLAPPABLE #-} (ToJSON a, PersistEntity a) => ToJSON (Entity a) where
  toJSON = entityIdToJSON

instance {-# OVERLAPPABLE #-} (FromJSON a, PersistEntity a) => FromJSON (Entity a) where
  parseJSON = entityIdFromJSON

instance {-# OVERLAPPABLE #-} ToJSON a => ToTypedContent a where
  toTypedContent = TypedContent typeJson . toContent

instance {-# OVERLAPPABLE #-} ToJSON a => ToContent a where
  toContent = toContent . encode

instance (ToBackendKey SqlBackend a) => ToJSONKey (Key a) where
  toJSONKey = toJSONKeyText keyAsText
    where keyAsText = T.pack . show . fromSqlKey

instance (ToBackendKey SqlBackend a) => FromJSONKey (Key a) where
  fromJSONKey = toSqlKey <$> fromJSONKey

instance (ToBackendKey SqlBackend a) => Hashable (Key a) where
  hash = hash . fromSqlKey
  hashWithSalt n = hashWithSalt n . fromSqlKey
