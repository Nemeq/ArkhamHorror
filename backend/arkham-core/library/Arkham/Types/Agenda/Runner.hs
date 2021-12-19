module Arkham.Types.Agenda.Runner where

import Arkham.Prelude

import Arkham.Types.ActId
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Direction
import Arkham.Types.Id
import Arkham.Types.Matcher
import Arkham.Types.Name
import Arkham.Types.Query
import Arkham.Types.Scenario.Deck
import Arkham.Types.Trait

type AgendaRunner env =
  ( HasQueue env
  , HasRecord env ()
  , Query AssetMatcher env
  , Query EnemyMatcher env
  , Query ExtendedCardMatcher env
  , Query InvestigatorMatcher env
  , Query LocationMatcher env
  , Query ActMatcher env
  , HasCount ClueCount env InvestigatorId
  , HasCount ClueCount env LocationId
  , HasCount DiscardCount env InvestigatorId
  , HasCount DoomCount env ()
  , HasCount EnemyCount env (LocationId, [Trait])
  , HasCount EnemyCount env (LocationMatcher, [Trait])
  , HasCount PlayerCount env ()
  , HasCount ScenarioDeckCount env ScenarioDeckKey
  , HasCount SetAsideCount env CardCode
  , HasId (Maybe LocationId) env LocationMatcher
  , HasId (Maybe LocationId) env (Direction, LocationId)
  , HasId (Maybe StoryTreacheryId) env CardCode
  , HasId CardCode env EnemyId
  , HasId LeadInvestigatorId env ()
  , HasId LocationId env EnemyId
  , HasId LocationId env InvestigatorId
  , HasList LocationName env ()
  , HasList (InvestigatorId, Distance) env EnemyMatcher
  , HasList (LocationId, Distance) env InvestigatorId
  , HasSet ActId env ()
  , HasSet ClosestPathLocationId env (LocationId, LocationId)
  , HasSet ClosestPathLocationId env (LocationId, LocationMatcher)
  , HasSet CompletedScenarioId env ()
  , HasSet EnemyId env ()
  , HasSet EnemyId env ([Trait], LocationId)
  , HasSet EnemyId env LocationId
  , HasSet EnemyId env EnemyMatcher
  , HasSet EnemyId env LocationMatcher
  , HasSet EnemyId env Trait
  , HasSet InScenarioInvestigatorId env ()
  , HasSet InvestigatorId env ()
  , HasSet InvestigatorId env EnemyId
  , HasSet InvestigatorId env LocationMatcher
  , HasSet InvestigatorId env LocationId
  , HasSet LocationId env ()
  , HasSet LocationId env [Trait]
  , HasSet Trait env EnemyId
  )
