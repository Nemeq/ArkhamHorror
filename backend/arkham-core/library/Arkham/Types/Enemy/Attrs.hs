{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Enemy.Attrs where

import Arkham.Import

import qualified Arkham.Types.Action as Action
import Arkham.Types.Enemy.Runner
import Arkham.Types.Game.Helpers
import Arkham.Types.Keyword (Keyword)
import qualified Arkham.Types.Keyword as Keyword
import Arkham.Types.Trait

data Attrs = Attrs
  { enemyName :: Text
  , enemyId :: EnemyId
  , enemyCardCode :: CardCode
  , enemyEngagedInvestigators :: HashSet InvestigatorId
  , enemyLocation :: LocationId
  , enemyFight :: Int
  , enemyHealth :: GameValue Int
  , enemyEvade :: Int
  , enemyDamage :: Int
  , enemyHealthDamage :: Int
  , enemySanityDamage :: Int
  , enemyTraits :: HashSet Trait
  , enemyTreacheries :: HashSet TreacheryId
  , enemyAssets :: HashSet AssetId
  , enemyVictory :: Maybe Int
  , enemyKeywords :: HashSet Keyword
  , enemyPrey :: Prey
  , enemyModifiers :: HashMap Source [Modifier]
  , enemyExhausted :: Bool
  , enemyDoom :: Int
  , enemyClues :: Int
  , enemyUnique :: Bool
  }
  deriving stock (Show, Generic)

instance ToJSON Attrs where
  toJSON = genericToJSON $ aesonOptions $ Just "enemy"
  toEncoding = genericToEncoding $ aesonOptions $ Just "enemy"

instance FromJSON Attrs where
  parseJSON = genericParseJSON $ aesonOptions $ Just "enemy"

doom :: Lens' Attrs Int
doom = lens enemyDoom $ \m x -> m { enemyDoom = x }

clues :: Lens' Attrs Int
clues = lens enemyClues $ \m x -> m { enemyClues = x }

prey :: Lens' Attrs Prey
prey = lens enemyPrey $ \m x -> m { enemyPrey = x }

engagedInvestigators :: Lens' Attrs (HashSet InvestigatorId)
engagedInvestigators =
  lens enemyEngagedInvestigators $ \m x -> m { enemyEngagedInvestigators = x }

location :: Lens' Attrs LocationId
location = lens enemyLocation $ \m x -> m { enemyLocation = x }

damage :: Lens' Attrs Int
damage = lens enemyDamage $ \m x -> m { enemyDamage = x }

health :: Lens' Attrs (GameValue Int)
health = lens enemyHealth $ \m x -> m { enemyHealth = x }

healthDamage :: Lens' Attrs Int
healthDamage = lens enemyHealthDamage $ \m x -> m { enemyHealthDamage = x }

sanityDamage :: Lens' Attrs Int
sanityDamage = lens enemySanityDamage $ \m x -> m { enemySanityDamage = x }

fight :: Lens' Attrs Int
fight = lens enemyFight $ \m x -> m { enemyFight = x }

evade :: Lens' Attrs Int
evade = lens enemyEvade $ \m x -> m { enemyEvade = x }

unique :: Lens' Attrs Bool
unique = lens enemyUnique $ \m x -> m { enemyUnique = x }

keywords :: Lens' Attrs (HashSet Keyword)
keywords = lens enemyKeywords $ \m x -> m { enemyKeywords = x }

modifiers :: Lens' Attrs (HashMap Source [Modifier])
modifiers = lens enemyModifiers $ \m x -> m { enemyModifiers = x }

treacheries :: Lens' Attrs (HashSet TreacheryId)
treacheries = lens enemyTreacheries $ \m x -> m { enemyTreacheries = x }

assets :: Lens' Attrs (HashSet AssetId)
assets = lens enemyAssets $ \m x -> m { enemyAssets = x }

exhausted :: Lens' Attrs Bool
exhausted = lens enemyExhausted $ \m x -> m { enemyExhausted = x }

baseAttrs :: EnemyId -> CardCode -> (Attrs -> Attrs) -> Attrs
baseAttrs eid cardCode f =
  let
    MkEncounterCard {..} =
      fromJustNote
          ("missing enemy encounter card: " <> show cardCode)
          (lookup cardCode allEncounterCards)
        $ CardId (unEnemyId eid)
  in
    f $ Attrs
      { enemyName = ecName
      , enemyId = eid
      , enemyCardCode = cardCode
      , enemyEngagedInvestigators = mempty
      , enemyLocation = "00000" -- no known location
      , enemyFight = 1
      , enemyHealth = Static 1
      , enemyEvade = 1
      , enemyDamage = 0
      , enemyHealthDamage = 0
      , enemySanityDamage = 0
      , enemyTraits = ecTraits
      , enemyTreacheries = mempty
      , enemyAssets = mempty
      , enemyKeywords = setFromList ecKeywords
      , enemyPrey = AnyPrey
      , enemyModifiers = mempty
      , enemyExhausted = False
      , enemyDoom = 0
      , enemyClues = 0
      , enemyVictory = ecVictoryPoints
      , enemyUnique = False
      }

weaknessBaseAttrs :: EnemyId -> CardCode -> Attrs
weaknessBaseAttrs eid cardCode =
  let
    MkPlayerCard {..} =
      fromJustNote
          ("missing player enemy weakness card: " <> show cardCode)
          (lookup cardCode allPlayerCards)
        $ CardId (unEnemyId eid)
  in
    Attrs
      { enemyName = pcName
      , enemyId = eid
      , enemyCardCode = cardCode
      , enemyEngagedInvestigators = mempty
      , enemyLocation = "00000" -- no known location
      , enemyFight = 1
      , enemyHealth = Static 1
      , enemyEvade = 1
      , enemyDamage = 0
      , enemyHealthDamage = 0
      , enemySanityDamage = 0
      , enemyTraits = pcTraits
      , enemyTreacheries = mempty
      , enemyAssets = mempty
      , enemyVictory = pcVictoryPoints
      , enemyKeywords = setFromList pcKeywords
      , enemyPrey = AnyPrey
      , enemyModifiers = mempty
      , enemyExhausted = False
      , enemyClues = 0
      , enemyDoom = 0
      , enemyUnique = False
      }

spawnAtEmptyLocation
  :: (MonadIO m, HasSet EmptyLocationId () env, MonadReader env m, HasQueue env)
  => InvestigatorId
  -> EnemyId
  -> m ()
spawnAtEmptyLocation iid eid = do
  emptyLocations <- asks $ map unEmptyLocationId . setToList . getSet ()
  case emptyLocations of
    [] -> unshiftMessage (Discard (EnemyTarget eid))
    [lid] -> unshiftMessage (EnemySpawn (Just iid) lid eid)
    lids -> unshiftMessage
      (Ask iid $ ChooseOne [ EnemySpawn (Just iid) lid eid | lid <- lids ])

spawnAt
  :: (MonadIO m, MonadReader env m, HasQueue env)
  => Maybe InvestigatorId
  -> EnemyId
  -> LocationName
  -> m ()
spawnAt miid eid locationName =
  unshiftMessages $ resolve (EnemySpawnAtLocationNamed miid locationName eid)

spawnAtOneOf
  :: (MonadIO m, HasSet LocationId () env, MonadReader env m, HasQueue env)
  => InvestigatorId
  -> EnemyId
  -> [LocationId]
  -> m ()
spawnAtOneOf iid eid targetLids = do
  locations' <- asks (getSet ())
  case setToList (setFromList targetLids `intersection` locations') of
    [] -> unshiftMessage (Discard (EnemyTarget eid))
    [lid] -> unshiftMessage (EnemySpawn (Just iid) lid eid)
    lids -> unshiftMessage
      (Ask iid $ ChooseOne [ EnemySpawn (Just iid) lid eid | lid <- lids ])

modifiedEnemyFight
  :: ( MonadReader env m
     , MonadIO m
     , HasModifiersFor env env
     , HasSource ForSkillTest env
     )
  => Attrs
  -> m Int
modifiedEnemyFight Attrs {..} = do
  msource <- asks $ getSource ForSkillTest
  let source = fromMaybe (EnemySource enemyId) msource
  modifiers' <- getModifiersFor source (EnemyTarget enemyId) =<< ask
  pure $ foldr applyModifier enemyFight modifiers'
 where
  applyModifier (EnemyFight m) n = max 0 (n + m)
  applyModifier _ n = n

modifiedEnemyEvade
  :: ( MonadReader env m
     , MonadIO m
     , HasModifiersFor env env
     , HasSource ForSkillTest env
     )
  => Attrs
  -> m Int
modifiedEnemyEvade Attrs {..} = do
  msource <- asks $ getSource ForSkillTest
  let source = fromMaybe (EnemySource enemyId) msource
  modifiers' <- getModifiersFor source (EnemyTarget enemyId) =<< ask
  pure $ foldr applyModifier enemyEvade modifiers'
 where
  applyModifier (EnemyEvade m) n = max 0 (n + m)
  applyModifier _ n = n

modifiedDamageAmount :: Attrs -> Int -> Int
modifiedDamageAmount attrs baseAmount = foldr
  applyModifier
  baseAmount
  (concat . toList $ enemyModifiers attrs)
 where
  applyModifier (DamageTaken m) n = max 0 (n + m)
  applyModifier _ n = n

canEnterLocation
  :: (EnemyRunner env, MonadReader env m, MonadIO m)
  => EnemyId
  -> LocationId
  -> m Bool
canEnterLocation eid lid = do
  traits <- asks (getSet eid)
  modifiers' <- getModifiers (EnemySource eid) lid
  pure $ not $ flip any modifiers' $ \case
    CannotBeEnteredByNonElite{} -> Elite `notMember` traits
    _ -> False

instance HasId EnemyId () Attrs where
  getId _ Attrs {..} = enemyId

instance IsEnemy Attrs where
  isAloof Attrs {..} = Keyword.Aloof `elem` enemyKeywords

instance ActionRunner env => HasActions env Attrs where
  getActions iid NonFast Attrs {..} = do
    canFight <- getCanFight enemyId iid
    canEngage <- getCanEngage enemyId iid
    canEvade <- getCanEvade enemyId iid
    pure
      $ fightEnemyActions canFight
      <> engageEnemyActions canEngage
      <> evadeEnemyActions canEvade
   where
    fightEnemyActions canFight =
      [ FightEnemy
          iid
          enemyId
          (InvestigatorSource iid)
          SkillCombat
          []
          mempty
          True
      | canFight
      ]
    engageEnemyActions canEngage = [ EngageEnemy iid enemyId True | canEngage ]
    evadeEnemyActions canEvade =
      [ EvadeEnemy
          iid
          enemyId
          (InvestigatorSource iid)
          SkillAgility
          mempty
          mempty
          mempty
          True
      | canEvade
      ]
  getActions _ _ _ = pure []

toSource :: Attrs -> Source
toSource Attrs { enemyId } = EnemySource enemyId

isTarget :: Attrs -> Target -> Bool
isTarget Attrs { enemyId } (EnemyTarget eid) = enemyId == eid
isTarget _ _ = False

getModifiedHealth
  :: ( MonadIO m
     , MonadReader env m
     , HasModifiersFor env env
     , HasCount PlayerCount () env
     )
  => Attrs
  -> m Int
getModifiedHealth Attrs {..} = do
  playerCount <- getPlayerCount
  modifiers' <-
    getModifiersFor (EnemySource enemyId) (EnemyTarget enemyId) =<< ask
  pure $ foldr applyModifier (fromGameValue enemyHealth playerCount) modifiers'
 where
  applyModifier (HealthModifier m) n = max 0 (n + m)
  applyModifier _ n = n

instance EnemyRunner env => RunMessage env Attrs where
  runMessage msg a@Attrs {..} = case msg of
    EnemySpawnEngagedWithPrey eid | eid == enemyId -> do
      preyIds <- asks $ map unPreyId . setToList . getSet enemyPrey
      preyIdsWithLocation <- for preyIds
        $ \iid -> (iid, ) <$> asks (getId @LocationId iid)
      leadInvestigatorId <- getLeadInvestigatorId
      a <$ case preyIdsWithLocation of
        [] -> pure ()
        [(iid, lid)] -> unshiftMessages
          [EnemySpawnedAt lid eid, EnemyEngageInvestigator eid iid]
        iids -> unshiftMessage
          (Ask leadInvestigatorId $ ChooseOne
            [ Run [EnemySpawnedAt lid eid, EnemyEngageInvestigator eid iid]
            | (iid, lid) <- iids
            ]
          )
    EnemySpawn _ lid eid | eid == enemyId -> do
      locations' <- asks (getSet ())
      if lid `notElem` locations'
        then a <$ unshiftMessage (Discard (EnemyTarget eid))
        else do
          when
              (Keyword.Aloof
              `notElem` enemyKeywords
              && Keyword.Massive
              `notElem` enemyKeywords
              )
            $ do
                preyIds <- asks $ map unPreyId . setToList . getSet
                  (enemyPrey, lid)
                investigatorIds <- if null preyIds
                  then asks $ setToList . getSet @InvestigatorId lid
                  else pure []
                leadInvestigatorId <- getLeadInvestigatorId
                case preyIds <> investigatorIds of
                  [] -> pure ()
                  [iid] -> unshiftMessage (EnemyEngageInvestigator eid iid)
                  iids -> unshiftMessage
                    (Ask leadInvestigatorId $ ChooseOne
                      [ EnemyEngageInvestigator eid iid | iid <- iids ]
                    )
          when (Keyword.Massive `elem` enemyKeywords) $ do
            investigatorIds <- getInvestigatorIds
            unshiftMessages
              [ EnemyEngageInvestigator eid iid | iid <- investigatorIds ]
          pure $ a & location .~ lid
    EnemySpawnedAt lid eid | eid == enemyId -> pure $ a & location .~ lid
    ReadyExhausted -> do
      miid <- asks $ headMay . setToList . getSet enemyLocation
      case miid of
        Just iid ->
          when
              (Keyword.Aloof
              `notElem` enemyKeywords
              && (null enemyEngagedInvestigators
                 || Keyword.Massive
                 `elem` enemyKeywords
                 )
              )
            $ unshiftMessage (EnemyEngageInvestigator enemyId iid)
        Nothing -> pure ()
      pure $ a & exhausted .~ False
    MoveUntil lid target | isTarget a target -> if lid == enemyLocation
      then pure a
      else do
        leadInvestigatorId <- getLeadInvestigatorId
        adjacentLocationIds <-
          asks $ map unConnectedLocationId . setToList . getSet enemyLocation
        closestLocationIds <-
          asks $ map unClosestLocationId . setToList . getSet
            (enemyLocation, lid)
        if lid `elem` adjacentLocationIds
          then a <$ unshiftMessage
            (chooseOne leadInvestigatorId [EnemyMove enemyId enemyLocation lid])
          else a <$ unshiftMessages
            [ chooseOne
              leadInvestigatorId
              [ EnemyMove enemyId enemyLocation lid'
              | lid' <- closestLocationIds
              ]
            , MoveUntil lid target
            ]
    EnemyMove eid _ lid | eid == enemyId -> do
      willMove <- canEnterLocation eid lid
      if willMove
        then pure $ a & location .~ lid & engagedInvestigators .~ mempty
        else pure a
    HuntersMove
      | Keyword.Hunter
        `elem` enemyKeywords
        && null enemyEngagedInvestigators
        && not enemyExhausted
      -> do
        closestLocationIds <-
          asks $ map unClosestLocationId . setToList . getSet
            (enemyLocation, enemyPrey)
        leadInvestigatorId <- getLeadInvestigatorId
        case closestLocationIds of
          [] -> pure a
          [lid] -> a <$ unshiftMessage (EnemyMove enemyId enemyLocation lid)
          ls -> a <$ unshiftMessage
            (Ask leadInvestigatorId $ ChooseOne $ map
              (EnemyMove enemyId enemyLocation)
              ls
            )
    EnemiesAttack
      | not (null enemyEngagedInvestigators) && not enemyExhausted -> do
        unshiftMessages $ map (`EnemyWillAttack` enemyId) $ setToList
          enemyEngagedInvestigators
        pure a
    AttackEnemy iid eid source skillType tempModifiers tokenResponses
      | eid == enemyId -> do
        let
          onFailure = if Keyword.Retaliate `elem` enemyKeywords
            then [EnemyAttack iid eid, FailedAttackEnemy iid eid]
            else [FailedAttackEnemy iid eid]
        enemyFight' <- modifiedEnemyFight a
        a <$ unshiftMessage
          (BeginSkillTest
            iid
            source
            (EnemyTarget eid)
            (Just Action.Fight)
            skillType
            enemyFight'
            [SuccessfulAttackEnemy iid eid, InvestigatorDamageEnemy iid eid]
            onFailure
            tempModifiers
            tokenResponses
          )
    EnemyEvaded iid eid | eid == enemyId ->
      pure $ a & engagedInvestigators %~ deleteSet iid & exhausted .~ True
    TryEvadeEnemy iid eid source skillType onSuccess onFailure skillTestModifiers tokenResponses
      | eid == enemyId
      -> do
        let
          onFailure' = if Keyword.Alert `elem` enemyKeywords
            then EnemyAttack iid eid : onFailure
            else onFailure
          onSuccess' = flip map onSuccess $ \case
            Damage EnemyJustEvadedTarget source' n ->
              EnemyDamage eid iid source' n
            msg' -> msg'
        enemyEvade' <- modifiedEnemyEvade a
        a <$ unshiftMessage
          (BeginSkillTest
            iid
            source
            (EnemyTarget eid)
            (Just Action.Evade)
            skillType
            enemyEvade'
            (EnemyEvaded iid eid : onSuccess')
            onFailure'
            skillTestModifiers
            tokenResponses
          )
    PerformEnemyAttack iid eid | eid == enemyId -> a <$ unshiftMessages
      [ InvestigatorAssignDamage
        iid
        (EnemySource enemyId)
        enemyHealthDamage
        enemySanityDamage
      , After (EnemyAttack iid enemyId)
      ]
    EnemyDamage eid iid source amount | eid == enemyId -> do
      let amount' = modifiedDamageAmount a amount
      modifiedHealth <- getModifiedHealth a
      (a & damage +~ amount') <$ when
        (a ^. damage + amount' >= modifiedHealth)
        (unshiftMessage (EnemyDefeated eid iid enemyCardCode source))
    EnemyDefeated eid _ _ _ | eid == enemyId -> do
      unshiftMessages
        [ Discard (TreacheryTarget tid) | tid <- setToList enemyTreacheries ]
      unshiftMessages
        [ Discard (AssetTarget aid) | aid <- setToList enemyAssets ]
      pure a
    AddModifiers (EnemyTarget eid) source modifiers' | eid == enemyId -> do
      when (Blank `elem` modifiers')
        $ unshiftMessage (RemoveAllModifiersFrom (EnemySource eid))
      pure $ a & modifiers %~ insertWith (<>) source modifiers'
    RemoveAllModifiersOnTargetFrom (EnemyTarget eid) source | eid == enemyId ->
      do
        when (Blank `elem` fromMaybe [] (lookup source enemyModifiers))
          $ unshiftMessage (ApplyModifiers (EnemyTarget enemyId))
        pure $ a & modifiers %~ deleteMap source
    RemoveAllModifiersFrom source -> runMessage
      (RemoveAllModifiersOnTargetFrom (EnemyTarget enemyId) source)
      a
    EnemyEngageInvestigator eid iid | eid == enemyId ->
      pure $ a & engagedInvestigators %~ insertSet iid
    EngageEnemy iid eid False | eid == enemyId ->
      pure $ a & engagedInvestigators .~ singleton iid
    MoveTo iid lid | iid `elem` enemyEngagedInvestigators ->
      if Keyword.Massive `elem` enemyKeywords
        then pure a
        else do
          willMove <- canEnterLocation enemyId lid
          if willMove
            then a <$ unshiftMessage (EnemyMove enemyId enemyLocation lid)
            else a <$ unshiftMessage (DisengageEnemy iid enemyId)
    AfterEnterLocation iid lid | lid == enemyLocation -> do
      when
          (Keyword.Aloof
          `notElem` enemyKeywords
          && (null enemyEngagedInvestigators
             || Keyword.Massive
             `elem` enemyKeywords
             )
          )
        $ unshiftMessage (EnemyEngageInvestigator enemyId iid)
      pure a
    CheckAttackOfOpportunity iid isFast
      | not isFast && iid `elem` enemyEngagedInvestigators && not enemyExhausted
      -> a <$ unshiftMessage (EnemyWillAttack iid enemyId)
    InvestigatorDrawEnemy iid lid eid | eid == enemyId -> do
      unshiftMessage (EnemySpawn (Just iid) lid eid)
      pure $ a & location .~ lid
    InvestigatorEliminated iid ->
      pure $ a & engagedInvestigators %~ deleteSet iid
    UnengageNonMatching iid traits
      | iid `elem` enemyEngagedInvestigators && null
        (setFromList traits `intersection` enemyTraits)
      -> a <$ unshiftMessage (DisengageEnemy iid enemyId)
    DisengageEnemy iid eid | eid == enemyId -> do
      pure $ a & engagedInvestigators %~ deleteSet iid
    EnemySetBearer eid bid | eid == enemyId -> pure $ a & prey .~ Bearer bid
    AdvanceAgenda{} -> pure $ a & doom .~ 0
    PlaceDoom (CardIdTarget cid) amount | unCardId cid == unEnemyId enemyId ->
      pure $ a & doom +~ amount
    PlaceDoom (EnemyTarget eid) amount | eid == enemyId ->
      pure $ a & doom +~ amount
    AttachTreachery tid (EnemyTarget eid) | eid == enemyId ->
      pure $ a & treacheries %~ insertSet tid
    AttachAsset aid (EnemyTarget eid) | eid == enemyId ->
      pure $ a & assets %~ insertSet aid
    AttachAsset aid _ -> pure $ a & assets %~ deleteSet aid
    RemoveKeywords (EnemyTarget eid) keywordsToRemove | eid == enemyId ->
      pure $ a & keywords %~ (`difference` setFromList keywordsToRemove)
    Blanked msg' -> runMessage msg' a
    _ -> pure a
