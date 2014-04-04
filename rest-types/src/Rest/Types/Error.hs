{-# LANGUAGE
    TemplateHaskell
  , EmptyDataDecls
  , TypeFamilies
  , GADTs
  , ScopedTypeVariables
  , StandaloneDeriving
  , DeriveDataTypeable
  #-}
module Rest.Types.Error
  ( DataError(..)
  , DomainReason(..)
  , Status(..)
  , Reason_
  , Reason(..)
  ) where

import Control.Monad.Error
import Data.JSON.Schema
import Data.String
import Data.Typeable
import Generics.Regular
import Generics.Regular.XmlPickler (gxpickle)
import Generics.Regular.JSON
import Text.JSON
import Text.XML.HXT.Arrow.Pickle

-- Error utilities.

data DataError
  = ParseError        String
  | PrintError        String
  | MissingField      String
  | UnsupportedFormat String
  deriving Show

data DomainReason a = DomainReason { mkResponseCode :: a -> Int, reason :: a }

instance Show a => Show (DomainReason a) where
  showsPrec a (DomainReason _ e) = showParen (a >= 11) (showString "Domain " . showsPrec 11 e)

instance XmlPickler a => XmlPickler (DomainReason a) where
  xpickle = xpWrap (DomainReason (error "No error function defined for DomainReason parsed from JSON"), reason) xpickle

instance JSON a => JSON (DomainReason a) where
  showJSON (DomainReason _ e) = showJSON e
  readJSON = fmap (DomainReason (error "No error function defined for DomainReason parsed from JSON")) . readJSON

instance JSONSchema a => JSONSchema (DomainReason a) where
  schema = schema . fmap reason

instance Json a => Json (DomainReason a)

data Status a b = Failure a | Success b deriving Typeable

$(deriveAll ''Status "PFStatus")
type instance PF (Status a b) = PFStatus a b

instance (XmlPickler a, XmlPickler b) => XmlPickler (Status a b) where
  xpickle = gxpickle

instance (JSON a, JSON b) => JSON (Status a b) where
  showJSON = gshowJSON
  readJSON = greadJSON

instance (JSONSchema a, JSONSchema b) => JSONSchema (Status a b) where
  schema = gSchema

instance (Json a, Json b) => Json (Status a b)

type Reason_ = Reason ()

data Reason a
  = NotFound
  | PreparationFailed
  | UnsupportedResource
  | UnsupportedAction
  | UnsupportedVersion
  | NotAllowed
  | AuthenticationFailed
  | Busy

  | IdentError   DataError
  | ParamError   DataError
  | InputError   DataError
  | OutputError  DataError

  | CustomReason (DomainReason a)
  | Unknown      String
  deriving (Show, Typeable)

instance Error DataError

instance IsString (Reason e) where
  fromString = Unknown

instance Error (Reason e) where
  strMsg = fromString

$(deriveAll ''DataError "PFDataError")
$(deriveAll ''Reason    "PFReason")

type instance PF DataError  = PFDataError
type instance PF (Reason e) = PFReason e

instance XmlPickler DataError  where xpickle = gxpickle
instance XmlPickler e => XmlPickler (Reason e) where xpickle = gxpickle

instance JSON DataError where showJSON = gshowJSON ; readJSON = greadJSON
instance JSON e => JSON (Reason e) where showJSON = gshowJSON ; readJSON = greadJSON

instance JSONSchema DataError where schema = gSchema
instance JSONSchema e => JSONSchema (Reason e) where schema = gSchema

instance Json DataError
instance Json e => Json (Reason e)
