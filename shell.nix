{ nixpkgs ? import <nixpkgs> {} }:
let
  inherit (nixpkgs) pkgs;
  nixPackages = [
    pkgs.ruby
    pkgs.jekyll
    pkgs.zlib
    pkgs.bundler
  ];
in
pkgs.stdenv.mkDerivation {
  name = "jekyll-local";
  buildInputs = nixPackages;
  shellHooks = "bundle install && bundle exec jekyll serve -o --livereload && exit";
}
