# This module defines a small NixOS installation CD.  It does not
# contain any graphical stuff.
# TODO: 
{ config, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>

    # Provide an initial copy of the NixOS channel so that we
    # don't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nixos-custom-install" (builtins.readFile ./laptop.sh))
  ];
}
