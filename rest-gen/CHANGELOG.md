# Changelog

## 0.13

Breaking changes:
* Un-exposes internal modules so we don't have to major bump on every change.
* `gen` Now accepts AST-like types instead of just strings to make it more obvious how to use it, see types in `Rest.Gen.Types`

Bugfixes:
* Make sure Identifiers are always imported when needed. This is a further improvement on the bugfix in rest-gen-0.11.
* rest-gen-0.12	did not always take arguments in generated methods into account, so the renamed qualification has been reverted for now.

## 0.12

* Haskell: Module rewrites such as `Data.Text.Internal` -> `Data.Text` now produces qualified imports `import qualified Data.Text as Data.Text` instead of `import qualified Data.Text as Data.Text.Lazy`. This prevents building against different versions of the same package that may have moved the internal module (as is the case with `text`) from generating different clients.

## 0.11

* Bugfix: Haskell: Resources without a getter now generate identifier arguments for other end points
* Shuffles some internal (but exposed) functions around

#### 0.10.0.4

* Drops `aeson-utils` dependency in favor of `scientific >= 0.3.2`

#### 0.10.0.3

* Allow `mtl == 2.2.*`

#### 0.10.0.1

* Bump `Cabal` upper bound to `< 1.22`

## 0.10

* Generate documentation, Javascript and Haskell code for multi-delete
  handlers. The name of the generated functions is `removeMany` or
  `removeManyBy<id>`.
* Escape reserved names in Haskell code generation.
