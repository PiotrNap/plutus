{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE TypeApplications      #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE UndecidableInstances  #-}
{-# OPTIONS_GHC -Wno-orphans #-}
module Main (main) where

import PlutusPrelude

import NamesSpec
import ParserSpec
import TransformSpec
import TypeSpec

import PlutusIR
import PlutusIR.Parser
import PlutusIR.Test

import PlutusCore qualified as PLC

import Test.Tasty
import Test.Tasty.Extras

import Flat (flat, unflat)

main :: IO ()
main = defaultMain $ runTestNestedIn ["plutus-ir/test"] tests

tests :: TestNested
tests = testGroup "plutus-ir" <$> sequence
    [ prettyprinting
    , parsing
    , lets
    , datatypes
    , recursion
    , serialization
    , errors
    , pure names
    , transform
    , types
    , typeErrors
    ]

prettyprinting :: TestNested
prettyprinting = testNested "prettyprinting"
    $ map (goldenPir id $ term @PLC.DefaultUni @PLC.DefaultFun)
    [ "basic"
    , "maybe"
    ]

lets :: TestNested
lets = testNested "lets"
    [ goldenPlcFromPir term "letInLet"
    , goldenPlcFromPir term "letDep"
    ]

datatypes :: TestNested
datatypes = testNested "datatypes"
    [ goldenPlcFromPir term "maybe"
    , goldenPlcFromPir term "listMatch"
    , goldenPlcFromPirCatch term "idleAll"
    , goldenPlcFromPirCatch term "some"
    , goldenEvalPir term "listMatchEval"
    ]

recursion :: TestNested
recursion = testNested "recursion"
    [ goldenPlcFromPir term "even3"
    , goldenEvalPir term "even3Eval"
    , goldenPlcFromPir term "stupidZero"
    , goldenPlcFromPir term "mutuallyRecursiveValues"
    ]

serialization :: TestNested
serialization = testNested "serialization"
    $ map (goldenPir roundTripPirTerm term)
    [ "serializeBasic"
    , "serializeMaybePirTerm"
    , "serializeEvenOdd"
    , "serializeListMatch"
    ]

roundTripPirTerm :: Term TyName Name PLC.DefaultUni PLC.DefaultFun a -> Term TyName Name PLC.DefaultUni PLC.DefaultFun ()
roundTripPirTerm = decodeOrError . unflat . flat . void
  where
    decodeOrError (Right tm) = tm
    decodeOrError (Left err) = error (show err)

errors :: TestNested
errors = testNested "errors"
    [ goldenPlcFromPirCatch term "mutuallyRecursiveTypes"
    , goldenPlcFromPirCatch term "recursiveTypeBind"
    ]
