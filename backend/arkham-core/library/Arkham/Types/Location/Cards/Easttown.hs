{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Location.Cards.Easttown where

import Arkham.Import

import Arkham.Types.Location.Attrs
import Arkham.Types.Location.Runner
import Arkham.Types.Trait

newtype Easttown = Easttown Attrs
  deriving newtype (Show, ToJSON, FromJSON)

easttown :: Easttown
easttown = Easttown $ baseAttrs
  "01132"
  "Easttown"
  2
  (PerPlayer 1)
  Moon
  [Circle, Triangle]
  [Arkham]

instance HasModifiersFor env Easttown where
  getModifiersFor _ (InvestigatorTarget iid) (Easttown attrs) =
    pure [ ReduceCostOf [Ally] 2 | iid `member` locationInvestigators attrs ]
  getModifiersFor _ _ _ = pure []

instance ActionRunner env => HasActions env Easttown where
  getActions i window (Easttown attrs) = getActions i window attrs

instance (LocationRunner env) => RunMessage env Easttown where
  runMessage msg (Easttown attrs) = Easttown <$> runMessage msg attrs
