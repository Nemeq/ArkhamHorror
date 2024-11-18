module Arkham.Treachery.Cards.Tekelili_226
  ( tekelili_226
  , Tekelili_226(..)
  )
where

import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Import.Lifted

newtype Tekelili_226 = Tekelili_226 TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

tekelili_226 :: TreacheryCard Tekelili_226
tekelili_226 = treachery Tekelili_226 Cards.tekelili_226

instance RunMessage Tekelili_226 where
  runMessage msg t@(Tekelili_226 attrs) = runQueueT $ case msg of
    Revelation _iid (isSource attrs -> True) -> pure t
    _ -> Tekelili_226 <$> liftRunMessage msg attrs
