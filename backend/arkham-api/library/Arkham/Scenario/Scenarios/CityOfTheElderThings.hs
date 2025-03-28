module Arkham.Scenario.Scenarios.CityOfTheElderThings (cityOfTheElderThings) where

import Data.Map.Strict qualified as Map
import Arkham.Act.Cards qualified as Acts
import Arkham.Agenda.Cards qualified as Agendas
import Arkham.Asset.Cards qualified as Assets
import Arkham.Campaigns.EdgeOfTheEarth.Helpers
import Arkham.Campaigns.EdgeOfTheEarth.Key
import Arkham.Campaigns.EdgeOfTheEarth.Supplies
import Arkham.Card.CardDef
import Arkham.Key
import Arkham.Message.Lifted.Move (moveAllTo)
import Arkham.EncounterSet qualified as Set
import Arkham.FlavorText
import Arkham.Helpers.ChaosBag
import Arkham.Helpers.Query
import Arkham.Helpers.Text
import Arkham.Location.Cards qualified as Locations
import Arkham.Location.Grid
import Arkham.Matcher
import Arkham.Message.Lifted.Choose
import Arkham.Scenario.Import.Lifted
import Arkham.Scenarios.CityOfTheElderThings.Helpers
import Arkham.Treachery.Cards qualified as Treacheries

newtype CityOfTheElderThings = CityOfTheElderThings ScenarioAttrs
  deriving anyclass (IsScenario, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

cityOfTheElderThings :: Difficulty -> CityOfTheElderThings
cityOfTheElderThings difficulty =
  scenario
    CityOfTheElderThings
    "08621"
    "City of the Elder Things"
    difficulty
    []

instance HasChaosTokenValue CityOfTheElderThings where
  getChaosTokenValue iid tokenFace (CityOfTheElderThings attrs) = case tokenFace of
    Skull -> pure $ toChaosTokenValue attrs Skull 3 5
    Cultist -> pure $ ChaosTokenValue Cultist NoModifier
    Tablet -> pure $ ChaosTokenValue Tablet NoModifier
    ElderThing -> pure $ ChaosTokenValue ElderThing NoModifier
    otherFace -> getChaosTokenValue iid otherFace attrs

cityLandscapes :: [CardDef]
cityLandscapes = [ Locations.ancientPlanetarium
        , Locations.stoneBridge
        , Locations.stoneBridge
        , Locations.stoneBridge
        , Locations.cylindricalTower
        , Locations.labyrinthineChamber
        , Locations.labyrinthineChamber
        , Locations.mapRoom
        , Locations.rooflessRampart
        , Locations.ruinousStreets
        , Locations.ruinousStreets
        , Locations.cyclopeanSpires
        , Locations.submergedPassageway
        , Locations.submergedPassageway
        , Locations.templeOfTheElderThings
        , Locations.templeOfTheElderThings
        ]

allKeys :: MonadRandom m => m [ArkhamKey]
allKeys = do
  skull1 <- toKey <$> createChaosToken #skull
  skull2 <- toKey <$> createChaosToken #skull
  cultist1 <- toKey <$> createChaosToken #cultist
  cultist2 <- toKey <$> createChaosToken #cultist
  tablet1 <- toKey <$> createChaosToken #tablet
  tablet2 <- toKey <$> createChaosToken #tablet
  elderThing1 <- toKey <$> createChaosToken #elderthing
  elderThing2 <- toKey <$> createChaosToken #elderthing
  zero1 <- toKey <$> createChaosToken #"0"
  zero2 <- toKey <$> createChaosToken #"0"
  minusOne1 <- toKey <$> createChaosToken #"-1"
  minusOne2 <- toKey <$> createChaosToken #"-1"
  minusTwo1 <- toKey <$> createChaosToken #"-2"
  minusTwo2 <- toKey <$> createChaosToken #"-2"
  minusThree1 <- toKey <$> createChaosToken #"-3"
  minusThree2 <- toKey <$> createChaosToken #"-3"
  shuffleM [ skull1
       , skull2
       , cultist1
       , cultist2
       , tablet1
       , tablet2
       , elderThing1
       , elderThing2
       , zero1
       , zero2
       , minusOne1
       , minusOne2
       , minusTwo1
       , minusTwo2
       , minusThree1
       , minusThree2
       ]

instance RunMessage CityOfTheElderThings where
  runMessage msg s@(CityOfTheElderThings attrs) = runQueueT $ scenarioI18n $ case msg of
    PreScenarioSetup -> do
      story $ i18nWithTitle "intro"
      sinhaIsAlive <- getPartnerIsAlive Assets.drMalaSinhaDaringPhysician
      blueStory
        $ validateEntry sinhaIsAlive "sinha.alive"
        <> hr
        <> validateEntry (not sinhaIsAlive) "sinha.otherwise"

      unless sinhaIsAlive do
        eachInvestigator \iid -> addCampaignCardToDeck iid DoNotShuffleIn Treacheries.frostbitten

      scoutedTheCityOutskirts <- getHasRecord TheInvestigatorsScoutedTheCityOutskirts
      story
        $ i18n "descend"
        <> blueFlavor
          ( validateEntry scoutedTheCityOutskirts "scoutedTheCityOutskirts.yes"
              <> hr
              <> validateEntry (not scoutedTheCityOutskirts) "scoutedTheCityOutskirts.no"
          )

      dyerIsAlive <- getPartnerIsAlive Assets.professorWilliamDyerProfessorOfGeology
      blueStory
        $ validateEntry dyerIsAlive "dyer.alive"
        <> hr
        <> validateEntry (not dyerIsAlive) "dyer.otherwise"

      unless dyerIsAlive do
        eachInvestigator \iid -> addCampaignCardToDeck iid DoNotShuffleIn Treacheries.possessed

      story $ i18n "entrance"

      cookieIsAlive <- getPartnerIsAlive Assets.jamesCookieFredericksDubiousChoice
      dynamiteRecovered <- hasSupply Dynamite
      blueStory
        $ validateEntry (cookieIsAlive && dynamiteRecovered) "cookie.alive"
        <> hr
        <> validateEntry (not $ cookieIsAlive && dynamiteRecovered) "cookie.otherwise"

      unless (dyerIsAlive && dynamiteRecovered) do
        whenM hasRemainingFrostTokens $ addChaosToken #frost

      story $ i18n "trail"

      kenslerIsAlive <- getPartnerIsAlive Assets.drAmyKenslerProfessorOfBiology
      ellsworthIsAlive <- getPartnerIsAlive Assets.roaldEllsworthIntrepidExplorer
      danforthIsAlive <- getPartnerIsAlive Assets.danforthBrilliantStudent
      hirokoIsAlive <- getPartnerIsAlive Assets.takadaHirokoAeroplaneMechanic
      eliyahIsAlive <- getPartnerIsAlive Assets.eliyahAshevakDogHandler
      claypoolIsAlive <- getPartnerIsAlive Assets.averyClaypoolAntarcticGuide

      let group1Count = length $ filter id [kenslerIsAlive, ellsworthIsAlive, sinhaIsAlive]
      let group2Count = length $ filter id [danforthIsAlive, hirokoIsAlive, eliyahIsAlive]
      let group3Count = length $ filter id [dyerIsAlive, claypoolIsAlive, cookieIsAlive]
      let group1 = group1Count > group2Count && group1Count > group3Count
      let group2 = group2Count > group1Count && group2Count > group3Count
      let group3 = group3Count > group1Count && group3Count > group2Count
      let tied = not (group1 || group2 || group3)

      story
        $ toFlavor
        $ p "votes"
        <> cols
          [ p "group1" <> ul do
              li.validate kenslerIsAlive "vote.kensler"
              li.validate ellsworthIsAlive "vote.ellsworth"
              li.validate sinhaIsAlive "vote.sinha"
          , p "group2" <> ul do
              li.validate danforthIsAlive "vote.danforth"
              li.validate hirokoIsAlive "vote.hiroko"
              li.validate eliyahIsAlive "vote.eliyah"
          , p "group3" <> ul do
              li.validate dyerIsAlive "vote.dyer"
              li.validate claypoolIsAlive "vote.claypool"
              li.validate cookieIsAlive "vote.cookie"
          ]
        <> ul do
          li.validate group1 "vote.group1"
          li.validate group2 "vote.group2"
          li.validate group3 "vote.group3"
          li.validate tied "vote.tied"

      when tied do
        lead <- getLead
        chooseOneM lead do
          labeled "Proceed to _Setup (v. I)_" $ doStep 1 msg
          labeled "Proceed to _Setup (v. II)_" $ doStep 2 msg
          labeled "Proceed to _Setup (v. III)_" $ doStep 3 msg

      when group1 $ doStep 1 msg
      when group2 $ doStep 2 msg
      when group3 $ doStep 3 msg

      eachInvestigator (`forInvestigator` PreScenarioSetup)
      pure s
    DoStep n PreScenarioSetup -> do
      pure $ CityOfTheElderThings $ attrs & metaL .~ toJSON n
    ForInvestigator iid PreScenarioSetup -> do
      partners <- getRemainingPartners
      unless (null partners) do
        chooseOneM iid do
          questionLabeled "Choose a partner for this scenario"
          labeled "Do not take a partner" nothing
          for_ partners \partner -> do
            inPlay <- selectAny $ assetIs partner.cardCode
            unless inPlay do
              cardLabeled partner.cardCode $ handleTarget iid ScenarioSource (CardCodeTarget partner.cardCode)
      pure s
    Setup -> do
      doStep (toResult @Int attrs.meta) msg
      pure s
    DoStep 1 Setup -> runScenarioSetup CityOfTheElderThings attrs do
      gather Set.CityOfTheElderThings
      gather Set.ElderThings
      gather Set.Miasma
      gather Set.NamelessHorrors
      gather Set.Penguins
      gather Set.Tekelili
      gather Set.LockedDoors
      gatherAndSetAside Set.Shoggoths
      setActDeck [Acts.sprawlingCityV1, Acts.pursuitOfTheUnknownV1]
      setAgendaDeck [Agendas.lurkingHorrors, Agendas.doomFromBelow]
      setUsesGrid
      placeInGrid_ (Pos 0 0) Locations.hiddenTunnelEntranceToTheDepths
      {- FOURMOLU_DISABLE -}
      let
        positions =
          [ Pos (-1) (-2), Pos 0 (-2)  -- top row
          , Pos (-1) (-1), Pos 0 (-1), Pos 1 (-1), Pos 2 (-1)  -- second row
          , Pos (-2) 0, Pos (-1) 0, Pos 1 0, Pos 2 0 -- middle
          , Pos (-2) 1, Pos (-1) 1, Pos 0 1, Pos 1 1 -- fourth row
          , Pos 0 2, Pos 1 2  -- bottom row
          ]
      {- FOURMOLU_ENABLE -}
      locations <- shuffleM cityLandscapes
      locationMap <- Map.fromList <$> for (zip positions locations) \(pos, loc) ->
        (pos,) <$> placeInGrid pos loc
      lead <- getLead
      chooseTargetM lead (mapMaybe (`Map.lookup` locationMap) [Pos 0 2, Pos 1 2, Pos 2 0, Pos 2 (-1), Pos 0 (-2), Pos (-1) (-2), Pos (-2) 0, Pos (-2) 1]) \lid -> do
        reveal lid
        moveAllTo attrs lid
      tokens <- allKeys
      lift $ for_ (zip (Map.elems locationMap) tokens) (uncurry placeKey)
    DoStep 2 Setup -> runScenarioSetup CityOfTheElderThings attrs do
      gather Set.CityOfTheElderThings
      gather Set.ElderThings
      gather Set.NamelessHorrors
      gather Set.Penguins
      gather Set.SilenceAndMystery
      gather Set.Tekelili
      gather Set.ChillingCold
      gatherAndSetAside Set.CreaturesInTheIce
      setActDeck [Acts.sprawlingCityV2, Acts.pursuitOfTheUnknownV2]
      setAgendaDeck [Agendas.lurkingHorrors, Agendas.doomFromBelow]
      setUsesGrid
      placeInGrid_ (Pos 0 0) Locations.hiddenTunnelEntranceToTheDepths
      {- FOURMOLU_DISABLE -}
      let
        positions =
          [ Pos (-1) (-1), Pos 0 (-1), Pos 1 (-1)
          , Pos (-2) (-2), Pos (-1) (-2), Pos 0 (-2), Pos 1 (-2), Pos 2 (-2)
          , Pos (-3) (-3), Pos (-2) (-3), Pos 2 (-3), Pos 3 (-3)
          , Pos (-4) (-4), Pos (-3) (-4), Pos 3 (-4), Pos 4 (-4)
          ]
      {- FOURMOLU_ENABLE -}
      locations <- shuffleM cityLandscapes
      locationMap <- Map.fromList <$> for (zip positions locations) \(pos, loc) ->
        (pos,) <$> placeInGrid pos loc
      for_ (Map.lookup (Pos 4 (-4)) locationMap) startAt
      tokens <- allKeys
      lift $ for_ (zip (Map.elems locationMap) tokens) (uncurry placeKey)
    DoStep 3 Setup -> runScenarioSetup CityOfTheElderThings attrs do
      gather Set.CityOfTheElderThings
      gather Set.CreaturesInTheIce
      gather Set.Miasma
      gather Set.Penguins
      gather Set.Tekelili
      gather Set.ChillingCold
      gather Set.LockedDoors
      gatherAndSetAside Set.Shoggoths
      setActDeck [Acts.sprawlingCityV3, Acts.pursuitOfTheUnknownV3]
      setAgendaDeck [Agendas.lurkingHorrors, Agendas.doomFromBelow]
      setUsesGrid
      placeInGrid_ (Pos 0 0) Locations.hiddenTunnelEntranceToTheDepths
      {- FOURMOLU_DISABLE -}
      let
        positions =
          [ Pos (-7) 4, Pos (-6) 4
          , Pos (-7) 3, Pos (-6) 3, Pos (-5) 3, Pos (-4) 3
          , Pos (-5) 2, Pos (-4) 2, Pos (-3) 2, Pos (-2) 2
          , Pos (-4) 1, Pos (-3) 1, Pos (-2) 1, Pos (-1) 1
          , Pos (-2) 0, Pos (-1) 0
          ]
      {- FOURMOLU_ENABLE -}
      locations <- shuffleM cityLandscapes
      locationMap <- Map.fromList <$> for (zip positions locations) \(pos, loc) ->
        (pos,) <$> placeInGrid pos loc
      for_ (Map.lookup (Pos (-7) 4) locationMap) startAt
      tokens <- allKeys
      lift $ for_ (zip (Map.elems locationMap) tokens) (uncurry placeKey)
    _ -> CityOfTheElderThings <$> liftRunMessage msg attrs
