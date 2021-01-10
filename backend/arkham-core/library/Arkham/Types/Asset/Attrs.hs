{-# LANGUAGE TemplateHaskell #-}

module Arkham.Types.Asset.Attrs where

import Arkham.Import

import Arkham.Types.Action
import Arkham.Types.Asset.Class
import Arkham.Types.Asset.Uses
import Arkham.Types.Trait

data Attrs = Attrs
  { assetName :: Text
  , assetId :: AssetId
  , assetCardCode :: CardCode
  , assetCost :: CardCost
  , assetInvestigator :: Maybe InvestigatorId
  , assetLocation :: Maybe LocationId
  , assetEnemy :: Maybe EnemyId
  , assetActions :: [Message]
  , assetSlots :: [SlotType]
  , assetHealth :: Maybe Int
  , assetSanity :: Maybe Int
  , assetHealthDamage :: Int
  , assetSanityDamage :: Int
  , assetTraits :: HashSet Trait
  , assetUses :: Uses
  , assetExhausted :: Bool
  , assetDoom :: Int
  , assetClues :: Int
  , assetHorror :: Maybe Int
  , assetCanLeavePlayByNormalMeans :: Bool
  , assetIsStory :: Bool
  }
  deriving stock (Show, Generic)

makeLensesWith suffixedFields ''Attrs

instance ToJSON Attrs where
  toJSON = genericToJSON $ aesonOptions $ Just "asset"
  toEncoding = genericToEncoding $ aesonOptions $ Just "asset"

instance FromJSON Attrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "asset"

instance IsCard Attrs where
  getCardId = CardId . unAssetId . assetId
  getCardCode = assetCardCode
  getTraits = assetTraits
  getKeywords = mempty

baseAttrs :: AssetId -> CardCode -> Attrs
baseAttrs aid cardCode =
  let
    MkPlayerCard {..} =
      fromJustNote
          ("missing player card" <> unpack (unCardCode cardCode))
          (lookup cardCode allPlayerCards)
        $ CardId (unAssetId aid)
  in
    Attrs
      { assetName = pcName
      , assetId = aid
      , assetCardCode = cardCode
      , assetCost = pcCost
      , assetInvestigator = Nothing
      , assetLocation = Nothing
      , assetEnemy = Nothing
      , assetActions = mempty
      , assetSlots = mempty
      , assetHealth = Nothing
      , assetSanity = Nothing
      , assetHealthDamage = 0
      , assetSanityDamage = 0
      , assetTraits = pcTraits
      , assetUses = NoUses
      , assetExhausted = False
      , assetDoom = 0
      , assetClues = 0
      , assetHorror = Nothing
      , assetCanLeavePlayByNormalMeans = True
      , assetIsStory = False
      }

instance Entity Attrs where
  type EntityId Attrs = AssetId
  toId = assetId
  toSource = AssetSource . toId
  toTarget = AssetTarget . toId
  isSource Attrs { assetId } (AssetSource aid) = assetId == aid
  isSource _ _ = False
  isTarget Attrs {..} = \case
    AssetTarget aid -> aid == assetId
    CardCodeTarget cardCode -> assetCardCode == cardCode
    CardIdTarget cardId -> unCardId cardId == unAssetId assetId
    _ -> False

ownedBy :: Attrs -> InvestigatorId -> Bool
ownedBy Attrs {..} = (== assetInvestigator) . Just

assetAction
  :: InvestigatorId -> Attrs -> Int -> Maybe Action -> Cost -> Message
assetAction iid attrs idx mAction cost =
  ActivateCardAbilityAction iid
    $ mkAbility (toSource attrs) idx (ActionAbility mAction cost)

getInvestigator :: HasCallStack => Attrs -> InvestigatorId
getInvestigator = fromJustNote "asset must be owned" . view investigatorL

defeated :: Attrs -> Bool
defeated Attrs {..} =
  maybe False (assetHealthDamage >=) assetHealth
    || maybe False (assetSanityDamage >=) assetSanity

instance HasActions env Attrs where
  getActions _ _ _ = pure []

instance IsAsset Attrs where
  slotsOf = assetSlots
  useTypeOf = useType . assetUses
  isHealthDamageable a = case assetHealth a of
    Nothing -> False
    Just n -> n > assetHealthDamage a
  isSanityDamageable a = case assetSanity a of
    Nothing -> False
    Just n -> n > assetSanityDamage a
  isStory = assetIsStory

instance (HasQueue env, HasModifiersFor env ()) => RunMessage env Attrs where
  runMessage msg a@Attrs {..} = case msg of
    ReadyExhausted -> case assetInvestigator of
      Just iid -> do
        modifiers <-
          map modifierType
            <$> getModifiersFor (toSource a) (InvestigatorTarget iid) ()
        if ControlledAssetsCannotReady `elem` modifiers
          then pure a
          else pure $ a & exhaustedL .~ False
      Nothing -> pure $ a & exhaustedL .~ False
    RemoveAllDoom -> pure $ a & doomL .~ 0
    PlaceClues target n | isTarget a target -> pure $ a & cluesL +~ n
    RemoveClues target n | isTarget a target ->
      pure $ a & cluesL %~ max 0 . subtract n
    CheckDefeated ->
      a <$ when (defeated a) (unshiftMessages $ resolve $ AssetDefeated assetId)
    AssetDefeated aid | aid == assetId ->
      a <$ unshiftMessage (Discard $ toTarget a)
    AssetDamage aid _ health sanity | aid == assetId ->
      pure $ a & healthDamageL +~ health & sanityDamageL +~ sanity
    When (InvestigatorResigned iid) | assetInvestigator == Just iid ->
      a <$ unshiftMessage (ResignWith (AssetTarget assetId))
    InvestigatorEliminated iid | assetInvestigator == Just iid ->
      a <$ unshiftMessage (Discard (AssetTarget assetId))
    AddUses target useType' n | a `isTarget` target -> case assetUses of
      Uses useType'' m | useType' == useType'' ->
        pure $ a & usesL .~ Uses useType' (n + m)
      _ -> error "Trying to add the wrong use type"
    SpendUses target useType' n | isTarget a target -> case assetUses of
      Uses useType'' m | useType' == useType'' ->
        pure $ a & usesL .~ Uses useType' (max 0 (m - n))
      _ -> error "Trying to use the wrong use type"
    AttachAsset aid target | aid == assetId -> case target of
      LocationTarget lid -> pure $ a & locationL ?~ lid
      EnemyTarget eid -> pure $ a & enemyL ?~ eid
      _ -> error "Cannot attach asset to that type"
    RemoveFromGame target | a `isTarget` target ->
      a <$ unshiftMessage (RemovedFromPlay $ toSource a)
    Discard target | a `isTarget` target -> a <$ unshiftMessages
      [RemovedFromPlay $ toSource a, Discarded target (toCard a)]
    InvestigatorPlayAsset iid aid _ _ | aid == assetId -> do
      unshiftMessage $ CheckWindow iid [WhenEnterPlay $ toTarget a]
      pure $ a & investigatorL ?~ iid
    TakeControlOfAsset iid aid | aid == assetId ->
      pure $ a & investigatorL ?~ iid
    Exhaust target | a `isTarget` target -> pure $ a & exhaustedL .~ True
    Ready target | a `isTarget` target -> case assetInvestigator of
      Just iid -> do
        modifiers <-
          map modifierType
            <$> getModifiersFor (toSource a) (InvestigatorTarget iid) ()
        if ControlledAssetsCannotReady `elem` modifiers
          then pure a
          else pure $ a & exhaustedL .~ False
      Nothing -> pure $ a & exhaustedL .~ False
    Blanked msg' -> runMessage msg' a
    _ -> pure a
