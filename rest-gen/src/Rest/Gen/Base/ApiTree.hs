{-# LANGUAGE GADTs #-}
module Rest.Gen.Base.ApiTree where

import Data.Char
import Data.List
import Data.Maybe
import Data.Function

import Rest.Gen.Base.ActionInfo
import Rest.Gen.Base.ActionInfo.Ident (description)
import Rest.Gen.Base.Link
import Rest.Gen.Utils
import Rest.Resource (Router (..), Some1 (..))
import qualified Rest.Resource as Res

data ApiAction =
  ApiAction
    { itemResource :: ResourceId
    , itemLink     :: Link
    , itemInfo     :: ActionInfo
    } deriving (Show, Eq)

data ApiResource =
  TreeItem
    { resName        :: String
    , resId          :: ResourceId
    , resParents     :: ResourceId
    , resLink        :: Link
    , resIdents      :: [Link]
    , resPrivate     :: Bool
    , resItems       :: [ApiAction]
    , resDescription :: String
    , subResources   :: [ApiResource]
    } deriving (Show, Eq)

apiSubtrees :: Router m s -> ApiResource
apiSubtrees (Embed _ routes) = defaultTree { subResources = map (\(Some1 r) -> apiTree r) routes }

apiTree :: Router m s -> ApiResource
apiTree = apiTree' [] []

apiTree' :: ResourceId -> Link -> Router m s -> ApiResource
apiTree' rid lnk (Embed r routes) =
    let myId        = rid ++ [Res.name r]
        myLnk       = lnk ++ [LResource (Res.name r)]
        accessLinks = [ actionInfoToLink [] ai | ai <- resourceToActionInfo r, isAccessor ai ]
    in TreeItem
        { resName        = Res.name r
        , resId          = myId
        , resParents     = rid
        , resLink        = myLnk
        , resIdents      = accessLinks
        , resPrivate     = Res.private r
        , resItems       = [ ApiAction myId (myLnk ++ actionInfoToLink [LAccess accessLinks] ai) ai | ai <- resourceToActionInfo r ]
        , resDescription = Res.description r
        , subResources   = map (\(Some1 chd) -> apiTree' myId (myLnk ++ [LAccess accessLinks]) chd) routes
        }

-- | Create urls from an action
actionInfoToLink :: Link -> ActionInfo -> Link
actionInfoToLink ac ai
  | postAction ai = ac ++ dirPart ++ identPart
  | otherwise     = dirPart ++ identPart
  where dirPart   = if resDir ai /= ""
                      then [LAction $ resDir ai]
                      else []
        identPart = maybe [] ((:[]) . LParam . description) (ident ai)

defaultTree :: ApiResource
defaultTree = TreeItem "" [] [] [] [] False [] "" []

-- | Traversing ApiResources
foldTree :: (ApiResource -> [a] -> a) -> ApiResource -> a
foldTree f tr = f tr (map (foldTree f) (subResources tr))

foldTreeChildren :: ([a] -> a) -> (ApiResource -> [a] -> a) -> ApiResource -> a
foldTreeChildren f1 f2 = f1 . map (foldTree f2) . subResources

noPrivate :: ApiResource -> ApiResource
noPrivate = foldTree $ \it subs -> it { subResources = filter (not . resPrivate) subs }

sortTree :: ApiResource -> ApiResource
sortTree = foldTree $ \it subs -> it { subResources = sortBy (compare `on` resName) subs }

allTrees :: ApiResource -> [ApiResource]
allTrees = foldTree $ \it subs -> it : concat subs

allSubTrees :: ApiResource -> [ApiResource]
allSubTrees = foldTreeChildren concat $ \it subs -> it : concat subs

apiResources :: ApiResource -> [ResourceId]
apiResources = foldTree $ \it subs -> map (resName it:) ([] : concat subs)

allResources :: ApiResource -> [ApiResource]
allResources = foldTree $ \it -> (it:) . concat

allSubResources :: ApiResource -> [ApiResource]
allSubResources = foldTreeChildren concat $ \it -> (it:) . concat

allResourceIds :: ApiResource -> [ResourceId]
allResourceIds = map resId . allResources

allSubResourceIds :: ApiResource -> [ResourceId]
allSubResourceIds = map resId . allSubResources

subResourceNames :: ApiResource -> [String]
subResourceNames = map resName . subResources

subResourceIds :: ApiResource -> [ResourceId]
subResourceIds = map resId . subResources

hasAccessor :: ApiResource -> Bool
hasAccessor = not . null . resIdents

-- | Extra functions for generation
mkFuncParts :: ApiAction -> [String]
mkFuncParts (ApiAction _ _ ai) = concatMap cleanName parts
  where
      parts = case actionType ai of
                Retrieve -> let nm = get ++ by ++ target
                            in if null nm then ["access"] else nm
                Create   -> ["create"] ++ by ++ target
                -- Should be delete, but delete is a JS keyword and causes problems in collect.
                Delete   -> ["remove"] ++ by ++ target
                List     -> ["list"]   ++ by ++ target
                Update   -> ["save"]   ++ by ++ target
                Modify   -> if resDir ai == "" then ["do"] else [resDir ai]

      target = if resDir ai == "" then [] else [resDir ai]
      by     = if target /= [] && isJust (ident ai) then ["by"] else []
      get    = if isAccessor ai then [] else ["get"]

cleanName :: String -> [String]
cleanName ""         = [""]
cleanName ('-':v:rs) = [] : mapHead (mapHead toUpper) (cleanName (v: rs))
cleanName (x : xs) | isAlphaNum x = mapHead (x:) $ cleanName xs
                   | otherwise    = cleanName xs
