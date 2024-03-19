module Arkham.Treachery.Cards.WhisperingChaosWest
  ( whisperingChaosWest
  , WhisperingChaosWest(..)
  )
where

import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Import.Lifted

newtype WhisperingChaosWest = WhisperingChaosWest TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

whisperingChaosWest :: TreacheryCard WhisperingChaosWest
whisperingChaosWest = treachery WhisperingChaosWest Cards.whisperingChaosWest

instance RunMessage WhisperingChaosWest where
  runMessage msg t@(WhisperingChaosWest attrs) = runQueueT $ case msg of
    Revelation _iid (isSource attrs -> True) -> pure t
    _ -> WhisperingChaosWest <$> lift (runMessage msg attrs)
