{-# LANGUAGE ExistentialQuantification #-}

module BenchGraph (
  Edges,
  ToFuncToBench,
  FuncToBench (..),
  GraphImpl,
  mkGraph,
  benchFunc
) where

import Criterion.Main
import Control.DeepSeq (NFData(..))

-- Generic graph
type Edges = [(Int,Int)]

-- We want to pass the generic graph to create an according function to test
type ToFuncToBench a = Edges -> FuncToBench a

-- Type used to group different types of functions
data FuncToBench a = forall b. NFData b => Consummer String (a -> b) 
  | forall b c. NFData c => FuncWithArg String (b -> a -> c) (b -> String) [b]

-- An interface between our generic graphs and others
class GraphImpl g where
  mkGraph :: Edges -> g

-- Main function
-- Will be cooler if its return a single benchmark with bgroup
benchFunc :: GraphImpl g => ToFuncToBench g -> [Edges] -> [Benchmark]
benchFunc tofunc = map (\e -> benchFunc' (tofunc e) e)

-- Here we bench a single function over a single graph
benchFunc' :: GraphImpl g => FuncToBench g -> Edges -> Benchmark
benchFunc' (Consummer name fun) edges = bench (name++"/"++(show edges)) $ nf fun $! mkGraph edges
benchFunc' (FuncWithArg name fun showArg args ) edges = bgroup (name++"/"++(show edges)) $ map (\arg -> bench (showArg arg) $ nf (fun arg) $! mkGraph edges) args
