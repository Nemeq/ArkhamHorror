module Arkham.Treachery.Cards.Tekelili_228
  ( tekelili_228
  , Tekelili_228(..)
  )
where

import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Import.Lifted

newtype Tekelili_228 = Tekelili_228 TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

tekelili_228 :: TreacheryCard Tekelili_228
tekelili_228 = treachery Tekelili_228 Cards.tekelili_228

instance RunMessage Tekelili_228 where
  runMessage msg t@(Tekelili_228 attrs) = runQueueT $ case msg of
    Revelation _iid (isSource attrs -> True) -> pure t
    _ -> Tekelili_228 <$> liftRunMessage msg attrs
