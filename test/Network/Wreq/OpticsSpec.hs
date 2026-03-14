{-# LANGUAGE OverloadedStrings #-}

module Network.Wreq.OpticsSpec (spec) where

import qualified Data.Attoparsec.ByteString.Char8 as A8
import Data.ByteString (ByteString)
import Data.Time.Calendar (fromGregorian)
import Data.Time.Clock (UTCTime (..), secondsToDiffTime)
import Network.HTTP.Client (Cookie (..), createCookieJar)
import Network.HTTP.Types.Status (ok200)
import Network.Wreq (defaults)
import Network.Wreq.Optics
import Optics.Core
import Test.Hspec

epoch :: UTCTime
epoch = UTCTime (fromGregorian 2000 1 1) (secondsToDiffTime 0)

testCookie :: Cookie
testCookie =
    Cookie
        { cookie_name = "session"
        , cookie_value = "abc123"
        , cookie_expiry_time = epoch
        , cookie_domain = "example.com"
        , cookie_path = "/"
        , cookie_creation_time = epoch
        , cookie_last_access_time = epoch
        , cookie_persistent = False
        , cookie_host_only = True
        , cookie_secure_only = False
        , cookie_http_only = True
        }

spec :: Spec
spec = do
    describe "Options lenses" $ do
        it "views redirects" $
            view redirects defaults `shouldBe` 10

        it "sets params" $ do
            let opts = defaults & set (param "foo") ["bar"]
            view (param "foo") opts `shouldBe` ["bar"]

        it "sets headers" $ do
            let opts = defaults & set (header "X-Custom") ["value"]
            view (header "X-Custom") opts `shouldBe` ["value"]

        it "views auth as Nothing by default" $
            view auth defaults `shouldBe` Nothing

        it "views proxy as Nothing by default" $
            view proxy defaults `shouldBe` Nothing

        it "sets multiple params" $ do
            let opts =
                    defaults
                        & set (param "a") ["1"]
                        & set (param "b") ["2"]
            view (param "a") opts `shouldBe` ["1"]
            view (param "b") opts `shouldBe` ["2"]

        it "sets cookies" $ do
            let jar = createCookieJar [testCookie]
                opts = defaults & set cookies (Just jar)
            case view cookies opts of
                Nothing -> expectationFailure "expected Just CookieJar"
                Just _ -> pure ()

    describe "Cookie lenses" $ do
        it "views cookie name" $
            view cookieName testCookie `shouldBe` "session"

        it "views cookie value" $
            view cookieValue testCookie `shouldBe` "abc123"

        it "views cookie domain" $
            view cookieDomain testCookie `shouldBe` "example.com"

        it "views cookie path" $
            view cookiePath testCookie `shouldBe` "/"

        it "views cookie booleans" $ do
            view cookiePersistent testCookie `shouldBe` False
            view cookieHostOnly testCookie `shouldBe` True
            view cookieSecureOnly testCookie `shouldBe` False
            view cookieHttpOnly testCookie `shouldBe` True

        it "sets cookie value" $
            view cookieValue (set cookieValue "new" testCookie) `shouldBe` "new"

    describe "Status lenses" $ do
        it "views status code" $
            view statusCode ok200 `shouldBe` 200

        it "views status message" $
            view statusMessage ok200 `shouldBe` "OK"

    describe "assoc2 (param/header) lens laws" $ do
        it "get-set: setting what you get is identity" $ do
            let opts = defaults & set (param "x") ["v"]
                val = view (param "x") opts
            view (param "x") (set (param "x") val opts) `shouldBe` val

        it "set-get: getting what you set returns the set value" $ do
            let opts = set (param "x") ["hello"] defaults
            view (param "x") opts `shouldBe` ["hello"]

        it "set-set: setting twice is the same as setting once" $ do
            let opts =
                    defaults
                        & set (param "x") ["first"]
                        & set (param "x") ["second"]
            view (param "x") opts `shouldBe` ["second"]

    describe "atto fold" $ do
        it "parses with atto" $ do
            let input = "123" :: ByteString
                result = toListOf (atto A8.decimal) input :: [Int]
            result `shouldBe` [123]

        it "atto_ fails on partial parse" $ do
            let input = "123abc" :: ByteString
                result = toListOf (atto_ A8.decimal) input :: [Int]
            result `shouldBe` []
