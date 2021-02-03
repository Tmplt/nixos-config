{
  network = {
    description = "my personal remote systems";
    enableRollback = true;
  };

  defaults = { pkgs, ... }: let automationEmail = "robots@tmplt.dev"; in {
    users.users = let sshKeys = import ./ssh-keys.nix; in {
      root.openssh.authorizedKeys.keys = with sshKeys; [ tmplt ];

      tmplt = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = with sshKeys; [ tmplt ];
      };
    };

    services.openssh = {
      enable = true;
      passwordAuthentication = false;
    };

    deployment.keys.ssmtp-authpass = {
      text = (import ./secrets).ssmtp.authPass;
      user = "tmplt";
      group = "wheel";
      permissions = "0400";
    };

    services.ssmtp = {
      enable = true;
      authUser = automationEmail;
      authPassFile = "/run/keys/ssmtp-authpass";
      domain = "tmplt.dev";
      hostName = "smtp.migadu.com:465";
      useTLS = true;
      setSendmail = true;
    };

    services.smartd = {
      enable = true;

      # Default settings, but daily short self-tests, ~bi-weekly long self-tests.
      # TODO: long self-tests should be prio'd here. Are they?
      defaults.autodetected = "-a -s (L/../(01|16)/./00|S/../.././00)";

      notifications.mail = {
        enable = true;
        sender = automationEmail;
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

      # Email program is called like: `eval "${ZED_EMAIL_PROG}" ${ZED_EMAIL_OPTS} < email-body`
      ZED_EMAIL_PROG = toString (pkgs.writeShellScript "zfs-zed-email-wrapper" ''
      subject=$1
      address=$2
      body=$(${pkgs.coreutils}/bin/cat -)

      ${pkgs.ssmtp}/bin/ssmtp $address <<EOF
      From: zfs-zed on $(${pkgs.inetutils}/bin/hostname) <${automationEmail}>
      Subject: $subject
      $body
      EOF
    '');
    };

    nix.gc = {
      automatic = true;
      options = "-d --delete-older-than 30d";
    };
  };

  nas = import ./systems/nas.nix;
  ludd = import ./systems/server.nix;
}
