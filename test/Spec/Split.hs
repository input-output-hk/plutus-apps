{-# LANGUAGE NamedFieldPuns #-}

module Spec.Split where

import           Data.Maybe              (catMaybes)
import           Test.QuickCheck         (Property)
import           Test.QuickCheck.Monadic (PropertyM, monadicIO)

import           Index                   (Index, IndexView (..))
import qualified Index                   as Ix
import           Index.Split             (SplitIndex (..))
import qualified Index.Split             as S
import           Spec.Index              (Conversion (..))

conversion :: (Show a, Show e, Show n) => Conversion (PropertyM IO) a e n
conversion = Conversion
  { cView          = view
  , cHistory       = history
  , cNotifications = undefined
  , cMonadic       = monadic
  }

view
  :: (Show a, Show e, Show n)
  => Index a e n
  -> PropertyM IO (Maybe (IndexView a))
view ix = do
  mix <- run ix
  case mix of
    Nothing  -> pure Nothing
    Just ix' -> do
      v <- S.view ix'
      pure $ Just v

history
  :: (Show a, Show e, Show n)
  => Index a e n
  -> PropertyM IO (Maybe [a])
history ix = do
  mix <- run ix
  case mix of
    Nothing  -> pure Nothing
    Just ix' -> do
      h <- S.getHistory ix'
      pure $ Just h

monadic
  :: PropertyM IO Property
  -> Property
monadic = monadicIO

run
  :: forall m a e n. (Show a, Show e, Show n, Monad m)
  => Index a e n
  -> m (Maybe (SplitIndex m a e n))
run (Ix.New f d a) = pure $ S.new findex fstore d (pure a)
  where
    findex :: a -> [e] -> (a, [n])
    findex a' es = foldr convertIxF (a', []) es
    fstore :: a -> m a
    fstore a' = pure a'
    convertIxF :: e -> (a, [n]) -> (a, [n])
    convertIxF e (a', ns) =
      let (a'', mn) = f a' e
       in (a'', catMaybes [mn] ++ ns)
run (Ix.Insert e ix) = do
  mix <- run ix
  case  mix of
    Nothing  -> pure Nothing
    Just ix' -> do
      nix <- S.insert e ix'
      pure $ Just nix
run (Ix.Rewind n ix) = do
  mix <- run ix
  case mix of
    Nothing  -> pure Nothing
    Just ix' -> pure $ S.rewind n ix'

