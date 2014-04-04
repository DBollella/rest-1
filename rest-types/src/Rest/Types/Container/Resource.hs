{-# LANGUAGE
    DeriveDataTypeable
  , DeriveGeneric
  , TemplateHaskell
  , TypeFamilies
  , EmptyDataDecls
  #-}
module Rest.Types.Container.Resource
  ( Resource (..)
  , Resources (..)

  , KeyValues
  , Value (..)
  ) where

import Data.Aeson hiding (Value)
import Data.JSON.Schema (JSONSchema (..), gSchema)
import Data.Typeable
import GHC.Generics
import Generics.Generic.Aeson
import Generics.Regular (PF, deriveAll)
import Generics.Regular.XmlPickler (gxpickle)
import Text.XML.HXT.Arrow.Pickle
import qualified Data.JSON.Schema as Json

import Rest.Types.Container

type KeyValues = StringMap String Value

newtype Value = Value { unValue :: String } deriving (Show, Typeable)

instance XmlPickler Value where
  xpickle = xpElem "value" $ xpWrap (Value, unValue) xpText0

instance ToJSON   Value where toJSON    = toJSON . unValue
instance FromJSON Value where parseJSON = fmap Value . parseJSON

instance JSONSchema Value where
  schema _ = Json.Value 0 (-1)

data Resource = Resource
  { uri        :: String
  , headers    :: KeyValues
  , parameters :: KeyValues
  , input      :: String
  } deriving (Generic, Show, Typeable)

deriveAll ''Resource "PFResource"
type instance PF Resource = PFResource

instance XmlPickler Resource where
  xpickle = gxpickle

instance ToJSON     Resource where toJSON    = gtoJson
instance FromJSON   Resource where parseJSON = gparseJson
instance JSONSchema Resource where schema    = gSchema

-------------------------------------------------------------------------------

newtype Resources = Resources [Resource] deriving (Generic, Typeable)

deriveAll ''Resources "PFResources"
type instance PF Resources = PFResources

instance XmlPickler Resources where
  xpickle = gxpickle

instance ToJSON     Resources where toJSON    = gtoJson
instance FromJSON   Resources where parseJSON = gparseJson
instance JSONSchema Resources where schema    = gSchema
