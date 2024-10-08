module Arkham.Asset.Assets.PocketTelescope (
  pocketTelescope,
  PocketTelescope (..),
)
where

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Import.Lifted
import Arkham.Investigate
import Arkham.Matcher
import Arkham.Modifier

newtype PocketTelescope = PocketTelescope AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

pocketTelescope :: AssetCard PocketTelescope
pocketTelescope = asset PocketTelescope Cards.pocketTelescope

instance HasAbilities PocketTelescope where
  getAbilities (PocketTelescope a) =
    [ restrictedAbility a 1 (ControlsThis <> exists UnrevealedLocation) $ FastAbility (exhaust a)
    , restrictedAbility
        a
        2
        (ControlsThis <> exists (RevealedLocation <> ConnectedLocation <> InvestigatableLocation))
        $ ActionAbility [#investigate]
        $ ActionCost 1
    ]

instance RunMessage PocketTelescope where
  runMessage msg a@(PocketTelescope attrs) = runQueueT $ case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      locations <- select UnrevealedLocation
      chooseOne
        iid
        [ targetLabel location [LookAtRevealed iid (attrs.ability 1) (toTarget location)]
        | location <- locations
        ]
      pure a
    UseThisAbility iid (isSource attrs -> True) 2 -> do
      locations <- select (RevealedLocation <> ConnectedLocation <> InvestigatableLocation)
      chooseOne
        iid
        [ targetLabel location [HandleTargetChoice iid (attrs.ability 2) (toTarget location)]
        | location <- locations
        ]
      pure a
    HandleTargetChoice iid (isAbilitySource attrs 2 -> True) (LocationTarget lid) -> do
      abilityModifier (AbilityRef (toSource attrs) 2) (attrs.ability 2) iid (AsIfAt lid)
      sid <- getRandom
      pushM $ mkInvestigateLocation sid iid (attrs.ability 2) lid
      pure a
    _ -> PocketTelescope <$> liftRunMessage msg attrs
