module Arkham.Enemy.Cards.PursuingMotorcar
  ( pursuingMotorcar
  , PursuingMotorcar(..)
  )
where

import Arkham.Enemy.Cards qualified as Cards
import Arkham.Enemy.Import.Lifted

newtype PursuingMotorcar = PursuingMotorcar EnemyAttrs
  deriving anyclass (IsEnemy, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

pursuingMotorcar :: EnemyCard PursuingMotorcar
pursuingMotorcar = enemy PursuingMotorcar Cards.pursuingMotorcar (4, Static 4, 2) (2, 0)

instance RunMessage PursuingMotorcar where
  runMessage msg (PursuingMotorcar attrs) = runQueueT $ case msg of
    _ -> PursuingMotorcar <$> liftRunMessage msg attrs
