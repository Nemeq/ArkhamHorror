module Arkham.Treachery.Cards.WrackedByNightmaresSpec
  ( spec
  ) where

import TestImport.Lifted

import Arkham.Asset.Attrs ( Field (..) )
import Arkham.Asset.Attrs qualified as Asset
import Arkham.Investigator.Attrs ( Field (..) )
import Arkham.Treachery.Attrs ( Field (..) )
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Matcher hiding (AssetExhausted)
import Arkham.Projection

spec :: Spec
spec = describe "Wracked by Nightmares" $ do
  it "prevents controlled assets from readying" $ do
    investigator <- testInvestigator id
    wrackedByNightmares <- genPlayerCard Cards.wrackedByNightmares
    asset <- testAsset
      ((Asset.exhaustedL .~ True) . (Asset.controllerL ?~ toId investigator))
    gameTest
        investigator
        [ loadDeck investigator [wrackedByNightmares]
        , drawCards investigator 1
        , ReadyExhausted
        ]
        (entitiesL . assetsL %~ insertEntity asset)
      $ do
          runMessages
          selectAny
              (TreacheryInThreatAreaOf (InvestigatorWithId $ toId investigator)
              <> treacheryIs Cards.wrackedByNightmares
              )
            `shouldReturn` True
          fieldAssert AssetExhausted (== True) asset

  it "trigger actions removes restriction and takes two actions" $ do
    investigator <- testInvestigator id
    wrackedByNightmares <- genPlayerCard Cards.wrackedByNightmares
    asset <- testAsset
      ((Asset.exhaustedL .~ True) . (Asset.ownerL ?~ toId investigator))
    gameTest
        investigator
        [loadDeck investigator [wrackedByNightmares], drawCards investigator 1]
        (entitiesL . assetsL %~ insertEntity asset)
      $ do
          runMessages
          wrackedByNightmaresId <- selectJust AnyTreachery
          [discardWrackedByNightmares] <- field
            TreacheryAbilities
            wrackedByNightmaresId
          pushAll
            [ UseAbility (toId investigator) discardWrackedByNightmares []
            , ReadyExhausted
            ]
          runMessages
          selectAny
              (TreacheryInThreatAreaOf (InvestigatorWithId $ toId investigator)
              <> treacheryIs Cards.wrackedByNightmares
              )
            `shouldReturn` False
          fieldAssert AssetExhausted (== True) asset
          fieldAssert
            InvestigatorDiscard
            (== [wrackedByNightmares])
            investigator
          fieldAssert InvestigatorRemainingActions (== 1) investigator
