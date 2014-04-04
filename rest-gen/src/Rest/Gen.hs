module Rest.Gen where

import Data.Char
import Data.Label
import Data.Foldable
import Data.Maybe
import System.Cmd
import System.Directory
import System.Exit

import Rest.Api (withVersion, Api, Some1 (..))

import Rest.Gen.Config
import Rest.Gen.Docs.Generate
import Rest.Gen.JavaScript.Generate
import Rest.Gen.Haskell.Generate hiding (apiVersion)
import Rest.Gen.Ruby.Generate
import Rest.Gen.Utils

generate :: String -> Config -> Api m -> [(String, String)] -> IO ()
generate name config api moduleRewrites =
  withVersion (get apiVersion config) api (putStrLn "Could not find api version" >> exitFailure) $ \ver (Some1 r) ->
     case get action config of
       Just (MakeDocs root)        ->
         do loc <- getTargetDir config "./docs"
            setupTargetDir config loc
            let context = DocsContext root ver (fromMaybe "./templates" (getSourceLocation config))
            writeDocs context r loc
            exitSuccess
       Just MakeJS                 -> mkJsApi (moduleName ++ "Api") (get apiPrivate config) ver r >>= toTarget config
       Just MakeRb                 -> mkRbApi (moduleName ++ "Api") (get apiPrivate config) ver r >>= toTarget config
       Just (MakeHS cabalTemplate) ->
         do loc <- getTargetDir config "./client"
            setupTargetDir config loc
            let context = HaskellContext ver loc cabalTemplate (packageName ++ "-client") (get apiPrivate config) moduleRewrites [moduleName, "Client"]
            mkHsApi context r
            exitSuccess
       Nothing                     -> return ()
  where
    packageName = map toLower name
    moduleName  = upFirst packageName

getTargetDir :: Config -> String -> IO String
getTargetDir config str =
  case get target config of
    Stream     -> putStrLn ("Cannot generate documentation to stdOut, generating to " ++ str) >> return str
    Default    -> putStrLn ("Generating to " ++ str) >> return str
    Location d -> putStrLn ("Generating to " ++ d) >> return d

setupTargetDir :: Config -> String -> IO ()
setupTargetDir config t =
  do createDirectoryIfMissing True t
     forM_ (getSourceLocation config) $ \s -> system $ "cp -rf " ++ s ++ " " ++ t

toTarget :: Config -> String -> IO ()
toTarget config code =
  do let outf =
           case get target config of
             Stream     -> putStrLn
             Default    -> putStrLn
             Location l -> writeFile l
     outf code
     exitSuccess

getSourceLocation :: Config -> Maybe String
getSourceLocation config =
  case get source config of
    Location s -> Just s
    _          -> Nothing
