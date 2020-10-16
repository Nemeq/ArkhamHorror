{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Act.Cards.FindingLadyEsprit
  ( FindingLadyEsprit(..)
  , findingLadyEsprit
  )
where

import Arkham.Import

import Arkham.Types.Act.Attrs
import qualified Arkham.Types.Act.Attrs as Act
import Arkham.Types.Act.Helpers
import Arkham.Types.Act.Runner
import Arkham.Types.EncounterSet (gatherEncounterSet)
import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Trait

newtype FindingLadyEsprit = FindingLadyEsprit Attrs
  deriving newtype (Show, ToJSON, FromJSON)

findingLadyEsprit :: FindingLadyEsprit
findingLadyEsprit =
  FindingLadyEsprit $ baseAttrs "81005" "Finding Lady Esprit" "Act 1a"

instance HasActions env investigator FindingLadyEsprit where
  getActions i window (FindingLadyEsprit x) = getActions i window x

investigatorsInABayouLocation
  :: ( MonadReader env m
     , HasSet LocationId [Trait] env
     , HasSet InvestigatorId (HashSet LocationId) env
     )
  => m [InvestigatorId]
investigatorsInABayouLocation =
  bayouLocations >>= asks . (setToList .) . getSet

bayouLocations
  :: (MonadReader env m, HasSet LocationId [Trait] env)
  => m (HashSet LocationId)
bayouLocations = asks $ getSet [Bayou]

nonBayouLocations
  :: ( MonadReader env m
     , HasSet LocationId () env
     , HasSet LocationId [Trait] env
     )
  => m (HashSet LocationId)
nonBayouLocations = difference <$> getLocationSet <*> bayouLocations

instance ActRunner env => RunMessage env FindingLadyEsprit where
  runMessage msg a@(FindingLadyEsprit attrs@Attrs {..}) = case msg of
    AdvanceAct aid | aid == actId && actSequence == "Act 1a" -> do
      investigatorIds <- investigatorsInABayouLocation
      requiredClueCount <- getPlayerCountValue (PerPlayer 1)
      unshiftMessages
        (SpendClues requiredClueCount investigatorIds
        : [ chooseOne iid [AdvanceAct aid] | iid <- investigatorIds ]
        )
      pure
        $ FindingLadyEsprit
        $ attrs
        & (Act.sequence .~ "Act 1b")
        & (flipped .~ True)
    AdvanceAct aid | aid == actId && actSequence == "Act 1b" -> do
      [ladyEspritSpawnLocation] <- setToList <$> bayouLocations
      a <$ unshiftMessages
        [ CreateStoryAssetAt "81019" ladyEspritSpawnLocation
        , PutSetAsideIntoPlay (SetAsideLocations mempty)
        , NextAdvanceActStep aid 2
        ]
    NextAdvanceActStep aid 2 | aid == actId && actSequence == "Act 1b" -> do
      leadInvestigatorId <- getLeadInvestigatorId
      curseOfTheRougarouSet <- gatherEncounterSet
        EncounterSet.CurseOfTheRougarou
      rougarouSpawnLocations <- setToList <$> nonBayouLocations
      a <$ unshiftMessages
        ([ chooseOne
             leadInvestigatorId
             [ CreateEnemyAt "81028" lid | lid <- rougarouSpawnLocations ]
         ]
        <> [ ShuffleEncounterDiscardBackIn
           , ShuffleIntoEncounterDeck curseOfTheRougarouSet
           , AddCampaignCardToDeck leadInvestigatorId "81029"
           , CreateWeaknessInThreatArea "81029" leadInvestigatorId
           ]
        )
    PrePlayerWindow -> do
      investigatorIds <- investigatorsInABayouLocation
      requiredClueCount <- getPlayerCountValue (PerPlayer 1)
      canAdvance' <- (>= requiredClueCount)
        <$> getSpendableClueCount investigatorIds
      pure $ FindingLadyEsprit $ attrs & canAdvance .~ canAdvance'
    _ -> FindingLadyEsprit <$> runMessage msg attrs
