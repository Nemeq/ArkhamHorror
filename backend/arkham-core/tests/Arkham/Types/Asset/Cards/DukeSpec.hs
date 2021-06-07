module Arkham.Types.Asset.Cards.DukeSpec
  ( spec
  )
where

import TestImport

import qualified Arkham.Types.Enemy.Attrs as Enemy
import Arkham.Types.Investigator.Attrs (InvestigatorAttrs(..))
import Arkham.Types.Location.Attrs (LocationAttrs(..))

spec :: Spec
spec = describe "Duke" $ do
  context "fight action" $ do
    it "uses a base combat skill of 4 and does +1 damage" $ do
      duke <- buildAsset "02014"
      enemy <- testEnemy ((Enemy.healthL .~ Static 3) . (Enemy.fightL .~ 4))
      investigator <- testInvestigator "00000"
        $ \attrs -> attrs { investigatorCombat = 1 }
      location <- testLocation "00000" id
      game <- runGameTest
        investigator
        [ SetTokens [Zero]
        , playAsset investigator duke
        , enemySpawn location enemy
        , moveTo investigator location
        ]
        ((enemiesL %~ insertEntity enemy)
        . (locationsL %~ insertEntity location)
        . (assetsL %~ insertEntity duke)
        )
      let dukeAsset = game ^?! assetsL . to toList . ix 0
      [fightAction, _] <- getActionsOf game investigator NonFast dukeAsset
      game' <-
        runGameTestMessages game [fightAction]
        >>= runGameTestOnlyOption "Fight enemy"
        >>= runGameTestOnlyOption "Start skill test"
        >>= runGameTestOnlyOption "Apply Results"
      updated game' enemy `shouldSatisfy` hasDamage (2, 0)
  context "investigate action" $ do
    it "uses a base intellect skill of 4" $ do
      duke <- buildAsset "02014"
      investigator <- testInvestigator "00000"
        $ \attrs -> attrs { investigatorIntellect = 1 }
      location <- testLocation
        "00000"
        (\attrs -> attrs { locationShroud = 4, locationClues = 1 })
      game <- runGameTest
        investigator
        [ SetTokens [Zero]
        , moveTo investigator location
        , playAsset investigator duke
        ]
        ((locationsL %~ insertEntity location) . (assetsL %~ insertEntity duke))
      let dukeAsset = game ^?! assetsL . to toList . ix 0
      [investigateAction] <- getActionsOf game investigator NonFast dukeAsset
      game' <-
        runGameTestMessages
          game
          [moveTo investigator location, investigateAction]
        >>= runGameTestOnlyOption "Start skill test"
        >>= runGameTestOnlyOption "Apply results"
      updated game' investigator `shouldSatisfy` hasClueCount 1
    it "you may move to a connecting location immediately before investigating"
      $ do
          duke <- buildAsset "02014"
          investigator <- testInvestigator "00000"
            $ \attrs -> attrs { investigatorIntellect = 1 }
          (location1, location2) <- testConnectedLocations id
            $ \attrs -> attrs { locationShroud = 4, locationClues = 1 }
          game <- runGameTest
            investigator
            [ placedLocation location1
            , placedLocation location2
            , SetTokens [Zero]
            , moveTo investigator location1
            , playAsset investigator duke
            ]
            ((locationsL %~ insertEntity location1)
            . (locationsL %~ insertEntity location2)
            . (assetsL %~ insertEntity duke)
            )
          let dukeAsset = game ^?! assetsL . to toList . ix 0
          [investigateAction] <- toInternalGame game
            >>= runReaderT (getActions (toId investigator) NonFast dukeAsset)
          game' <-
            runGameTestMessages
              game
              [moveTo investigator location1, investigateAction]
            >>= runGameTestOptionMatching
                  "move first"
                  (\case
                    Run{} -> True
                    _ -> False
                  )
            >>= runGameTestOnlyOption "Start skill test"
            >>= runGameTestOnlyOption "Apply results"
          updated game' investigator `shouldSatisfy` hasClueCount 1
