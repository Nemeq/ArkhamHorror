module Arkham.Event.Cards.Elusive where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Movement

newtype Elusive = Elusive EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

elusive :: EventCard Elusive
elusive = event Elusive Cards.elusive

instance RunMessage Elusive where
  runMessage msg e@(Elusive attrs) = case msg of
    PlayThisEvent iid eid | attrs `is` eid -> do
      enemies <- selectList $ enemyEngagedWith iid
      targets <- selectList $ EmptyLocation <> RevealedLocation
      pushAll
        $ map (DisengageEnemy iid) enemies
        <> [ chooseOrRunOne iid
            $ targetLabels targets (only . MoveTo . move (toSource attrs) iid)
           | notNull targets
           ]
        <> map EnemyCheckEngagement enemies
      pure e
    _ -> Elusive <$> runMessage msg attrs
