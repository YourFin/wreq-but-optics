# Wreq, but Optics!

This package provides two modules:
 - [Network.Wreq.Optics](src/Network/Wreq/Optics.hs) - A re-implementation of [Network.Wreq.Lens](https://hackage.haskell.org/package/wreq/docs/Network-Wreq-Lens.html), but exporting [`optics`](https://hackage.haskell.org/package/optics) instead of [`lens`](https://hackage.haskell.org/package/lens)es.
 - [Network.Wreq.ButOptics](src/Network/Wreq/ButOptics.hs) - A re-export of the same api as [Network.Wreq](https://hackage.haskell.org/package/wreq/docs/Network-Wreq.html), but [`lens`](https://hackage.haskell.org/package/lens)-related exports are replaced with [`optics`](https://hackage.haskell.org/package/optics) variants

# Versioning

Philosophically, this is intended as a dumb wrapper package. Major/patch versions of this package should match those of `wreq` to make understanding version numbers straightforward.

