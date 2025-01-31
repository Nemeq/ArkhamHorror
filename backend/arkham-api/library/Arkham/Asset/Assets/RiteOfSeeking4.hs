module Arkham.Asset.Assets.RiteOfSeeking4 (riteOfSeeking4, RiteOfSeeking4 (..)) where

import Arkham.Ability
import Arkham.Aspect hiding (aspect)
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Import.Lifted
import Arkham.Asset.Uses
import Arkham.Effect.Import
import Arkham.Helpers.Investigator
import Arkham.Investigate
import Arkham.Modifier

newtype RiteOfSeeking4 = RiteOfSeeking4 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

riteOfSeeking4 :: AssetCard RiteOfSeeking4
riteOfSeeking4 = asset RiteOfSeeking4 Cards.riteOfSeeking4

instance HasAbilities RiteOfSeeking4 where
  getAbilities (RiteOfSeeking4 a) = [investigateAbility a 1 (assetUseCost a Charge 1) ControlsThis]

instance RunMessage RiteOfSeeking4 where
  runMessage msg a@(RiteOfSeeking4 attrs) = runQueueT $ case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      let source = toAbilitySource attrs 1
      lid <- getJustLocation iid
      sid <- getRandom

      -- same effect as base
      createCardEffect Cards.riteOfSeeking (effectMetaTarget sid) source (InvestigationTarget iid lid)
      skillTestModifiers sid source iid [SkillModifier #willpower 2, DiscoveredClues 2]
      aspect iid source (#willpower `InsteadOf` #intellect) (mkInvestigate sid iid source)
      pure a
    _ -> RiteOfSeeking4 <$> liftRunMessage msg attrs
