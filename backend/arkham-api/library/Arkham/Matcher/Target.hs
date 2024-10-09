{-# LANGUAGE TemplateHaskell #-}

module Arkham.Matcher.Target where

import Arkham.Matcher.Act
import Arkham.Matcher.Agenda
import {-# SOURCE #-} Arkham.Matcher.Asset
import Arkham.Matcher.Enemy
import {-# SOURCE #-} Arkham.Matcher.Investigator
import Arkham.Matcher.Location
import Arkham.Prelude
import {-# SOURCE #-} Arkham.Target
import Arkham.Trait (Trait)
import Data.Aeson.TH

data TargetMatcher
  = TargetIs Target
  | TargetMatchesAny [TargetMatcher]
  | AnyTarget
  | TargetMatches [TargetMatcher]
  | LocationTargetMatches LocationMatcher
  | ActTargetMatches ActMatcher
  | AgendaTargetMatches AgendaMatcher
  | AssetTargetMatches AssetMatcher
  | EnemyTargetMatches EnemyMatcher
  | ScenarioCardTarget
  | TargetWithDoom
  | TargetAtLocation LocationMatcher
  | NotTarget TargetMatcher
  | TargetWithTrait Trait
  | TargetControlledBy InvestigatorMatcher
  deriving stock (Show, Eq, Ord, Data)

instance Not TargetMatcher where
  not_ = NotTarget

instance Semigroup TargetMatcher where
  AnyTarget <> x = x
  x <> AnyTarget = x
  TargetMatches xs <> TargetMatches ys = TargetMatches $ xs <> ys
  TargetMatches xs <> x = TargetMatches $ xs <> [x]
  x <> TargetMatches xs = TargetMatches $ x : xs
  x <> y = TargetMatches [x, y]

data TargetListMatcher
  = HasTarget TargetMatcher
  | ExcludesTarget TargetMatcher
  | AnyTargetList
  deriving stock (Show, Eq, Ord, Data)

mconcat
  [ deriveJSON defaultOptions ''TargetMatcher
  , deriveJSON defaultOptions ''TargetListMatcher
  ]
