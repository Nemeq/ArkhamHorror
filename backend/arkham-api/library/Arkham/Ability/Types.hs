{-# LANGUAGE TemplateHaskell #-}

module Arkham.Ability.Types where

import Arkham.Prelude

import Arkham.Ability.Limit
import Arkham.Ability.Type
import Arkham.Card.CardCode
import Arkham.Card.EncounterCard
import Arkham.Cost
import Arkham.Criteria (Criterion)
import Arkham.Json
import Arkham.Matcher
import Arkham.SkillType
import Arkham.Source
import Arkham.Target
import Data.Aeson.TH
import GHC.Records

data AdditionalCostDelay = DelayAdditionalCosts | DelayAdditionalCostsWhen Criterion
  deriving stock (Show, Eq, Ord, Data)

data Ability = Ability
  { abilitySource :: Source
  , abilityCardCode :: CardCode
  , abilityIndex :: Int
  , abilityType :: AbilityType
  , abilityLimit :: AbilityLimit
  , abilityWindow :: WindowMatcher
  , abilityMetadata :: Maybe AbilityMetadata
  , abilityCriteria :: Criterion
  , abilityDoesNotProvokeAttacksOfOpportunity :: Bool
  , abilityTooltip :: Maybe Text
  , abilityCanBeCancelled :: Bool
  , abilityDisplayAsAction :: Bool
  , abilityDelayAdditionalCosts :: Maybe AdditionalCostDelay
  , abilityBasic :: Bool
  , abilityAdditionalCosts :: [Cost]
  , abilityRequestor :: Source
  , abilityTriggersSkillTest :: Bool
  , abilityWantsSkillTest :: Maybe SkillTestMatcher
  }
  deriving stock (Show, Ord, Data)

skillTestAbility :: Ability -> Ability
skillTestAbility ab = ab {abilityTriggersSkillTest = True}

notSkillTestAbility :: Ability -> Ability
notSkillTestAbility ab = ab {abilityTriggersSkillTest = False}

setRequestor :: Sourceable source => source -> Ability -> Ability
setRequestor source ab = ab {abilityRequestor = toSource source}

instance HasCost Ability where
  overCost f ab = ab {Arkham.Ability.Types.abilityType = overCost f (abilityType ab)}

instance HasField "wantsSkillTest" Ability (Maybe SkillTestMatcher) where
  getField = abilityWantsSkillTest

instance HasField "criteria" Ability Criterion where
  getField = abilityCriteria

instance HasField "kind" Ability AbilityType where
  getField = abilityType

instance HasField "requestor" Ability Source where
  getField = abilityRequestor

instance HasField "source" Ability Source where
  getField = abilitySource

instance HasField "cardCode" Ability CardCode where
  getField = abilityCardCode

instance HasField "index" Ability Int where
  getField = abilityIndex

instance HasField "ref" Ability AbilityRef where
  getField = abilityToRef

data AbilityRef = AbilityRef Source Int
  deriving stock (Show, Eq, Generic, Data)
  deriving anyclass (ToJSON, FromJSON)

abilityToRef :: Ability -> AbilityRef
abilityToRef a = AbilityRef a.source a.index

data AbilityMetadata
  = IntMetadata Int
  | TargetMetadata Target
  | SourceMetadata Source
  | EncounterCardMetadata EncounterCard
  | SkillChoiceMetadata SkillType
  | NoAbilityMetadata
  | InvestigateTargets LocationMatcher
  | CardCodeMetadata CardCode
  deriving stock (Eq, Show, Ord, Data)

instance Eq Ability where
  a == b = (abilitySource a == abilitySource b) && (abilityIndex a == abilityIndex b)

instance Sourceable Ability where
  toSource a = AbilitySource (abilitySource a) (abilityIndex a)

abilityLimitL :: Lens' Ability AbilityLimit
abilityLimitL = lens abilityLimit $ \m x -> m {abilityLimit = x}

abilityTypeL :: Lens' Ability AbilityType
abilityTypeL = lens abilityType $ \m x -> m {Arkham.Ability.Types.abilityType = x}

abilityMetadataL :: Lens' Ability (Maybe AbilityMetadata)
abilityMetadataL = lens abilityMetadata $ \m x -> m {abilityMetadata = x}

abilityTooltipL :: Lens' Ability (Maybe Text)
abilityTooltipL = lens abilityTooltip $ \m x -> m {abilityTooltip = x}

abilityCriteriaL :: Lens' Ability Criterion
abilityCriteriaL = lens abilityCriteria $ \m x -> m {abilityCriteria = x}

abilityWantsSkillTestL :: Lens' Ability (Maybe SkillTestMatcher)
abilityWantsSkillTestL = lens abilityWantsSkillTest $ \m x -> m {abilityWantsSkillTest = x}

abilityDoesNotProvokeAttacksOfOpportunityL :: Lens' Ability Bool
abilityDoesNotProvokeAttacksOfOpportunityL =
  lens abilityDoesNotProvokeAttacksOfOpportunity
    $ \m x -> m {abilityDoesNotProvokeAttacksOfOpportunity = x}

abilityDisplayAsActionL :: Lens' Ability Bool
abilityDisplayAsActionL = lens abilityDisplayAsAction $ \m x -> m {abilityDisplayAsAction = x}

abilityDelayAdditionalCostsL :: Lens' Ability (Maybe AdditionalCostDelay)
abilityDelayAdditionalCostsL = lens abilityDelayAdditionalCosts $ \m x -> m {abilityDelayAdditionalCosts = x}

delayAdditionalCosts :: Ability -> Ability
delayAdditionalCosts = abilityDelayAdditionalCostsL ?~ DelayAdditionalCosts

delayAdditionalCostsWhen :: Criterion -> Ability -> Ability
delayAdditionalCostsWhen c = abilityDelayAdditionalCostsL ?~ DelayAdditionalCostsWhen c

$(deriveJSON defaultOptions ''AdditionalCostDelay)
$(deriveJSON defaultOptions ''AbilityMetadata)
$(deriveToJSON (aesonOptions $ Just "ability") ''Ability)

instance FromJSON Ability where
  parseJSON = withObject "Ability" $ \o -> do
    abilitySource <- o .: "source"
    abilityCardCode <- o .: "cardCode"
    abilityIndex <- o .: "index"
    abilityType <- o .: "type"
    abilityLimit <- o .: "limit"
    abilityWindow <- o .: "window"
    abilityMetadata <- o .:? "metadata"
    abilityCriteria <- o .: "criteria"
    abilityDoesNotProvokeAttacksOfOpportunity <- o .: "doesNotProvokeAttacksOfOpportunity"
    abilityTooltip <- o .:? "tooltip"
    abilityCanBeCancelled <- o .: "canBeCancelled"
    abilityDisplayAsAction <- o .: "displayAsAction"
    abilityDelayAdditionalCosts <-
      (o .: "delayAdditionalCosts" <&> \x -> if x then Just DelayAdditionalCosts else Nothing)
        <|> o
        .: "delayAdditionalCosts"
    abilityBasic <- o .: "basic"
    abilityAdditionalCosts <- o .: "additionalCosts"
    abilityRequestor <- o .:? "requestor" .!= abilitySource
    abilityTriggersSkillTest <- o .:? "triggersSkillTest" .!= False
    abilityWantsSkillTest <- o .:? "wantsSkillTest" .!= Nothing

    pure Ability {..}

newtype DifferentAbility = DifferentAbility Ability
  deriving newtype (Show, ToJSON, FromJSON)

instance Eq DifferentAbility where
  (DifferentAbility a) == (DifferentAbility b) =
    case abilityIndex a of
      100 -> abilityIndex b == 100 && sameSource
      101 -> abilityIndex b == 101 && sameSource
      102 -> abilityIndex b == 102 && sameSource
      _ -> (abilityCardCode a == abilityCardCode b) && (abilityIndex a == abilityIndex b)
   where
    sameSource = case abilitySource a of
      EnemySource _ -> case abilitySource b of
        EnemySource _ -> True
        _ -> False
      LocationSource _ -> case abilitySource b of
        LocationSource _ -> True
        _ -> False
      InvestigatorSource _ -> case abilitySource b of
        InvestigatorSource _ -> True
        _ -> False
      _ -> error $ "Unhandled samesource in DifferentAbility: " <> show (abilitySource a, abilitySource b)
