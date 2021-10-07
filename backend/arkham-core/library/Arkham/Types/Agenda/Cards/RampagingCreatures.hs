module Arkham.Types.Agenda.Cards.RampagingCreatures
  ( RampagingCreatures(..)
  , rampagingCreatures
  ) where

import Arkham.Prelude

import Arkham.Agenda.Cards qualified as Cards
import Arkham.Scenarios.UndimensionedAndUnseen.Helpers
import Arkham.Types.Ability
import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Runner
import Arkham.Types.Classes
import Arkham.Types.Game.Helpers
import Arkham.Types.GameValue
import Arkham.Types.Matcher hiding (ChosenRandomLocation)
import Arkham.Types.Message
import Arkham.Types.Phase
import Arkham.Types.Target
import Arkham.Types.Timing qualified as Timing

newtype RampagingCreatures = RampagingCreatures AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

rampagingCreatures :: AgendaCard RampagingCreatures
rampagingCreatures =
  agenda (1, A) RampagingCreatures Cards.rampagingCreatures (Static 5)

instance HasAbilities RampagingCreatures where
  getAbilities (RampagingCreatures x) =
    [mkAbility x 1 $ ForcedAbility $ PhaseEnds Timing.When $ PhaseIs EnemyPhase]

instance AgendaRunner env => RunMessage env RampagingCreatures where
  runMessage msg a@(RampagingCreatures attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source -> do
      leadInvestigatorId <- getLeadInvestigatorId
      broodOfYogSothoth <- map EnemyTarget
        <$> getSetList (EnemyWithTitle "Brood of Yog-Sothoth")
      a <$ when
        (notNull broodOfYogSothoth)
        (push $ chooseOneAtATime
          leadInvestigatorId
          [ TargetLabel target [ChooseRandomLocation target mempty]
          | target <- broodOfYogSothoth
          ]
        )
    ChosenRandomLocation target@(EnemyTarget _) lid | onSide A attrs ->
      a <$ push (MoveToward target (LocationWithId lid))
    ChosenRandomLocation target lid | isTarget attrs target && onSide B attrs ->
      do
        setAsideBroodOfYogSothoth <- shuffleM =<< getSetAsideBroodOfYogSothoth
        case setAsideBroodOfYogSothoth of
          [] -> pure a
          (x : _) -> a <$ push (CreateEnemyAt x lid Nothing)
    AdvanceAgenda aid | aid == agendaId attrs && onSide B attrs -> a <$ pushAll
      [ ShuffleEncounterDiscardBackIn
      , ChooseRandomLocation (toTarget attrs) mempty
      , NextAgenda aid "02238"
      ]
    _ -> RampagingCreatures <$> runMessage msg attrs
