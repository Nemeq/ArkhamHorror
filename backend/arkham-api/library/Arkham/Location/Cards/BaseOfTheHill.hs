module Arkham.Location.Cards.BaseOfTheHill (baseOfTheHill) where

import Arkham.Ability
import Arkham.Action qualified as Action
import Arkham.GameValue
import Arkham.Helpers.Modifiers (ModifierType (..), modifySelectWhen)
import Arkham.Helpers.Query
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted
import Arkham.Matcher

newtype BaseOfTheHill = BaseOfTheHill LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

baseOfTheHill :: LocationCard BaseOfTheHill
baseOfTheHill =
  locationWith BaseOfTheHill Cards.baseOfTheHill 3 (Static 0)
    $ revealedConnectedMatchersL
    <>~ [LocationWithTitle "Diverging Path"]

instance HasModifiersFor BaseOfTheHill where
  getModifiersFor (BaseOfTheHill a) = do
    modifySelectWhen a a.revealed (LocationWithTitle "Diverging Path") [ConnectedToWhen (be a) Anywhere]

instance HasAbilities BaseOfTheHill where
  getAbilities (BaseOfTheHill attrs) =
    withResignAction
      attrs
      [ withTooltip
          "{action}: _Investigate_. If you succeed, instead of discovering clues, put a random set-aside Diverging Path into play. (Limit once per round.)"
          $ limitedAbility (PlayerLimit PerRound 1)
          $ investigateAbility attrs 1 mempty Here
      | attrs.revealed
      ]

instance RunMessage BaseOfTheHill where
  runMessage msg l@(BaseOfTheHill attrs) = runQueueT $ case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      sid <- getRandom
      investigate sid iid (attrs.ability 1)
      pure l
    Successful (Action.Investigate, _) _ (isAbilitySource attrs 1 -> True) _ _ -> do
      divergingPaths <- getSetAsideCardsMatching $ CardWithTitle "Diverging Path"
      for_ (nonEmpty divergingPaths) (sample >=> placeLocation_)
      pure l
    _ -> BaseOfTheHill <$> liftRunMessage msg attrs
