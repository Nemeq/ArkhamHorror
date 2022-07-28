module Arkham.Agenda.Cards.ACreatureOfTheBayou
  ( ACreatureOfTheBayou(..)
  , aCreatureOfTheBayou
  ) where

import Arkham.Prelude

import Arkham.Agenda.Cards qualified as Cards
import Arkham.Scenarios.CurseOfTheRougarou.Helpers
import Arkham.Agenda.Attrs
import Arkham.Agenda.Helpers hiding (matches)
import Arkham.Agenda.Runner
import Arkham.Classes
import Arkham.Location.Attrs (Field(..))
import Arkham.GameValue
import Arkham.Message
import Arkham.Projection
import Arkham.Target

newtype ACreatureOfTheBayou = ACreatureOfTheBayou AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

aCreatureOfTheBayou :: AgendaCard ACreatureOfTheBayou
aCreatureOfTheBayou =
  agenda (1, A) ACreatureOfTheBayou Cards.aCreatureOfTheBayou (Static 5)

instance RunMessage ACreatureOfTheBayou where
  runMessage msg a@(ACreatureOfTheBayou attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && onSide B attrs -> do
      mrougarou <- getTheRougarou
      case mrougarou of
        Nothing -> a <$ pushAll
          [ ShuffleEncounterDiscardBackIn
          , AdvanceAgendaDeck agendaDeckId (toSource attrs)
          , PlaceDoomOnAgenda
          ]
        Just eid -> do
          leadInvestigatorId <- getLeadInvestigatorId
          targets <- setToList <$> nonBayouLocations
          nonBayouLocationsWithClueCounts <-
            sortOn snd
              <$> traverse (traverseToSnd (field LocationClues)) targets
          let
            moveMessage = case nonBayouLocationsWithClueCounts of
              [] -> error "there has to be such a location"
              ((_, c) : _) ->
                let
                  (matches, _) =
                    span ((== c) . snd) nonBayouLocationsWithClueCounts
                in
                  case matches of
                    [(x, _)] -> MoveUntil x (EnemyTarget eid)
                    xs -> chooseOne
                      leadInvestigatorId
                      [ MoveUntil x (EnemyTarget eid) | (x, _) <- xs ]
          a <$ pushAll
            [ ShuffleEncounterDiscardBackIn
            , moveMessage
            , AdvanceAgendaDeck agendaDeckId (toSource attrs)
            ]
    _ -> ACreatureOfTheBayou <$> runMessage msg attrs
