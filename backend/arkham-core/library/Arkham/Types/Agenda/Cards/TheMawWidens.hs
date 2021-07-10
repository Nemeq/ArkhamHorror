module Arkham.Types.Agenda.Cards.TheMawWidens
  ( TheMawWidens(..)
  , theMawWidens
  ) where

import Arkham.Prelude

import Arkham.Types.Agenda.Attrs
import Arkham.Types.Agenda.Helpers
import Arkham.Types.Agenda.Runner
import Arkham.Types.Classes
import Arkham.Types.Direction
import Arkham.Types.GameValue
import Arkham.Types.LocationId
import Arkham.Types.Message
import Arkham.Types.Query

newtype TheMawWidens = TheMawWidens AgendaAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theMawWidens :: TheMawWidens
theMawWidens =
  TheMawWidens $ baseAttrs "02161" "The Maw Widens" (Agenda 2 A) (Static 3)

instance HasModifiersFor env TheMawWidens

instance HasActions env TheMawWidens where
  getActions i window (TheMawWidens x) = getActions i window x

leftmostLocation
  :: ( MonadReader env m
     , HasId (Maybe LocationId) env (Direction, LocationId)
     , MonadIO m
     )
  => LocationId
  -> m LocationId
leftmostLocation lid = do
  mlid' <- getId (LeftOf, lid)
  maybe (pure lid) leftmostLocation mlid'

instance AgendaRunner env => RunMessage env TheMawWidens where
  runMessage msg a@(TheMawWidens attrs@AgendaAttrs {..}) = case msg of
    AdvanceAgenda aid | aid == agendaId && agendaSequence == Agenda 2 B -> do
      leadInvestigatorId <- unLeadInvestigatorId <$> getId ()
      investigatorIds <- getInvestigatorIds
      locationId <- getId @LocationId leadInvestigatorId
      lid <- leftmostLocation locationId
      a <$ pushAll
        (RemoveLocation lid
        : [ InvestigatorDiscardAllClues iid | iid <- investigatorIds ]
        <> [NextAgenda agendaId "02162"]
        )
    _ -> TheMawWidens <$> runMessage msg attrs
