# Declare common options for servers.

{ config, lib, pkgs, ... }:

let
  sshKeys = import ./ssh-keys.nix;
in
{
  users.users.tmplt = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ sshKeys.tmplt ];
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  nix.gc = {
    automatic = true;
    options = "-d --delete-older-than 30d";
  };
}
