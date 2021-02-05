module Arkham.Types.Location.Cards.Schoolhouse_212
  ( schoolhouse_212
  , Schoolhouse_212(..)
  ) where

import Arkham.Import

import qualified Arkham.Types.EncounterSet as EncounterSet
import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype Schoolhouse_212 = Schoolhouse_212 LocationAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

schoolhouse_212 :: Schoolhouse_212
schoolhouse_212 = Schoolhouse_212 $ baseAttrs
  "02212"
  (Name "Schoolhouse" Nothing)
  EncounterSet.BloodOnTheAltar
  4
  (Static 1)
  Moon
  [Plus, Squiggle, Circle]
  [Dunwich]

instance HasModifiersFor env Schoolhouse_212 where
  getModifiersFor = noModifiersFor

instance ActionRunner env => HasActions env Schoolhouse_212 where
  getActions iid window (Schoolhouse_212 attrs) = getActions iid window attrs

instance LocationRunner env => RunMessage env Schoolhouse_212 where
  runMessage msg (Schoolhouse_212 attrs) =
    Schoolhouse_212 <$> runMessage msg attrs
