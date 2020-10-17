{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Act.Cards.DisruptingTheRitual where

import Arkham.Import

import Arkham.Types.Act.Attrs
import qualified Arkham.Types.Act.Attrs as Act
import Arkham.Types.Act.Helpers
import Arkham.Types.Act.Runner

newtype DisruptingTheRitual = DisruptingTheRitual Attrs
  deriving newtype (Show, ToJSON, FromJSON)

disruptingTheRitual :: DisruptingTheRitual
disruptingTheRitual =
  DisruptingTheRitual $ (baseAttrs "01148" "Disrupting the Ritual" "Act 3a")
    { actClues = Just 0
    }

instance ActionRunner env => HasActions env DisruptingTheRitual where
  getActions iid NonFast (DisruptingTheRitual Attrs {..}) = do
    hasActionsRemaining <- getHasActionsRemaining iid Nothing mempty
    spendableClueCount <- getSpendableClueCount [iid]
    pure
      [ ActivateCardAbilityAction
          iid
          (mkAbility (ActSource actId) 1 (ActionAbility 1 Nothing))
      | hasActionsRemaining && spendableClueCount > 0
      ]
  getActions i window (DisruptingTheRitual x) = getActions i window x

instance ActRunner env => RunMessage env DisruptingTheRitual where
  runMessage msg a@(DisruptingTheRitual attrs@Attrs {..}) = case msg of
    AdvanceAct aid | aid == actId && actSequence == "Act 3a" -> do
      leadInvestigatorId <- getLeadInvestigatorId
      unshiftMessage (chooseOne leadInvestigatorId [AdvanceAct actId])
      pure
        $ DisruptingTheRitual
        $ attrs
        & (Act.sequence .~ "Act 3b")
        & (flipped .~ True)
    AdvanceAct aid | aid == actId && actSequence == "Act 3a" ->
      a <$ unshiftMessage (Resolution 1)
    PlaceClues (ActTarget aid) n | aid == actId -> do
      requiredClues <- getPlayerCountValue (PerPlayer 2)
      let totalClues = n + fromJustNote "Must be set" actClues
      when (totalClues >= requiredClues) (unshiftMessage (AdvanceAct actId))
      pure $ DisruptingTheRitual (attrs { actClues = Just totalClues })
    UseCardAbility iid (ActSource aid) _ 1 | aid == actId -> do
      a <$ unshiftMessage
        (chooseOne
          iid
          [ BeginSkillTest
            iid
            (ActSource actId)
            (ActTarget actId)
            Nothing
            SkillWillpower
            3
            [PlaceClues (ActTarget actId) 1]
            mempty
            mempty
            mempty
          , BeginSkillTest
            iid
            (ActSource actId)
            (ActTarget actId)
            Nothing
            SkillAgility
            3
            [PlaceClues (ActTarget actId) 1]
            mempty
            mempty
            mempty
          ]
        )
    _ -> DisruptingTheRitual <$> runMessage msg attrs
