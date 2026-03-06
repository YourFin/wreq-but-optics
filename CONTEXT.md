# Looking up documentation

cabal-hoogle run <query> can be used to search the locally available package set.

Documentation for specific items can be referenced via ghci. For example,
to look up the documentation for `Optics.TH makePrisms`:

```nushell
"import Optics.TH\n:doc makePrisms" | cabal repl
```
