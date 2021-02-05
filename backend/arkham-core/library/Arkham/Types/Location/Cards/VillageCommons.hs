module Arkham.Types.Location.Cards.VillageCommons
  ( villageCommons
  , VillageCommons(..)
  ) where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype VillageCommons = VillageCommons LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

villageCommons :: VillageCommons
villageCommons = VillageCommons $ baseAttrs
  "02201"
  (Name "Village Commons" Nothing)
  EncounterSet.BloodOnTheAltar
  3
  (Static 0)
  Plus
  [Square, Circle, Moon]
  [Dunwich, Central]

instance HasModifiersFor env VillageCommons where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env VillageCommons where
  getActions iid window (VillageCommons attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env VillageCommons where
  runMessage msg (VillageCommons attrs) =
    VillageCommons <$> runMessage msg attrs
