{-# LANGUAGE NegativeLiterals #-}

module TinyAPL.PrimitivesSpec where

import TinyAPL.ArrayFunctionOperator
import TinyAPL.Error
import qualified TinyAPL.Glyphs as G
import qualified TinyAPL.Primitives as P

import Test.Hspec
import Data.Complex

spec :: Spec
spec = do
  let scope = Scope [("l", vector $ Character <$> ['a'..'z'])] [] [] [] Nothing

  let m :: Function -> Array -> IO (Result Array)
      m fn y = runResult $ fst <$> runSt (callMonad fn y) scope

      d :: Function -> Array -> Array -> IO (Result Array)
      d fn x y = runResult $ fst <$> runSt (callDyad fn x y) scope

      aam :: Adverb -> Array -> Array -> IO (Result Array)
      aam adv u x = runResult $ fst <$> runSt (callOnArray adv u >>= (`callMonad` x)) scope

      aad :: Adverb -> Array -> Array -> Array -> IO (Result Array)
      aad adv u x y = runResult $ fst <$> runSt (callOnArray adv u >>= (\d -> callDyad d x y)) scope

      afm :: Adverb -> Function -> Array -> IO (Result Array)
      afm adv f x = runResult $ fst <$> runSt (callOnFunction adv f >>= (`callMonad` x)) scope

      afd :: Adverb -> Function -> Array -> Array -> IO (Result Array)
      afd adv f x y = runResult $ fst <$> runSt (callOnFunction adv f >>= (\d -> callDyad d x y)) scope

      caam :: Conjunction -> Array -> Array -> Array -> IO (Result Array)
      caam conj u v x = runResult $ fst <$> runSt (callOnArrayAndArray conj u v >>= (`callMonad` x)) scope

      caad :: Conjunction -> Array -> Array -> Array -> Array -> IO (Result Array)
      caad conj u v x y = runResult $ fst <$> runSt (callOnArrayAndArray conj u v >>= (\d -> callDyad d x y)) scope

      cafm :: Conjunction -> Array -> Function -> Array -> IO (Result Array)
      cafm conj u g x = runResult $ fst <$> runSt (callOnArrayAndFunction conj u g >>= (`callMonad` x)) scope

      cafd :: Conjunction -> Array -> Function -> Array -> Array -> IO (Result Array)
      cafd conj u g x y = runResult $ fst <$> runSt (callOnArrayAndFunction conj u g >>= (\d -> callDyad d x y)) scope

      cfam :: Conjunction -> Function -> Array -> Array -> IO (Result Array)
      cfam conj f v x = runResult $ fst <$> runSt (callOnFunctionAndArray conj f v >>= (`callMonad` x)) scope

      cfad :: Conjunction -> Function -> Array -> Array -> Array -> IO (Result Array)
      cfad conj f v x y = runResult $ fst <$> runSt (callOnFunctionAndArray conj f v >>= (\d -> callDyad d x y)) scope

      cffm :: Conjunction -> Function -> Function -> Array -> IO (Result Array)
      cffm conj f g x = runResult $ fst <$> runSt (callOnFunctionAndFunction conj f g >>= (`callMonad` x)) scope

      cffd :: Conjunction -> Function -> Function -> Array -> Array -> IO (Result Array)
      cffd conj f g x y = runResult $ fst <$> runSt (callOnFunctionAndFunction conj f g >>= (\d -> callDyad d x y)) scope

      e2m :: Either e a -> Maybe a
      e2m (Right x) = Just x
      e2m (Left _) = Nothing

  describe "arrays" $ do
    describe [G.zilde] $ do
      it "is an empty vector" $ do
        P.zilde `shouldBe` vector []
  
  describe "functions" $ do
    describe [G.plus] $ do
      describe "conjugate" $ do
        it "doesn't change real numbers" $ do
          m P.plus (vector [Number 3, Number -2]) `shouldReturn` pure (vector [Number 3, Number -2])
        it "conjugates complex numbers" $ do
          m P.plus (vector [Number (3 :+ 2), Number (1 :+ -1)]) `shouldReturn` pure (vector [Number (3 :+ -2), Number (1 :+ 1)])
      describe "add" $ do
        it "adds complex numbers" $ do
          d P.plus (scalar $ Number (2 :+ 1)) (vector [Number 1, Number -3, Number (0 :+ 1)]) `shouldReturn` pure (vector [Number (3 :+ 1), Number (-1 :+ 1), Number (2 :+ 2)])
    
    describe [G.minus] $ do
      describe "negate" $ do
        it "negates complex numbers" $ do
          m P.minus (vector [Number 3, Number -1, Number (2 :+ 3)]) `shouldReturn` pure (vector [Number -3, Number 1, Number (-2 :+ -3)])
      describe "subtract" $ do
        it "subtracts complex numbers" $ do
          d P.minus (scalar $ Number 3) (vector [Number 1, Number -3, Number (2 :+ 1)]) `shouldReturn` pure (vector [Number 2, Number 6, Number (1 :+ -1)])

    describe [G.times] $ do
      describe "signum" $ do
        it "returns the sign of real numbers" $ do
          m P.times (vector [Number 3, Number 0, Number -5]) `shouldReturn` pure (vector [Number 1, Number 0, Number -1])
        it "returns the direction of complex numbers" $ do
          m P.times (vector [Number (0 :+ 2), Number (1 :+ 1)]) `shouldReturn` pure (vector [Number (0 :+ 1), Number (sqrt 0.5 :+ sqrt 0.5)])
      describe "multiply" $ do
        it "multiplies complex numbers" $ do
          d P.times (scalar $ Number (2 :+ 1)) (vector [Number 2, Number -1, Number (3 :+ -1)]) `shouldReturn` pure (vector [Number (4 :+ 2), Number (-2 :+ -1), Number (7 :+ 1)])
    
    describe [G.divide] $ do
      describe "reciprocal" $ do
        it "returns the reciprocal of complex numbers" $ do
          m P.divide (vector [Number 3, Number (2 :+ 1), Number -3]) `shouldReturn` pure (vector [Number (1 / 3), Number (1 / (2 :+ 1)), Number (-1 / 3)])
        it "fails with zero argument" $ do
          e2m <$> m P.divide (scalar $ Number 0) `shouldReturn` Nothing
      describe "divide" $ do
        it "divides complex numbers" $ do
          d P.divide (scalar $ Number (1 :+ 2)) (vector [Number 2, Number -3, Number (2 :+ -3)]) `shouldReturn` pure (vector [Number (0.5 :+ 1), Number ((-1 / 3) :+ (-2 / 3)), Number ((-4 / 13) :+ (7 / 13))])
        it "returns 1 for 0/0" $ do
          d P.divide (scalar $ Number 0) (scalar $ Number 0) `shouldReturn` pure (scalar $ Number 1)
        it "fails with zero right argument" $ do
          e2m <$> d P.divide (vector [Number 2, Number 1]) (scalar $ Number 0) `shouldReturn` Nothing
    
    describe [G.power] $ do
      describe "exp" $ do
        it "applies the exponential function to complex numbers" $ do
          m P.power (vector [Number 1, Number 2, Number -1, Number (0 :+ pi)]) `shouldReturn` pure (vector [Number $ exp 1, Number $ exp 2, Number $ exp -1, Number $ -1 :+ 0])
      describe "power" $ do
        it "exponentiates complex numbers" $ do
          d P.power (scalar $ Number 2) (vector [Number 1, Number -1, Number (2 :+ 1)]) `shouldReturn` pure (vector [Number 2, Number $ 1 / 2, Number $ 2 ** (2 :+ 1)])

    describe [G.logarithm] $ do
      describe "ln" $ do
        it "returns the natural logarithm of complex numbers" $ do
          m P.logarithm (vector [Number 1, Number (exp 1), Number -1]) `shouldReturn` pure (vector [Number $ log 1, Number 1, Number $ 0 :+ pi])
        it "fails with zero argument" $ do
          e2m <$> m P.logarithm (scalar $ Number 0) `shouldReturn` Nothing
      describe "log" $ do
        it "returns the logarithm of complex numbers" $ do
          d P.logarithm (scalar $ Number $ 2 :+ 1) (vector [Number 1, Number (0 :+ 3)]) `shouldReturn` pure (vector [Number 0, Number $ logBase (2 :+ 1) (0 :+ 3)])
        it "returns 1 for 1, 1" $ do
          d P.logarithm (scalar $ Number 1) (scalar $ Number 1) `shouldReturn` pure (scalar $ Number 1)
        it "fails for left argument 1" $ do
          e2m <$> d P.logarithm (scalar $ Number 1) (vector [Number 3, Number 0.5]) `shouldReturn` Nothing

    describe [G.circle] $ do
      describe "pi times" $ do
        it "multiplies complex numbers by pi" $ do
          m P.circle (vector [Number 0, Number 1, Number (2 :+ -1)]) `shouldReturn` pure (vector [Number 0, Number pi, Number (2 * pi :+ -1 * pi)])
      describe "0: √1-y²" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 0) (vector [Number $ 1 / 2, Number $ sqrt 3 / 2, Number $ 3 / 5, Number (2 :+ 1)]) `shouldReturn` pure (vector [Number $ sqrt 3 / 2, Number $ 1 / 2, Number $ 4 / 5, Number $ sqrt (1 - ((2 :+ 1) ** 2))])
      describe "1: sin y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 1) (vector [Number 0, Number $ pi / 2, Number (3 :+ 2)]) `shouldReturn` pure (vector [Number 0, Number 1, Number $ sin (3 :+ 2)])
      describe "¯1: arcsin y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -1) (vector [Number 0, Number 1, Number (1 :+ -2)]) `shouldReturn` pure (vector [Number 0, Number $ pi / 2, Number $ asin (1 :+ -2)])
      describe "2: cos y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 2) (vector [Number 0, Number $ pi / 2, Number (1 :+ 3)]) `shouldReturn` pure (vector [Number 1, Number $ cos $ pi / 2 {- not zero due to floating point errors -}, Number $ cos (1 :+ 3)])
      describe "¯2: arccos y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -2) (vector [Number 1, Number 0, Number (2 :+ 5)]) `shouldReturn` pure (vector [Number 0, Number $ pi / 2, Number $ acos (2 :+ 5)])
      describe "3: tan y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 3) (vector [Number 0, Number $ pi / 4, Number (-1 :+ 3)]) `shouldReturn` pure (vector [Number 0, Number 1, Number $ tan (-1 :+ 3)])
      describe "¯3: arctan y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -3) (vector [Number 0, Number 1, Number (3 :+ 4)]) `shouldReturn` pure (vector [Number 0, Number $ pi / 4, Number $ atan (3 :+ 4)])
      describe "4: √1+y²" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 4) (vector [Number 0, Number (0 :+ (3 / 5))]) `shouldReturn` pure (vector [Number 1, Number (4 / 5)])
      describe "¯4: √y²-1" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -4) (vector [Number 0, Number (4 / 5), Number (2 :+ 1)]) `shouldReturn` pure (vector [Number (0 :+ 1), Number (0 :+ (3 / 5)), Number $ sqrt $ (2 :+ 1) ** 2 - 1])
      describe "5: sinh y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 5) (vector [Number 1, Number (2 :+ 1)]) `shouldReturn` pure (vector [Number $ sinh 1, Number $ sinh (2 :+ 1)])
      describe "¯5: arsinh y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -5) (vector [Number 1, Number (2 :+ 1)]) `shouldReturn` pure (vector [Number $ asinh 1, Number $ asinh (2 :+ 1)])
      describe "6: cosh y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 6) (vector [Number 3, Number (3 :+ -2)]) `shouldReturn` pure (vector [Number $ cosh 3, Number $ cosh (3 :+ -2)])
      describe "¯6: arcosh y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -6) (vector [Number 3, Number (3 :+ -2)]) `shouldReturn` pure (vector [Number $ acosh 3, Number $ acosh (3 :+ -2)])
      describe "7: tanh y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 7) (vector [Number -2, Number (1 :+ 1)]) `shouldReturn` pure (vector [Number $ tanh -2, Number $ tanh (1 :+ 1)])
      describe "¯7: artanh y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -7) (vector [Number -2, Number (1 :+ 1)]) `shouldReturn` pure (vector [Number $ atanh -2, Number $ atanh (1 :+ 1)])
      describe "8: √-1-y²" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 8) (vector [Number 3, Number (0 :+ 1)]) `shouldReturn` pure (vector [Number (0 :+ sqrt 10), Number 0])
      describe "¯8: -√-1-y²" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -8) (vector [Number 3, Number (0 :+ 1)]) `shouldReturn` pure (vector [Number (0 :+ negate (sqrt 10)), Number 0])
      describe "9: Re y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 9) (vector [Number 5, Number (3 :+ 2), Number (0 :+ -1)]) `shouldReturn` pure (vector [Number 5, Number 3, Number 0])
      describe "¯9: y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -9) (vector [Number 3, Number (1 :+ -2)]) `shouldReturn` pure (vector [Number 3, Number (1 :+ -2)])
      describe "10: |y|" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 10) (vector [Number 3, Number -5, Number (0 :+ 2), Number (1 :+ -1)]) `shouldReturn` pure (vector [Number 3, Number 5, Number 2, Number $ sqrt 2])
      describe "¯10: conj(y)" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -10) (vector [Number 5, Number (3 :+ 2)]) `shouldReturn` pure (vector [Number 5, Number (3 :+ -2)])
      describe "11: Im y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 11) (vector [Number 5, Number (3 :+ 2), Number (0 :+ -1)]) `shouldReturn` pure (vector [Number 0, Number 2, Number -1])
      describe "¯11: iy" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -11) (vector [Number 3, Number (1 :+ 2)]) `shouldReturn` pure (vector [Number (0 :+ 3), Number (-2 :+ 1)])
      describe "12: Arg y" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number 12) (vector [Number 5, Number -3, Number (0 :+ 1), Number (2 :+ 2)]) `shouldReturn` pure (vector [Number 0, Number pi, Number $ pi / 2, Number $ pi / 4])
      describe "¯12: e*iy" $ do
        it "applies the function to complex numbers" $ do
          d P.circle (scalar $ Number -12) (vector [Number pi, Number $ pi / 2, Number (0 :+ 1)]) `shouldReturn` pure (vector [Number -1, Number (0 :+ 1), Number $ exp -1])
      describe "other arguments" $ do
        it "fails" $ do
          e2m <$> d P.circle (scalar $ Number -100) (vector [Number 3, Number -1]) `shouldReturn` Nothing
    
    describe [G.root] $ do
      describe "square root" $ do
        it "returns the square root of complex arguments" $ do
          m P.root (vector [Number 4, Number -1, Number (1 :+ 1)]) `shouldReturn` pure (vector [Number 2, Number (0 :+ 1), Number $ sqrt (1 :+ 1)])
      describe "nth root" $ do
        it "returns the nth root of complex arguments" $ do
          d P.root (vector [Number 3, Number 4, Number (0 :+ -1)]) (vector [Number 8, Number 16, Number (2 :+ 1)]) `shouldReturn` pure (vector [Number 2, Number 2, Number $ (2 :+ 1) ** recip (0 :+ -1)])
    
    describe [G.floor] $ do
      describe "floor" $ do
        it "floors real numbers" $ do
          m P.floor (vector [Number 1, Number 1.25, Number -1.75]) `shouldReturn` pure (vector [Number 1, Number 1, Number -2])
        it "floors complex numbers" $ do
          m P.floor (vector [Number (0.25 :+ 0.25), Number (0.75 :+ 0.25), Number (0.25 :+ 0.75)]) `shouldReturn` pure (vector [Number 0, Number 1, Number (0 :+ 1)])
      describe "min" $ do
        it "returns the minimum of real numbers" $ do
          d P.floor (vector [Number 3, Number -1]) (vector [Number 2, Number 5]) `shouldReturn` pure (vector [Number 2, Number -1])
        it "returns the lexicographical minimum of complex numbers" $ do
          d P.floor (vector [Number (2 :+ 1), Number (-1 :+ 3)]) (vector [Number (2 :+ 3), Number (2 :+ 5)]) `shouldReturn` pure (vector [Number (2 :+ 1), Number (-1 :+ 3)])

    describe [G.ceil] $ do
      describe "ceiling" $ do
        it "ceils real numbers" $ do
          m P.ceil (vector [Number 1, Number 1.25, Number -1.75]) `shouldReturn` pure (vector [Number 1, Number 2, Number -1])
        it "ceils complex numbers" $ do
          m P.ceil (vector [Number (0.25 :+ 0.25), Number (0.75 :+ 0.25), Number (0.75 :+ 0.75)]) `shouldReturn` pure (vector [Number (0 :+ 1), Number 1, Number (1 :+ 1)])
      describe "max" $ do
        it "returns the maximum of real numbers" $ do
          d P.ceil (vector [Number 3, Number -1]) (vector [Number 2, Number 5]) `shouldReturn` pure (vector [Number 3, Number 5])
        it "returns the lexicographical maximum of complex numbers" $ do
          d P.ceil (vector [Number (2 :+ 1), Number (-1 :+ 3)]) (vector [Number (2 :+ 3), Number (2 :+ 5)]) `shouldReturn` pure (vector [Number (2 :+ 3), Number (2 :+ 5)])

    describe [G.round] $ do
      describe "round" $ do
        it "rounds real numbers" $ do
          m P.round (vector [Number 1.2, Number 1.7]) `shouldReturn` pure (vector [Number 1, Number 2])
        it "rounds .5 above" $ do
          m P.round (vector [Number 1.5, Number -1.5]) `shouldReturn` pure (vector [Number 2, Number -1])
        it "rounds components of complex numbers" $ do
          m P.round (vector [Number (3 :+ 2.9), Number (1.2 :+ 3.4)]) `shouldReturn` pure (vector [Number (3 :+ 3), Number (1 :+ 3)])

    describe [G.less, G.equal, G.lessEqual, G.greater, G.notEqual, G.greaterEqual] $ do
      describe "comparisons" $ do
        it "compares scalars" $ do
          d P.less (vector [Number 1, Number 1, Number 1]) (vector [Number 0, Number 1, Number 2]) `shouldReturn` pure (vector [Number 0, Number 0, Number 1])
          d P.equal (vector [Number 1, Number 1, Number 1]) (vector [Number 0, Number 1, Number 2]) `shouldReturn` pure (vector [Number 0, Number 1, Number 0])
          d P.lessEqual (vector [Number 1, Number 1, Number 1]) (vector [Number 0, Number 1, Number 2]) `shouldReturn` pure (vector [Number 0, Number 1, Number 1])
          d P.greater (vector [Number 1, Number 1, Number 1]) (vector [Number 0, Number 1, Number 2]) `shouldReturn` pure (vector [Number 1, Number 0, Number 0])
          d P.notEqual (vector [Number 1, Number 1, Number 1]) (vector [Number 0, Number 1, Number 2]) `shouldReturn` pure (vector [Number 1, Number 0, Number 1])
          d P.greaterEqual (vector [Number 1, Number 1, Number 1]) (vector [Number 0, Number 1, Number 2]) `shouldReturn` pure (vector [Number 1, Number 1, Number 0])
    
    describe [G.notEqual] $ do
      describe "nub sieve" $ do
        it "marks positions of the first occurrence of each element" $ do
          m P.notEqual (vector [Number 1, Number 2, Number 1, Number 3, Number 3]) `shouldReturn` pure (vector [Number 1, Number 1, Number 0, Number 1, Number 0])

    describe [G.and] $ do
      describe "and" $ do
        it "combines boolean values with the and logical operation" $ do
          d P.and (vector [Number 0, Number 0, Number 1, Number 1]) (vector [Number 0, Number 1, Number 0, Number 1]) `shouldReturn` pure (vector [Number 0, Number 0, Number 0, Number 1])
      describe "lcm" $ do
        it "applies the LCM function to numbers" $ do
          d P.and (vector [Number 2, Number 0.5]) (vector [Number 3, Number 4.5]) `shouldReturn` pure (vector [Number 6, Number 4.5])
    
    describe [G.or] $ do
      describe "or" $ do
        it "combines boolean values with the or logical operation" $ do
          d P.or (vector [Number 0, Number 0, Number 1, Number 1]) (vector [Number 0, Number 1, Number 0, Number 1]) `shouldReturn` pure (vector [Number 0, Number 1, Number 1, Number 1])
      describe "gcd" $ do
        it "applies the GCD function to numbers" $ do
          d P.or (vector [Number 2, Number 0.5]) (vector [Number 3, Number 4.5]) `shouldReturn` pure (vector [Number 1, Number 0.5])

    describe [G.nand] $ do
      describe "nand" $ do
        it "combines boolean values with the nand logical operation" $ do
          d P.nand (vector [Number 0, Number 0, Number 1, Number 1]) (vector [Number 0, Number 1, Number 0, Number 1]) `shouldReturn` pure (vector [Number 1, Number 1, Number 1, Number 0])

    describe [G.nor] $ do
      describe "nor" $ do
        it "combines boolean values with the nor logical operation" $ do
          d P.nor (vector [Number 0, Number 0, Number 1, Number 1]) (vector [Number 0, Number 1, Number 0, Number 1]) `shouldReturn` pure (vector [Number 1, Number 0, Number 0, Number 0])

    describe [G.cartesian] $ do
      describe "pure imaginary" $ do
        it "multiplies arguments by i" $ do
          m P.cartesian (vector [Number 2, Number (3 :+ 1)]) `shouldReturn` pure (vector [Number (0 :+ 2), Number (-1 :+ 3)])
      describe "cartesian" $ do
        it "combines real and imaginary parts of a number" $ do
          d P.cartesian (vector [Number 1, Number (0 :+ 3)]) (vector [Number 2, Number (1 :+ 4)]) `shouldReturn` pure (vector [Number (1 :+ 2), Number (-4 :+ 4)])
    
    describe [G.polar] $ do
      describe "unit imaginary" $ do
        it "returns the point of the unit circle with phase specified by the argument" $ do
          m P.polar (vector [Number 0, Number pi, Number $ pi / 2, Number $ pi / 4]) `shouldReturn` pure (vector [Number 1, Number -1, Number (0 :+ 1), Number (sqrt 0.5 :+ sqrt 0.5)])
      describe "polar" $ do
        it "returns the complex number specified by the phase and radius" $ do
          d P.polar (vector [Number 3, Number 1, Number -1, Number (3 :+ 2)]) (vector [Number 0, Number $ pi / 2, Number pi, Number $ pi / 2]) `shouldReturn` pure (vector [Number 3, Number (0 :+ 1), Number 1, Number (-2 :+ 3)])

    describe [G.match, G.notMatch] $ do
      describe "comparisons" $ do
        it "compares arrays" $ do
          d P.match (vector [Number 1, Number 2]) (vector [Number 1, Number 2]) `shouldReturn` pure (scalar $ Number 1)
          d P.match (vector [Number 1, Number 2]) (vector [Number 1, Number 3]) `shouldReturn` pure (scalar $ Number 0)
          d P.notMatch (vector [Number 1, Number 2]) (vector [Number 1, Number 2]) `shouldReturn` pure (scalar $ Number 0)
          d P.notMatch (vector [Number 1, Number 2]) (vector [Number 1, Number 3]) `shouldReturn` pure (scalar $ Number 1)

    describe [G.notMatch] $ do
      describe "tally" $ do
        it "returns the length of a vector" $ do
          m P.notMatch (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (scalar $ Number 3)
        it "returns the count of major cells for a higher-rank vector" $ do
          m P.notMatch (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (scalar $ Number 2)
        it "returns 1 for a scalar" $ do
          m P.notMatch (scalar $ Number 10) `shouldReturn` pure (scalar $ Number 1)

    describe [G.rho] $ do
      describe "shape" $ do
        it "returns the shape of an array" $ do
          m P.rho (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [Number 3])
          m P.rho (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (vector [Number 2, Number 3])
      describe "reshape" $ do
        it "reshapes a vector into a matrix" $ do
          d P.rho (vector [Number 2, Number 3]) (vector [Number 1, Number 2, Number 3, Number 4, Number 5, Number 6]) `shouldReturn` pure (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]])
        it "recycles elements when there aren't enough" $ do
          d P.rho (vector [Number 2, Number 3]) (vector [Number 1, Number 2, Number 3, Number 4]) `shouldReturn` pure (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 1, Number 2]])
        it "discards extra elements" $ do
          d P.rho (vector [Number 2, Number 3]) (vector [Number 1, Number 2, Number 3, Number 4, Number 5, Number 6, Number 7, Number 8]) `shouldReturn` pure (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]])
        it "transforms empty vectors" $ do
          d P.rho (vector [Number 0]) (Array [0, 1] []) `shouldReturn` pure (vector [])
        it "fails when turning an empty vector into a nonempty vector" $ do
          e2m <$> d P.rho (vector [Number 1]) (vector []) `shouldReturn` Nothing
        it "takes the first item when reshaping to a scalar" $ do
          d P.rho (vector []) (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (scalar $ Number 1)
        it "fails when multiple negative numbers, or a negative number that's not ¯1" $ do
          e2m <$> d P.rho (vector [Number -2, Number 3]) (vector [Number 1, Number 2]) `shouldReturn` Nothing
          e2m <$> d P.rho (vector [Number 0, Number -1, Number -1]) (vector [Number 1, Number 2]) `shouldReturn` Nothing
        it "fails when there's a ¯1 and the amount of elements can't be fit" $ do
          e2m <$> d P.rho (vector [Number 2, Number -1]) (vector [Number 1, Number 2, Number 3]) `shouldReturn` Nothing
          e2m <$> d P.rho (vector [Number 0, Number -1]) (vector [Number 1, Number 2, Number 3]) `shouldReturn` Nothing
        it "reshapes arrays to a size that fits when a ¯1 is given" $ do
          d P.rho (vector [Number -1, Number 3]) (vector [Number 1, Number 2, Number 3, Number 4, Number 5, Number 6]) `shouldReturn` pure (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]])
          d P.rho (vector [Number 2, Number -1]) (vector [Number 1, Number 2, Number 3, Number 4, Number 5, Number 6]) `shouldReturn` pure (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]])
          d P.rho (vector [Number -1, Number 2]) (vector [Number 1, Number 2, Number 3, Number 4, Number 5, Number 6]) `shouldReturn` pure (fromMajorCells [vector [Number 1, Number 2], vector [Number 3, Number 4], vector [Number 5, Number 6]])
      
    describe [G.ravel] $ do
      describe "ravel" $ do
        it "returns the ravel of an array" $ do
          m P.ravel (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [Number 1, Number 2, Number 3])
          m P.ravel (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (vector [Number 1, Number 2, Number 3, Number 4, Number 5, Number 6])
          m P.ravel (scalar $ Number 1) `shouldReturn` pure (vector [Number 1])
    
    describe [G.reverse] $ do
      describe "reverse" $ do
        it "reverses arrays" $ do
          m P.reverse (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [Number 3, Number 2, Number 1])
          m P.reverse (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (fromMajorCells [vector [Number 4, Number 5, Number 6], vector [Number 1, Number 2, Number 3]])
          m P.reverse (scalar $ Number 1) `shouldReturn` pure (scalar $ Number 1)
      describe "rotate" $ do
        it "rotates arrays" $ do
          d P.reverse (scalar $ Number 1) (vector [Number 1, Number 2, Number 3, Number 4]) `shouldReturn` pure (vector [Number 2, Number 3, Number 4, Number 1])
          d P.reverse (scalar $ Number 3) (vector [Number 1, Number 2, Number 3, Number 4]) `shouldReturn` pure (vector [Number 4, Number 1, Number 2, Number 3])
          d P.reverse (scalar $ Number -1) (vector [Number 1, Number 2, Number 3, Number 4]) `shouldReturn` pure (vector [Number 4, Number 1, Number 2, Number 3])
          d P.reverse (scalar $ Number 0) (vector [Number 1, Number 2, Number 3, Number 4]) `shouldReturn` pure (vector [Number 1, Number 2, Number 3, Number 4])
        it "rotates arrays along multiple axes" $ do
          d P.reverse (vector [Number 1, Number 2]) (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (fromMajorCells [vector [Number 6, Number 4, Number 5], vector [Number 3, Number 1, Number 2]])
    
    describe [G.pair] $ do
      describe "half pair" $ do
        it "wraps an array into a box into a singleton vector" $ do
          m P.pair (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [box $ vector [Number 1, Number 2, Number 3]])
      describe "pair" $ do
        it "wraps two arrays into boxes into a pair vector" $ do
          d P.pair (vector [Number 1, Number 2, Number 3]) (vector [Number 4, Number 5, Number 6]) `shouldReturn` pure (vector [box $ vector [Number 1, Number 2, Number 3], box $ vector [Number 4, Number 5, Number 6]])
    
    describe [G.enclose] $ do
      describe "enclose" $ do
        it "wraps arrays into boxes" $ do
          m P.enclose (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (scalar $ box $ vector [Number 1, Number 2, Number 3])
        it "leaves simple scalars untouched" $ do
          m P.enclose (scalar $ Number 1) `shouldReturn` pure (scalar $ Number 1)
    
    describe [G.first] $ do
      describe "first" $ do
        it "returns the first element of a simple array" $ do
          m P.first (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (scalar $ Number 1)
        it "discloses boxes arrays" $ do
          m P.first (vector [box $ vector [Number 1, Number 2, Number 3], box $ vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (vector [Number 1, Number 2, Number 3])
        it "fails on an empty array" $ do
          e2m <$> m P.first (vector []) `shouldReturn` Nothing
    
    describe [G.last] $ do
      describe "last" $ do
        it "returns the last element of a simple array" $ do
          m P.last (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (scalar $ Number 3)
        it "discloses boxes arrays" $ do
          m P.last (vector [box $ vector [Number 1, Number 2, Number 3], box $ vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (vector [Number 4, Number 5, Number 6])
        it "fails on an empty array" $ do
          e2m <$> m P.last (vector []) `shouldReturn` Nothing
    
    describe [G.take] $ do
      describe "take" $ do
        it "takes the first elements of arrays" $ do
          d P.take (scalar $ Number 2) (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [Number 1, Number 2])
        it "takes the last elements of arrays" $ do
          d P.take (scalar $ Number -2) (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [Number 2, Number 3])
        it "takes elements across multiple axes" $ do
          d P.take (vector [Number 1, Number 2]) (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (fromMajorCells [vector [Number 1, Number 2]])

    describe [G.drop] $ do
      describe "drop" $ do
        it "drops the first elements of arrays" $ do
          d P.drop (scalar $ Number 1) (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [Number 2, Number 3])
        it "drops the last elements of arrays" $ do
          d P.drop (scalar $ Number -1) (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [Number 1, Number 2])
        it "drops elements across multiple axes" $ do
          d P.drop (vector [Number 1, Number 2]) (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (fromMajorCells [vector [Number 6]])

    describe [G.left] $ do
      describe "same" $ do
        it "returns the argument unchanged" $ do
          m P.left (scalar $ Number 1) `shouldReturn` pure (scalar $ Number 1)
      describe "left" $ do
        it "returns the left argument unchnanged" $ do
          d P.left (scalar $ Number 1) (scalar $ Number 2) `shouldReturn` pure (scalar $ Number 1)

    describe [G.right] $ do
      describe "same" $ do
        it "returns the argument unchanged" $ do
          m P.right (scalar $ Number 1) `shouldReturn` pure (scalar $ Number 1)
      describe "right" $ do
        it "returns the right argument unchnanged" $ do
          d P.right (scalar $ Number 1) (scalar $ Number 2) `shouldReturn` pure (scalar $ Number 2)
    
    describe [G.iota] $ do
      describe "index generator" $ do
        it "returns a vector of indices for scalar arguments" $ do
          m P.iota (scalar $ Number 3) `shouldReturn` pure (vector [Number 1, Number 2, Number 3])
        it "returns a higher-rank array for vector arguments" $ do
          m P.iota (vector [Number 2, Number 3]) `shouldReturn` pure (fromMajorCells
            [ vector [box $ vector [Number 1, Number 1], box $ vector [Number 1, Number 2], box $ vector [Number 1, Number 3]]
            , vector [box $ vector [Number 2, Number 1], box $ vector [Number 2, Number 2], box $ vector [Number 2, Number 3]] ])
    
    describe [G.indices] $ do
      describe "where" $ do
        it "returns indices of true values in a vector" $ do
          m P.indices (vector [Number 0, Number 1, Number 0, Number 1]) `shouldReturn` pure (vector [Number 2, Number 4])
        it "returns indices of true values in a higher-rank array" $ do
          m P.indices (fromMajorCells [vector [Number 0, Number 1, Number 0], vector [Number 1, Number 0, Number 1]]) `shouldReturn` pure (vector
            [ box $ vector [Number 1, Number 2]
            , box $ vector [Number 2, Number 1]
            , box $ vector [Number 2, Number 3] ])
        it "returns multiple indices for natural values" $ do
          m P.indices (vector [Number 0, Number 1, Number 2]) `shouldReturn` pure (vector [Number 2, Number 3, Number 3])

    describe [G.replicate] $ do
      describe "replicate" $ do
        it "replicates a vector" $ do
          d P.replicate (vector [Number 1, Number 0, Number 2]) (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [Number 1, Number 3, Number 3])
        it "replicates a higher-rank array" $ do
          d P.replicate (vector [Number 1, Number 0, Number 2]) (fromMajorCells [vector [Number 1, Number 2], vector [Number 3, Number 4], vector [Number 5, Number 6]]) `shouldReturn` pure (fromMajorCells [vector [Number 1, Number 2], vector [Number 5, Number 6], vector [Number 5, Number 6]])
        it "fails when the lengths of the arguments don't match" $ do
          e2m <$> d P.replicate (vector [Number 1, Number 0]) (vector [Number 2, Number 1, Number 5]) `shouldReturn` Nothing

    describe [G.abs] $ do
      describe "abs" $ do
        it "returns the absolute value of real numbers" $ do
          m P.abs (vector [Number 1, Number -2, Number 0]) `shouldReturn` pure (vector [Number 1, Number 2, Number 0])
        it "returns the magnitude of complex numbers" $ do
          m P.abs (vector [Number (1 :+ 1), Number (3 :+ -4)]) `shouldReturn` pure (vector [Number $ sqrt 2, Number 5])
      describe "residue" $ do
        it "returns the residue of division" $ do
          d P.abs (vector [Number 2, Number 2, Number 0.5]) (vector [Number 4, Number -5, Number 3.2]) `shouldReturn` pure (vector [Number 0, Number 1, Number 0.2])
        it "returns the right argument with zero left argument" $ do
          d P.abs (scalar $ Number 0) (scalar $ Number 3) `shouldReturn` pure (scalar $ Number 3)
    
    describe [G.phase] $ do
      describe "phase" $ do
        it "returns the phase of complex numbers" $ do
          m P.phase (vector [Number 1, Number -1, Number (0 :+ 1), Number (1 :+ 1)]) `shouldReturn` pure (vector [Number 0, Number pi, Number $ pi / 2, Number $ pi / 4])
      describe "set phase" $ do
        it "sets the phase of the left argument to the one of the right argument" $ do
          d P.phase (vector [Number 1, Number (0 :+ 2)]) (vector [Number pi, Number $ 3 * pi / 2]) `shouldReturn` pure (vector [Number -1, Number (0 :+ -2)])

    describe [G.real] $ do
      describe "real part" $ do
        it "returns the real part of the argument" $ do
          m P.real (vector [Number 1, Number (2 :+ 3), Number (0 :+ 5)]) `shouldReturn` pure (vector [Number 1, Number 2, Number 0])
      describe "set real part" $ do
        it "combines the imaginary part from the left argument and the real part from the right argument" $ do
          d P.real (vector [Number 1, Number (2 :+ 3), Number (0 :+ 5)]) (vector [Number (2 :+ 5), Number (3 :+ 1), Number 3]) `shouldReturn` pure (vector [Number 2, Number (3 :+ 3), Number (3 :+ 5)])
    
    describe [G.imag] $ do
      describe "imaginary part" $ do
        it "returns the imaginary part of the argument" $ do
          m P.imag (vector [Number 1, Number (2 :+ 3), Number (0 :+ 5)]) `shouldReturn` pure (vector [Number 0, Number 3, Number 5])
      describe "set imaginary part" $ do
        it "combines the real part from the left argument and the imaginary part from the right argument" $ do
          d P.imag (vector [Number 1, Number (2 :+ 3), Number (0 :+ 5)]) (vector [Number (2 :+ 5), Number (3 :+ 1), Number 3]) `shouldReturn` pure (vector [Number (1 :+ 5), Number (2 :+ 1), Number 0])

    describe [G.union] $ do
      describe "unique" $ do
        it "returns unique elements of an array" $ do
          m P.union (vector [Number 1, Number 2, Number 1, Number 3, Number 2]) `shouldReturn` pure (vector [Number 1, Number 2, Number 3])
      describe "union" $ do
        it "returns the union of two arrays" $ do
          d P.union (vector [Number 1, Number 1, Number 3]) (vector [Number 1, Number 2, Number 2, Number 3, Number 3]) `shouldReturn` pure (vector [Number 1, Number 1, Number 3, Number 2, Number 2])
    
    describe [G.intersection] $ do
      describe "intersection" $ do
        it "returns the intersection of two arrays" $ do
          d P.intersection (vector [Number 1, Number 2, Number 1]) (vector [Number 2, Number 2, Number 3]) `shouldReturn` pure (vector [Number 2])
    
    describe [G.difference] $ do
      describe "not" $ do
        it "inverts boolean values" $ do
          m P.difference (vector [Number 0, Number 1]) `shouldReturn` pure (vector [Number 1, Number 0])
        it "inverts probabilities" $ do
          m P.difference (vector [Number 0.25, Number 0.5, Number 0.9]) `shouldReturn` pure (vector [Number 0.75, Number 0.5, Number 0.1])
      describe "difference" $ do
        it "returns the difference of two arrays" $ do
          d P.difference (vector [Number 1, Number 1, Number 2, Number 2]) (vector [Number 2, Number 3]) `shouldReturn` pure (vector [Number 1, Number 1])
    
    describe [G.symdiff] $ do
      describe "symmetric difference" $ do
        it "returns the symmetric difference of two arrays" $ do
          d P.symdiff (vector [Number 1, Number 1, Number 2, Number 2]) (vector [Number 2, Number 3]) `shouldReturn` pure (vector [Number 1, Number 1, Number 3])
    
    describe [G.element] $ do
      describe "enlist" $ do
        it "flattens a nested array" $ do
          m P.element (fromMajorCells [vector [Number 1, box $ vector [Number 2, Number 3]], vector [Number 4, box $ vector [Number 5, box $ vector [Number 6, Number 7]]]]) `shouldReturn` pure (vector [Number 1, Number 2, Number 3, Number 4, Number 5, Number 6, Number 7])
  
  describe "adverbs" $ do
    describe [G.selfie] $ do
      describe "constant" $ do
        it "always returns the operand" $ do
          aam P.selfie (scalar $ Number 1) (scalar $ Number 2) `shouldReturn` pure (scalar $ Number 1)
          aad P.selfie (scalar $ Number 1) (scalar $ Number 2) (scalar $ Number 3) `shouldReturn` pure (scalar $ Number 1)
      describe "duplicate" $ do
        it "calls the operand with the same argument on both sides" $ do
          afm P.selfie P.plus (scalar $ Number 2) `shouldReturn` pure (scalar $ Number 4)
      describe "commute" $ do
        it "calls the operand with the arguments swapped" $ do
          afd P.selfie P.minus (scalar $ Number 2) (scalar $ Number 3) `shouldReturn` pure (scalar $ Number 1)

    describe [G.reduceDown] $ do
      describe "reduce down" $ do
        it "reduces an array top-to-bottom" $ do
          afm P.reduceDown P.plus (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (vector [Number 5, Number 7, Number 9])
          afm P.reduceDown P.minus (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (scalar $ Number -4)

    describe [G.reduceUp] $ do
      describe "reduce up" $ do
        it "reduces an array bottom-to-top" $ do
          afm P.reduceUp P.plus (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (vector [Number 5, Number 7, Number 9])
          afm P.reduceUp P.minus (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (scalar $ Number 2)

    describe [G.scanDown] $ do
      describe "scan down" $ do
        it "scans an array top-to-bottom (on prefixes)" $ do
          afm P.scanDown P.plus (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 5, Number 7, Number 9]])
          afm P.scanDown P.minus (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [Number 1, Number -1, Number -4])

    describe [G.scanUp] $ do
      describe "scan up" $ do
        it "scans an array bottom-to-top (on suffixes)" $ do
          afm P.scanUp P.plus (fromMajorCells [vector [Number 1, Number 2, Number 3], vector [Number 4, Number 5, Number 6]]) `shouldReturn` pure (fromMajorCells [vector [Number 5, Number 7, Number 9], vector [Number 4, Number 5, Number 6]])
          afm P.scanUp P.minus (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [Number 2, Number -1, Number 3])
    
    describe [G.each] $ do
      describe "monad each" $ do
        it "applies a function to each element of an array" $ do
          afm P.each P.iota (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [box $ vector [Number 1], box $ vector [Number 1, Number 2], box $ vector [Number 1, Number 2, Number 3]])
      describe "dyad each" $ do
        it "applies a function to each pair of elements of two arrays" $ do
          afd P.each P.intersection (vector [box $ vector [Number 1, Number 2], box $ vector [Number 1, Number 3]]) (vector [box $ vector [Number 1], box $ vector [Number 1, Number 2, Number 3]]) `shouldReturn` pure (vector [box $ vector [Number 1], box $ vector [Number 1, Number 3]])

    describe [G.eachLeft] $ do
      describe "each left" $ do
        it "applies a function to each element of the left argument and to the right argument" $ do
          afd P.eachLeft P.intersection (vector [box $ vector [Number 1, Number 2, Number 4], box $ vector [Number 1, Number 3]]) (vector [Number 1, Number 2, Number 3]) `shouldReturn` pure (vector [box $ vector [Number 1, Number 2], box $ vector [Number 1, Number 3]])

    describe [G.eachRight] $ do
      describe "each right" $ do
        it "applies a function to the left argument and to each element of the right argument" $ do
          afd P.eachRight P.intersection (vector [Number 1, Number 2, Number 3]) (vector [box $ vector [Number 2, Number 3], box $ vector [Number 2, Number 1, Number 2]]) `shouldReturn` pure (vector [box $ vector [Number 2, Number 3], box $ vector [Number 1, Number 2]])

  describe "conjunctions" $ do
    describe [G.atop] $ do
      describe "atop" $ do
        it "monadically composes functions with f(gy)" $ do
          cffm P.atop P.times P.minus (scalar $ Number 3) `shouldReturn` pure (scalar $ Number -1)
        it "dyadically composes functions with f(xgy)" $ do
          cffd P.atop P.times P.minus (scalar $ Number 3) (scalar $ Number 5) `shouldReturn` pure (scalar $ Number -1)
    
    describe [G.over] $ do
      describe "over" $ do
        it "monadically composes functions with f(gy)" $ do
          cffm P.over P.times P.minus (scalar $ Number 3) `shouldReturn` pure (scalar $ Number -1)
        it "dyadically composes functions with (gy)f(gx)" $ do
          cffd P.over P.plus P.minus (scalar $ Number 1) (scalar $ Number 2) `shouldReturn` pure (scalar $ Number -3)

    describe [G.after] $ do
      describe "after" $ do
        it "monadically composes functions with f(gy)" $ do
          cffm P.after P.times P.minus (scalar $ Number 3) `shouldReturn` pure (scalar $ Number -1)
        it "dyadically composes functions with xf(gy)" $ do
          cffd P.after P.plus P.minus (scalar $ Number 2) (scalar $ Number 1) `shouldReturn` pure (scalar $ Number 1)
      describe "bind" $ do
        it "binds the left argument to a dyad" $ do
          cafm P.after (scalar $ Number 1) P.minus (scalar $ Number 2) `shouldReturn` pure (scalar $ Number -1)
        it "binds the right argument to a dyad" $ do
          cfam P.after P.minus (scalar $ Number 1) (scalar $ Number 2) `shouldReturn` pure (scalar $ Number 1)
        it "fails if called dyadically" $ do
          e2m <$> cafd P.after (scalar $ Number 1) P.minus (scalar $ Number 2) (scalar $ Number 3) `shouldReturn` Nothing
          e2m <$> cfad P.after P.minus (scalar $ Number 1) (scalar $ Number 2) (scalar $ Number 3) `shouldReturn` Nothing
    
    describe [G.before] $ do
      describe "before" $ do
        it "monadically composes functions with g(fy)" $ do
          cffm P.before P.minus P.times (scalar $ Number 3) `shouldReturn` pure (scalar $ Number -1)  
        it "dyadically composes functions with (fx)gy" $ do
          cffd P.before P.minus P.plus (scalar $ Number 1) (scalar $ Number 2) `shouldReturn` pure (scalar $ Number 1)
      describe "default bind" $ do
        it "binds the argument to a function when called monadically" $ do
          cafm P.before (scalar $ Number 1) P.minus (scalar $ Number 2) `shouldReturn` pure (scalar $ Number -1)
          cfam P.before P.minus (scalar $ Number 1) (scalar $ Number 2) `shouldReturn` pure (scalar $ Number 1)
        it "ignores the operand when called dyadically" $ do
          cafd P.before (scalar $ Number 1) P.plus (scalar $ Number 2) (scalar $ Number 3) `shouldReturn` pure (scalar $ Number 5)
          cfad P.before P.minus (scalar $ Number 1) (scalar $ Number 5) (scalar $ Number 2) `shouldReturn` pure (scalar $ Number 3)
    
    describe [G.leftHook] $ do
      describe "left hook" $ do
        it "monadically composes functions with (fx)gx" $ do
          cffm P.leftHook P.minus P.plus (scalar $ Number 3) `shouldReturn` pure (scalar $ Number 0)
        it "dyadically composes functions with (fx)gy" $ do
          cffd P.leftHook P.minus P.plus (scalar $ Number 1) (scalar $ Number 2) `shouldReturn` pure (scalar $ Number 1)

    describe [G.rightHook] $ do
      describe "right hook" $ do
        it "monadically composes functions with xf(gx)" $ do
          cffm P.rightHook P.plus P.minus (scalar $ Number 5) `shouldReturn` pure (scalar $ Number 0)
        it "dyadically composes functions with xf(gy)" $ do
          cffd P.rightHook P.plus P.minus (scalar $ Number 2) (scalar $ Number 1) `shouldReturn` pure (scalar $ Number 1)