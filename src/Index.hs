module Index
  ( Index(..)
  -- * Constructors
  , new
  , insert
  , rewind
  -- * Projections
  , IndexView(..)
  , view
  , getFunction
  , getHistory
  -- * Helpers
  , insertL
  -- * Testing
  , ObservedBuilder (..)
  , GrammarBuilder (..)
  , ixSignature
  ) where

import           Control.Monad   (replicateM)
import           Data.Foldable   (foldl')
import           Data.Maybe      (fromJust)
import           GHC.Generics
import           QuickSpec
import           Test.QuickCheck (Arbitrary (..), CoArbitrary (..), Gen,
                                  arbitrarySizedIntegral, chooseInt, frequency,
                                  listOf, shrinkNothing, sized)

{- | Laws
  Constructors: new, insert, rewind
  Observations: view [depth, view, size], getHistory, getFunction

  Laws derived by constructors/observations:

    view (new f d a) =
      | d > 0     = IndexView [d a 0]
      | otherwise = Nothing
    getHistory (new f d a) = [a]
    view (insertL bs (new f d a)) = IndexView [d (foldl' f a bs) (max (length bs) d)]
    getHistory (insertL bs (new f d a)) = take d bs
    rewind n (new f d a) = Nothing
    view <$> (rewind n (insertL bs (new f d a))) =
      | n <= length bs = IndexView [d a' ((max (length bs) d) - n)]
        where a' = head $ drop n $ scanl' f a bs
      | otherwise = nothing
    getHistory (rewind n (insertL bs (new f d a))) = drop n $ scanl' f a bs

  Laws derived by interplay of constructors:

    d >= length bs =>
      obs (rewind (length bs) (insertL bs (new f d a))) = obs (new f d a)
    rewind _ (new f d a) = Nothing
    depth >= size
-}

data Index a e = New (a -> e -> a) Int a
               | Insert e (Index a e)
               | Rewind Int (Index a e)

instance (Show a, Show e) => Show (Index a e) where
  show (New _ depth acc) = "New <f> " <> show depth <> " " <> show acc
  show (Insert b ix)     = "Insert " <> show b <> " (" <> show ix <> ")"
  show (Rewind n ix)     = "Rewind " <> show n <> " (" <> show ix <> ")"

newtype GrammarBuilder a e = GrammarBuilder (Index a e)
  deriving (Show)

newtype ObservedBuilder a e = ObservedBuilder (Index a e)
  deriving (Show)

data IndexView a = IndexView
  { ixDepth :: Int
  , ixView  :: a
  , ixSize  :: Int -- ^ Size represents the stored history elements
  } deriving (Show, Ord, Eq, Typeable, Generic)

-- | Constructors

new :: (a -> e -> a) -> Int -> a -> Index a e
new = New

insert :: e -> Index a e -> Index a e
insert = Insert

rewind :: Int -> Index a e -> Index a e
rewind = Rewind

-- | Observations

view :: Index a e -> Maybe (IndexView a)
view (New _ depth initial) =
  if depth > 0
  then pure $ IndexView { ixDepth = depth
                        , ixView  = initial
                        , ixSize  = 1
                        }
  else Nothing
view (Insert e ix) = do
  let f = getFunction ix
  v <- view ix
  pure $ v { ixView = f (ixView v) e
           , ixSize = min (ixDepth v) (ixSize v + 1)
           }
view (Rewind n ix) = do
  h <- getHistory ix
  v <- view ix
  if length h > n
  then Just $ v { ixSize = ixSize v - n
                , ixView = head $ drop n h
                }
  else Nothing

-- | Internal

getFunction :: Index a e -> (a -> e -> a)
getFunction (New f _ _)   = f
getFunction (Insert _ ix) = getFunction ix
getFunction (Rewind _ ix) = getFunction ix

getHistory :: Index a e -> Maybe [a]
getHistory (New _ _ i) = Just [i]
getHistory (Insert e ix) = do
  let f = getFunction ix
  h <- getHistory ix
  v <- view ix
  pure $ f (head h) e : take (ixDepth v - 1) h
getHistory (Rewind n ix) = do
  h <- getHistory ix
  if length h > n
  then Just $ drop n h
  else Nothing

-- | Utility

insertL :: [e] -> Index a e -> Index a e
insertL es ix = foldl' (flip insert) ix es

-- | QuickCheck

instance ( CoArbitrary a
         , CoArbitrary e
         , Arbitrary a
         , Arbitrary e ) => Arbitrary (ObservedBuilder a e) where
  arbitrary = sized $ \n -> do
    depth <- frequency [ (05, pure 1)                       -- overfill
                       , (40, chooseInt (2, n + 2))         -- about filled
                       , (40, chooseInt (n + 2, n * 2 + 2)) -- not filled
                       ]
    overflow <- chooseInt (depth, depth * 2)
    acc <- arbitrary
    fn  <- arbitrary
    bs    <- frequency [ (05, pure [])                       -- empty
                       , (50, arbitrary)                     -- randomized
                       , (30, replicateM (depth `div` 2)     -- half filled
                                         arbitrary)
                       , (10, replicateM overflow arbitrary) -- overfilled
                       , (05, replicateM depth    arbitrary) -- exact
                       ]
    -- Construction can only fail due to NonPositive depth
    -- Tested with prop_hfNewReturns...
    let ix = new fn depth acc
    pure . ObservedBuilder $ insertL bs ix

instance ( CoArbitrary a
         , CoArbitrary e
         , Arbitrary a
         , Arbitrary e ) => Arbitrary (Index a e) where
  -- Use the ObservedIndex instance as a generator for Indexes
  arbitrary = do
    (ObservedBuilder ix) <- arbitrary
    pure ix
  shrink = shrinkNothing

instance ( CoArbitrary a
         , CoArbitrary e
         , Arbitrary a
         , Arbitrary e ) => Arbitrary (GrammarBuilder a e) where
  arbitrary = sized $ \n -> do
    depth <- frequency [ (05, pure 1)                       -- overfill
                       , (40, chooseInt (2, n + 2))         -- about filled
                       , (40, chooseInt (n + 2, n * 2 + 2)) -- not filled
                       ]
    f     <- arbitrary
    acc   <- arbitrary
    let ix = new f depth acc
    complexity <- arbitrarySizedIntegral
    generateGrammarIndex complexity ix

generateGrammarIndex :: Arbitrary e => Int -> Index a e -> Gen (GrammarBuilder a e)
generateGrammarIndex 0 ix = pure $ GrammarBuilder ix
generateGrammarIndex n ix = do
  b      <- arbitrary
  -- This should be correct by construction (the incorrect cases are not very
  -- interesting).
  d      <- chooseInt (1, ixDepth . fromJust $ view ix)
  nextIx <- frequency [ (80, pure            $ insert b ix)
                      , (20, pure            $ rewind d ix)
                      ]
  generateGrammarIndex (n - 1) nextIx

instance Arbitrary a => Arbitrary (IndexView a) where
  arbitrary = sized $ \n -> do
    depth <- chooseInt (2, n)
    size  <- chooseInt (0, depth)
    view'  <- arbitrary
    pure IndexView { ixDepth = depth
                   , ixSize  = size
                   , ixView  = view'
                   }

-- | QuickSpec

newtype IxEvents e = IxEvents [e]
  deriving (Eq, Ord, Typeable)

instance Arbitrary e => Arbitrary (IxEvents e) where
  arbitrary = IxEvents <$> listOf arbitrary

instance ( Ord a
         , Arbitrary a
         , Arbitrary e
         , CoArbitrary a
         , CoArbitrary e) => Observe (IxEvents e) (IndexView a) (Index a e) where
  observe (IxEvents es) ix = fromJust $ view $ insertL es ix

ixSignature :: [Sig]
ixSignature =
  [ monoObserve @(Index Int String)
  , monoObserve @(Index Int Int)
  , monoObserve @(Index Int [Int])
  , monoObserve @(Maybe (Index Int String))
  , monoObserve @(Maybe (Index Int Int))
  , monoObserve @(Maybe (Index Int [Int]))
  , mono @(IndexView Int)
  , con "new" (new :: (Int -> String -> Int) -> Int -> Int -> Index Int String)
  , con "insert" (insert :: String -> Index Int String -> Index Int String)
  , con "view" (view :: Index Int String -> Maybe (IndexView Int))
  , con "rewind" (rewind :: Int -> Index Int String -> Index Int String)
  , con "getHistory" (getHistory :: Index Int String -> Maybe [Int])
  , withMaxTermSize 6
  ]
