---
layout: post
title: Basic Profiling with GHC
author: cramsay
date:   2019-10-18 11:48:25 +0100
categories: haskell functional programming phd
---

Recently I was re-writing some of my own Haskell code and made it much, much
worse. On the bright side, it was a nice excuse to learn a little about GHCs
profiling tools. Here's a quick success story.

## Context

The code I was re-writing was for a bit of research I'm doing on describing
circuits where the parameters have a huge impact on the circuit topology.
Haskell ([Clash](https://clash-lang.org/), specifically) is a nice playground to
implement and verify circuits like these.

I was refactoring it to use a common library for all of the graph data
structures, rather than using my own custom ones. The original code used 3
different graph structures, each with their own helper functions, and it was
getting a little silly. So, at the cost of some type safety, I'm moving to the
[`fgl`](http://hackage.haskell.org/package/fgl-5.7.0.1) library, which already
has a lot of the functionality I need.

## Problem

So I've written a chunk of this code using the `fgl` graph... but it was eating
up my RAM like nobody's business! The original implementation didn't have this
issue, so it wasn't anything fundamental in the algorithm.

I'm being deliberately vague here, but the code is generating a huge graph,
which will grow as we demand graphs for larger bit-widths. 12 bits should be
achievable, but my new implementation would collapse after 8 bits on a machine
with 16 GB!

So, let's do some profiling to work out what is going wrong here.

## Profiling


There's a page over at
[haskell.org](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/profiling.html)
that has a nice summary of profiling with GHC. Let's use some of those
techniques and apply it to my new program.

  1) Compile the program (`AdderGraphFgl`) with GHC and extra arguments to
  include profiling information for all bindings --- even functions defined in
  where clauses, etc.
     
`ghc -prof -fprof-auto -rtsopts AdderGraphFgl`

  2) Run the program and ask for profiling output
  
`./AdderGraphFgl +RTS -p`

The output is now in `AdderGraphFgl.prof`. Let's take a look at the first few
lines in this file.

```raw
                                                                                                                      individual      inherited
COST CENTRE       MODULE                            SRC                                            no.     entries  %time %alloc   %time %alloc

MAIN              MAIN                              <built-in>                                     145          0    0.0    0.0   100.0  100.0
 CAF              Main                              <entire-module>                                289          0    0.0    0.0   100.0  100.0
  emptyMag        Main                              AdderGraphFgl.hs:166:1-30                      311          1    0.0    0.0     0.0    0.0
   insNode        Data.Graph.Inductive.Graph        Data/Graph/Inductive/Graph.hs:273:1-30         312          1    0.0    0.0     0.0    0.0
  main            Main                              AdderGraphFgl.hs:214:1-52                      290          1    0.0    0.0   100.0  100.0
   showsPre       Main                              AdderGraphFgl.hs:19:15-18                      390       4568    0.0    0.0     0.0    0.0
```

We get a few things from this output, including:

  * Call description:
    + The name, line number, and module of each function called
  * Number of entries to each function
  * Percentage of total time and memory allocation spent in each function, shown
    in 2 ways:
    + *Individual* --- what % was spent in the code directly within this
      function?
    + *Inherited* --- what % was spent in this function *and* all of the
      functions this one calls?
    
To find the source of my problem, let's scroll down this file and look for any
suspiciously high "Individual" percentages.

Sure enough, there's a few culprits, all within the `nextEdgePair` function:

```raw
                                                                                                                      individual      inherited
COST CENTRE          MODULE                            SRC                                            no.     entries  %time %alloc   %time %alloc

nextEdgePair.ids     Main                              AdderGraphFgl.hs:65:9-69                       425      12939    7.4   10.9    85.5   82.2
 edgeLabel           Data.Graph.Inductive.Graph        Data/Graph/Inductive/Graph.hs:257:1-21         430  177200460    1.3    0.0     1.3    0.0
 emap                Data.Graph.Inductive.Graph        Data/Graph/Inductive/Graph.hs:(227,1)-(229,26) 427      12939    0.0    0.0    37.5   46.6
  gmap               Data.Graph.Inductive.Graph        Data/Graph/Inductive/Graph.hs:217:1-33         428      12939    0.0    0.0    37.5   46.6
   ufold             Data.Graph.Inductive.Graph        Data/Graph/Inductive/Graph.hs:(209,1)-(213,23) 429   23068745   35.9   46.6    37.5   46.6
    pairID           Main                              AdderGraphFgl.hs:16:5-10                       431  177200460    1.6    0.0     1.6    0.0
 uniq                Main                              AdderGraphFgl.hs:203:1-24                      426          0   39.4   24.7    39.4   24.7
```

We're spending 85% of the time in the `nextEdgePair` function and there are parts
of it entered 177 *million* times! Let's go back to the source code and see
what's going on here.

## My bad code

Before we look at the `nextEdgePair` function, let's look at my graph type. I'm
using `DynGraph` from the `fgl` library, which takes two type parameters --- a
node label type and an edge label type.

In this case, the node label is just an `Int`, but the edge label is more
complex. In this graph, I really need to group edges into pairs.

> I'm essentially modelling a graph of different combinations of 2-input adders,
  so I need to pair up inputs to each adder node.

To do this, I make the edge label a record structure that has a pair ID field to
help group the edges into pairs, as well as any other edge data I need to track.

```haskell
type NLabel = Int

data ELabel = EL {
    pairID :: Int
  , shift  :: Int
  , ...
  } deriving (Show, Read, Eq)

type LookupGraph gr = gr NLabel ELabel
```

OK, now that we understand the need for these edge `pairID` values, let's
take a peek at the `nextEdgePair` function. If we give this function a graph, it
should return the next unused `pairID` value (which we'll need when safely
adding new edges!).

```haskell
-- | Get next available edge pair ID
nextEdgePair :: DynGraph gr
             => LookupGraph gr -- ^ Input graph
             -> Int            -- ^ Next edge pair ID
nextEdgePair gr = fst . head . filter (\(a,b)->a/=b) $ zip [0..] (ids ++ [-1])
  where ids = sort . uniq . map edgeLabel . labEdges $ emap pairID gr
```

The thing that jumps out at me is that the `ids` where clause uses `sort` and
`uniq`, both of which will evaluate the *entire* list of edges! So, every time
we want to add an edge to this huge graph, we have to do a computation over all
of the existing edges first!

That's a bit daft, and I should've thought about that while writing the code!
Regardless, we still got to the bottom of it after a little profiling.

So, how should I have structured this in the first place?

## My better code

There's no avoiding the `pairID` tracking without changing the graph structure,
but let's not go down that route because the whole point of this refactoring was
to settle on an existing library!

The other approach is to change the scope of the `pairID` labels. Instead of
numbering these globally for a graph, why not label them with respect to the
node that they lead into? The new `ELabel` type would look like:

```haskell
data ELabel = EL {
    pairID :: (NLabel, Int) 
  , shift  :: Int
  , ...
  } deriving (Show, Read, Eq)
```

This way we don't have to look at all edges, just all edges leading into one
node. Also the rest of the algorithm will only ever incrementally add edges (we
only remove them if the node is replaced), so we don't even need to look at the
`pairID` values --- just count the total number and divide by 2!
The updated version of `nextEdgePair` is then:

```haskell
nextEdgePair gr node = (node, length (pre gr node) `div` 2)
```

Comparing execution times of these two implementations gets a little
embarrassing... the improved code has a total wall-clock time of 0.52 seconds
for 8-bit words, as reported by the GHC profiling. The face-palm inducing
implementation runs in 4:21 minutes.

Jeepers.
