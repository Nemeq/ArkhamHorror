module Arkham.Types.Helpers where

import Arkham.Prelude hiding (unpack, toUpper, toLower)

import Data.Aeson.Text
import Data.Foldable (foldrM)
import qualified Data.HashMap.Strict as HashMap
import qualified Data.HashSet as HashSet
import qualified Data.List as L
import Data.List.NonEmpty (NonEmpty)
import qualified Data.List.NonEmpty as NE
import Data.Text.Lazy (unpack)
import Data.Text.Lazy.Builder
import Data.Char (isLetter, toLower, toUpper)

mapSet :: (Hashable b, Eq b) => (a -> b) -> HashSet a -> HashSet b
mapSet = HashSet.map

toLabel :: String -> String
toLabel [] = []
toLabel (x : xs) = toLower x : go xs
 where
  go [] = []
  go (' ' : x' : xs') = toUpper x' : go xs'
  go (x' : xs') = x' : go xs'

replaceNonLetters :: String -> String
replaceNonLetters [] = []
replaceNonLetters (x : xs) = if not (isLetter x)
  then ' ' : replaceNonLetters xs
  else x : replaceNonLetters xs

cycleN :: Int -> [a] -> [a]
cycleN n as = take (length as * n) $ L.cycle as

uncurry4 :: (a -> b -> c -> d -> e) -> (a, b, c, d) -> e
uncurry4 f ~(a, b, c, d) = f a b c d

toFst :: (a -> b) -> a -> (b, a)
toFst f a = (f a, a)

mapFrom
  :: IsMap map => (MapValue map -> ContainerKey map) -> [MapValue map] -> map
mapFrom f = mapFromList . map (toFst f)

toSnd :: (a -> b) -> a -> (a, b)
toSnd f a = (a, f a)

traverseToSnd :: Functor m => (a -> m b) -> a -> m (a, b)
traverseToSnd f a = (a, ) <$> f a

maxes :: [(a, Int)] -> [a]
maxes ps = case sortedPairs of
  [] -> []
  ((_, c) : _) -> map fst $ takeWhile ((== c) . snd) sortedPairs
  where sortedPairs = sortOn (Down . snd) ps

concatMapM'
  :: (Monad m, MonoFoldable mono) => (Element mono -> m [b]) -> mono -> m [b]
concatMapM' f xs = concatMapM f (toList xs)

foldTokens :: (Foldable t, Monad m) => b -> t a -> (b -> a -> m b) -> m b
foldTokens s tokens f = foldrM (flip f) s tokens

count :: (a -> Bool) -> [a] -> Int
count = (length .) . filter

countM :: Monad m => (a -> m Bool) -> [a] -> m Int
countM = ((length <$>) .) . filterM

sample :: MonadRandom m => NonEmpty a -> m a
sample xs = do
  idx <- getRandomR (0, NE.length xs - 1)
  pure $ xs NE.!! idx

infix 9 !!?
(!!?) :: [a] -> Int -> Maybe a
(!!?) xs i
  | i < 0 = Nothing
  | otherwise = go i xs
 where
  go :: Int -> [a] -> Maybe a
  go 0 (x : _) = Just x
  go j (_ : ys) = go (j - 1) ys
  go _ [] = Nothing
{-# INLINE (!!?) #-}

drawCard :: [a] -> (Maybe a, [a])
drawCard [] = (Nothing, [])
drawCard (x : xs) = (Just x, xs)

newtype Deck a = Deck { unDeck :: [a] }
  deriving newtype (Semigroup, Monoid, ToJSON, FromJSON, Eq)

instance Show (Deck a) where
  show _ = "<Deck>"

newtype Bag a = Bag { unBag :: [a] }
  deriving newtype (Semigroup, Monoid, ToJSON, FromJSON)

instance Show (Bag a) where
  show _ = "<Bag>"

data With a b = With a b

instance (Eq a, Eq b) => Eq (With a b) where
  With a1 b1 == With a2 b2 = a1 == a2 && b1 == b2

instance (ToJSON a, ToJSON b) => ToJSON (a `With` b) where
  toJSON (a `With` b) = case (toJSON a, toJSON b) of
    (Object o, Object m) -> Object $ HashMap.union m o
    (a', b') -> metadataError a' b'
   where
    metadataError a' b' =
      error
        . unpack
        . toLazyText
        $ "With failed to serialize to object: "
        <> "\nattrs: "
        <> encodeToTextBuilder a'
        <> "\nmetadata: "
        <> encodeToTextBuilder b'

instance (FromJSON a, FromJSON b) => FromJSON (a `With` b) where
  parseJSON = withObject "With"
    $ \o -> With <$> parseJSON (Object o) <*> parseJSON (Object o)

instance (Show a, Show b) => Show (a `With` b) where
  show (With a b) = show a <> " WITH " <> show b

with :: a -> b -> a `With`  b
with a b = With a b
