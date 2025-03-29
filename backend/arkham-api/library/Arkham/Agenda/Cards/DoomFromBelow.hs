module Arkham.Agenda.Cards.DoomFromBelow (doomFromBelow) where

import Arkham.Ability
import Arkham.Agenda.Cards qualified as Cards
import Arkham.Agenda.Import.Lifted
import Arkham.Matcher hiding (DuringTurn)
import Arkham.Message.Lifted.Choose
import Arkham.Message.Lifted.Move

newtype DoomFromBelow = DoomFromBelow AgendaAttrs
  deriving anyclass (IsAgenda, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

doomFromBelow :: AgendaCard DoomFromBelow
doomFromBelow = agenda (1, A) DoomFromBelow Cards.doomFromBelow (Static 10)

instance HasAbilities DoomFromBelow where
  getAbilities (DoomFromBelow attrs) =
    [ withTooltip
        "During your turn, spend 1 clue: Look at the revealed side of a City Landscape in your column or row. (Limit once per round.)"
        $ playerLimit PerRound
        $ restricted
          attrs
          1
          ( DuringTurn You
              <> exists
                ( UnrevealedLocation
                    <> oneOf
                      [ LocationInRowOf (LocationWithInvestigator You)
                      , LocationInColumnOf (LocationWithInvestigator You)
                      ]
                )
          )
        $ FastAbility (ClueCost $ Static 1)
    , withTooltip
        "During your turn, spend 3 clues: Move to any location in your column or row. (Limit once per round.)"
        $ playerLimit PerRound
        $ restricted
          attrs
          1
          (DuringTurn You <> exists (CanEnterLocation You))
        $ FastAbility (ClueCost $ Static 3)
    ]

instance RunMessage DoomFromBelow where
  runMessage msg a@(DoomFromBelow attrs) = runQueueT $ case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      ls <-
        select
          $ UnrevealedLocation
          <> oneOf
            [ LocationInRowOf (locationWithInvestigator iid)
            , LocationInColumnOf (locationWithInvestigator iid)
            ]
      chooseTargetM iid ls $ lookAtRevealed iid (attrs.ability 1)
      pure a
    UseThisAbility iid (isSource attrs -> True) 2 -> do
      ls <- select $ CanMoveToLocation (InvestigatorWithId iid) (attrs.ability 2) Anywhere
      chooseTargetM iid ls $ moveTo (attrs.ability 1) iid
      pure a
    AdvanceAgenda (isSide B attrs -> True) -> do
      push R2
      pure a
    _ -> DoomFromBelow <$> liftRunMessage msg attrs
