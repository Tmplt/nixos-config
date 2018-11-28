{ config, lib, pkgs, ... }:

{
  imports = [
    ./local-configuration.nix
    (import ./packages.nix {inherit config pkgs; })
  ];
}
