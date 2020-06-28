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
    setSendmail = true;
  };

  disabledModules = [ "services/monitoring/smartd.nix" ];
  imports = [ ./modules/smartd.nix ];

  services.smartd = {
    enable = true;

    # Default settings, but daily short self-tests, ~bi-weekly long self-tests.
    # TODO: long self-tests should be prio'd here. Are they?
    defaults.autodetected = "-a -s (L/../(01|16)/./00|S/../.././00)";

    notifications.mail = {
      enable = true;
      sender = automationEmail; # <https://github.com/NixOS/nixpkgs/pull/91432>
      mailer = "/run/wrappers/bin/sendmail";
      recipient = "v@tmplt.dev";
    };
  };

  services.zfs = {
    autoScrub.enable = true;
    autoScrub.interval = "*-*-7,23 00:00";

    autoSnapshot.enable = true;
  };

  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ "v@tmplt.dev" ];
    ZED_EMAIL_OPTS = "'@SUBJECT@' @ADDRESS@";
    ZED_NOTIFY_VERBOSE = true; # notify me even if pools are healthy
    ZED_SCRUB_AFTER_RESILVER = true;

    # Email program is called like: `sval "${ZED_EMAIL_PROG}" ${ZED_EMAIL_OPTS} < email-body`
    ZED_EMAIL_PROG = toString (pkgs.writeShellScript "zfs-zed-email-wrapper" ''
      subject=$1
      address=$2
      body=$(${pkgs.coreutils}/bin/coreutils --coreutils-prog=cat -)

      ${pkgs.ssmtp}/bin/ssmtp $address <<EOF
      From: ${automationEmail}
      Subject: $subject
      $body
      EOF
    '');
  };

  nix.gc = {
    automatic = true;
    options = "-d --delete-older-than 30d";
  };
}
