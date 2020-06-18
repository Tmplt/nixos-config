# Declare common options for servers.

{ config, lib, pkgs, ... }:

let
  sshKeys = import ./ssh-keys.nix;
  secrets = import ./secrets;
  automationEmail = "robots@tmplt.dev";
in
{
  users.users.tmplt = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = with sshKeys; [ tmplt mako ];
  };
  users.users.root.openssh.authorizedKeys.keys = [ sshKeys.tmplt ];

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  services.ssmtp = {
    enable = true;
    authUser = automationEmail;
    authPass = secrets.ssmtp.authPass;
    domain = "tmplt.dev";
    hostName = "smtp.migadu.com:465";
    useTLS = true;
  };

  nix.gc = {
    automatic = true;
    options = "-d --delete-older-than 30d";
  };
}
