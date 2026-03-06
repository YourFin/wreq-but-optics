test: hpack
	cabal test

build: hpack
	cabal build

hpack:
	hpack

setup:
	cabal user-config init --augment="nix: True"
	cabal update
	cabal-hoogle generate
