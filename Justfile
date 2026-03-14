test: hpack
  fourmolu --mode check src test
  nixfmt -c *.nix
  cabal test

format:
  fourmolu -i src test
  nixfmt *.nix

build: hpack
  cabal build

hpack:
  hpack

regen-hoogle: hpack
  cabal-hoogle generate

setup:
  cabal user-config init --augment="nix: True"
  cabal update
  cabal-hoogle generate
