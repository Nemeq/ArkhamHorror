module Arkham.Helpers.Xp where

import Arkham.Classes.HasGame
import Arkham.Classes.Query
import Arkham.Helpers.Card
import Arkham.Helpers.Modifiers
import Arkham.Helpers.Query
import Arkham.Helpers.Scenario
import Arkham.I18n
import Arkham.Id
import Arkham.Matcher
import Arkham.Message
import Arkham.Name
import Arkham.Prelude
import Arkham.Scenario.Types (Field (..))
import Arkham.Source
import Arkham.Xp
import GHC.Records

toGainXp :: (HasGame m, Sourceable source) => source -> m [(InvestigatorId, Int)] -> m [Message]
toGainXp (toSource -> source) f = map (\(iid, n) -> GainXP iid source n) <$> f

getXp :: HasGame m => m [(InvestigatorId, Int)]
getXp = getXpWithBonus 0

getXpWithBonus :: forall m. (HasCallStack, HasGame m) => Int -> m [(InvestigatorId, Int)]
getXpWithBonus bonus = do
  victoryPileVictory <- toVictory =<< getVictoryDisplay
  locationVictory <- toVictory =<< select (RevealedLocation <> LocationWithoutClues)
  let initialAmount = bonus + getSum (victoryPileVictory <> locationVictory)
  investigatorIds <- allInvestigatorIds
  for investigatorIds $ \iid -> do
    modifiers' <- getModifiers iid
    pure (iid, foldl' applyModifier initialAmount modifiers')
 where
  applyModifier n (XPModifier _ m) = max 0 (n + m)
  applyModifier n _ = n
  toVictory :: ConvertToCard c => [c] -> m (Sum Int)
  toVictory = fmap (mconcat . map Sum . catMaybes) . traverse getVictoryPoints

data XpBonus = NoBonus | WithBonus Text Int | MultiBonus [XpBonus]

instance Monoid XpBonus where
  mempty = NoBonus

instance Semigroup XpBonus where
  NoBonus <> a = a
  a <> NoBonus = a
  MultiBonus xs <> MultiBonus ys = MultiBonus (xs <> ys)
  MultiBonus xs <> y = MultiBonus (xs <> [y])
  x <> MultiBonus ys = MultiBonus (x : ys)
  x <> y = MultiBonus [x, y]

xpBonusToXp :: XpBonus -> Int
xpBonusToXp = \case
  NoBonus -> 0
  WithBonus _ x -> x
  MultiBonus xs -> sum $ map xpBonusToXp xs

toBonus :: HasI18n => Text -> Int -> XpBonus
toBonus k n = scope "xp" $ WithBonus ("$" <> ikey k) n

flattenBonus :: XpBonus -> [XpBonus]
flattenBonus = \case
  NoBonus -> []
  MultiBonus xs -> xs
  x@WithBonus {} -> [x]

instance HasField "value" XpBonus Int where
  getField = xpBonusToXp

instance HasField "flatten" XpBonus [XpBonus] where
  getField = flattenBonus

generateXpReport :: forall m. (HasCallStack, HasGame m) => XpBonus -> m XpBreakdown
generateXpReport bonus = do
  victoryPileVictory <- fmap (map AllGainXp) . toVictory =<< scenarioField ScenarioVictoryDisplay
  locationVictory <-
    fmap (map AllGainXp) . toVictory =<< select (RevealedLocation <> LocationWithoutClues)
  investigatorIds <- allInvestigatorIds
  fromModifiers <- concatForM investigatorIds $ \iid -> do
    modifiers' <- getModifiers iid
    pure $ mapMaybe (modifierToXpDetail iid) modifiers'
  pure
    $ XpBreakdown
    $ [ InvestigatorGainXp iid $ XpDetail XpBonus txt n | WithBonus txt n <- bonus.flatten, iid <- investigatorIds
      ]
    <> victoryPileVictory
    <> locationVictory
    <> fromModifiers
 where
  modifierToXpDetail iid (XPModifier lbl m) | m > 0 = Just (InvestigatorGainXp iid $ XpDetail XpFromCardEffect lbl m)
  modifierToXpDetail iid (XPModifier lbl m) | m < 0 = Just (InvestigatorLoseXp iid $ XpDetail XpFromCardEffect lbl m)
  modifierToXpDetail _ _ = Nothing
  toVictory :: ConvertToCard c => [c] -> m [XpDetail]
  toVictory = mapMaybeM toEntry
  toEntry c = do
    card <- convertToCard c
    XpDetail XpFromVictoryDisplay (toTitle card) <$$> getVictoryPoints c
