# Scrabble.jl
Some tools for anagrams, word jumbles, scrabble, etc.

# Installation

Use Julia's package manager, `Pkg`:
```
julia> Pkg.add("github.com/dpmerrell/Scrabble.jl")
```

# Key features

* `anagram_iter(text::String)`: an iterator over all possible anagrams of a given string.
   Warning: the complexity grows explosively with the length of the string!!
   We use dynamic programming for efficiency, but it's still an expensive problem to solve.
* `jumble_iter(text::String)`: an iterator over all possible words that can be produced from a 
   subset of the characters in `text`. Useful for "word jumble" kinds of games.
   
# Algorithmic ideas

Under the hood, we work almost entirely in terms of "bags": 26-dimensional vectors of integers
representing the quantity of each alphabetical character in a string.

The code in this repository consists mostly of different kinds of iterators over bags.
