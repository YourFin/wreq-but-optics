module ExampleSpec (spec) where

import Test.Hspec
import Example

spec :: Spec
spec = do
  describe "greeting" $ do
    it "returns the expected string" $ do
      greeting `shouldBe` "Hello, Haskell!"
    it "doesn't return a bad string" $ do
      greeting `shouldNotBe` "Hello, python!"
