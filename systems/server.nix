let
  sshKeys = import ../ssh-keys.nix;
  secrets = import ../secrets;
in
{
  praecursoris = { pkgs, lib, ... }: rec {
    deployment.targetHost = "praecursoris.campus.ltu.se";
    time.timeZone = "Europe/Stockholm";

    imports = [
      ../hardware-configurations/server.nix
      <nixpkgs/nixos/modules/profiles/headless.nix>
      ../common-server.nix
    ];

    networking = {
      hostName = "praecursoris";
      hostId = "61ceb5ac";

      interfaces.enp4s0.ipv4.addresses = [{
        address = "130.240.202.140";
        prefixLength = 24;
      }];

      defaultGateway = "130.240.202.1";
      nameservers = [ "130.240.16.8" ];

      defaultMailServer = {
        authPassFile = "/run/keys/ssmtp-authpass";
        authUser = "tmplt@dragons.rocks";
        directDelivery = true;
        domain = "tmplt.dev";
        hostName = "smtp.mailbox.org:465";
        setSendmail = true;
        useTLS = true;
      };
    };

    boot.loader.grub = {
      enable = true;
      version = 2;
      devices = [ "/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd" ];
    };
    boot.supportedFilesystems = [ "zfs" ];

    services.zfs = {
      autoScrub = { enable = true; interval = "monthly"; };
      autoSnapshot.enable = true;
    };

    systemd.services.zfs-health-check = {
      description = "Periodically check ZFS pool health status";
      serviceConfig.Type = "oneshot";
      serviceConfig.User = "root";
      requires = [ "zfs.target" "zfs-import.target" ];
      startAt = "minutely";

      script = ''
        set -euo pipefail

        ec=$(${pkgs.zfs}/bin/zpool status -x | ${pkgs.gnugrep}/bin/grep "all pools are healthy")
        [[ $? -eq 0 ]] && exit 0

        /run/wrappers/bin/sendmail tmplt@dragons.rocks <<EOF
        To: tmplt@dragons.rocks
        From: ZFS health monitor <root@praecursoris.campus.ltu.se>
        Subject: Alert: ZFS pool status unhealthy

        All pools did not report as healty:

        $ zpool status -v
        $(${pkgs.zfs}/bin/zpool status -v)
        EOF
      '';
    };

    nix.trustedUsers = [ "root" "@builders" ];
    users.groups.builders = {};
    users.users.builder = {
      isNormalUser = false;
      group = "builders";
      useDefaultShell = true;
      openssh.authorizedKeys.keys = [ sshKeys.builder ];
    };

    services.syncthing = rec {
      enable = true;
      openDefaultPorts = true;
      dataDir = "/var/lib/syncthing";
      declarative = {
        devices.perscitia = {
          id = secrets.syncthing.laptopID;
          introducer = true;
        };

        folders."${dataDir}/sync" = {
          devices = [ "perscitia" ];
          label = "sync";
        };
      };
    };

    services.taskserver = {
      enable = true;
      fqdn = "${networking.hostName}.campus.ltu.se";
      listenHost = "::";
      organisations.personal.users = [ "tmplt" ];

      pki.auto.expiration = {
        ca = 365;
        client = 365;
        crl = 365;
        server = 365;
      };
    };

    nixpkgs.config.packageOverrides = pkgs: {
      murmur = (import ../nixpkgs-pin.nix).unstable.murmur;
    };
    services.murmur = {
      enable = true;
      hostName = (lib.head networking.interfaces.enp4s0.ipv4.addresses).address;
      password = (import ../secrets).murmurPasswd;
      imgMsgLength = 2 * 1024 * 1024; # 2Mi
      registerName = "Draknästet";
      bandwidth = 128000;

      # TODO: PR options for these
      extraConfig =  ''
        username=.*
        channelname=.*
        rememberchannel=false
        suggestVersion=1.3.0
        opusthreshold=0
      '';

      sslCert = "/var/lib/acme/mumble.dragons.rocks/fullchain.pem";
      sslKey = "/var/lib/acme/mumble.dragons.rocks/key.pem";
    };
    users.users.murmur.group = "murmur";
    users.groups.murmur = {};
    security.acme.certs."mumble.dragons.rocks" = {
      allowKeysForGroup = true;
      group = "murmur";

      # Tell murmur to reload its SSL settings, if it is running
      postRun = ''
        if ${pkgs.systemd}/bin/systemctl is-active murmur.service; then
          ${pkgs.systemd}/bin/systemctl kill -s SIGUSR1 murmur.service
        fi
      '';
    };

    # TODO: polling is ugly; can we manage this with a git web-hook instead?
    users.users.homepage = {
      createHome = true;
      description = "tmplt.dev website";
      home = "/home/homepage";
      useDefaultShell = true;
      openssh.authorizedKeys.keys = [ sshKeys.tmplt ];
    };
    systemd.services.update-homepage = {
      description = "Init/update tmplt.dev homepage";
      serviceConfig.User = "homepage";
      serviceConfig.Type = "oneshot";
      path = with pkgs; [ git ];
      script = ''
        cd ~/
        if [ ! $(git rev-parse --is-inside-work-tree) ]; then
          git clone https://github.com/tmplt/tmplt.dev.git .
        else
          git fetch origin master
          git reset --hard origin/master
        fi
      '';
      startAt = "hourly";
      wantedBy = [ "multi-user.target" ];
      before = [ "nginx.service" ];
    };

    systemd.services.init-passwd = {
      description = "Init passwd.git repository";
      serviceConfig.User = "tmplt";
      serviceConfig.Type = "oneshot";
      path = with pkgs; [ git ];
      script = ''
        set -euox pipefail
        mkdir -p ~/passwd.git && cd ~/passwd.git
        if [ ! $(git rev-parse --is-inside-work-tree) ]; then
          git init --bare .
        fi
      '';
      wantedBy = [ "multi-user.target" ];
    };

    networking.firewall.allowedTCPPorts = [ 80 443 64738 ];
    networking.firewall.allowedUDPPorts = [ 64738 ];
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts = {
        "tmplt.dev" = {
          forceSSL = true;
          enableACME = true;
          default = true;
          # TODO: deny access to all hidden files instead
          locations."~ /\.git".extraConfig = "deny all;";
          locations."/".root = users.users.homepage.home;
        };

        "www.tmplt.dev" = {
          forceSSL = true;
          enableACME = true;
          locations."/".extraConfig = "return 301 $scheme://tmplt.dev$request_uri;";
        };

        "mumble.dragons.rocks" = {
          enableACME = true;
          globalRedirect = "tmplt.dev";
        };
      };
    };

    services.cron = {
      enable = true;
      systemCronJobs = [
        "* * * * */15 echo $(date +%s) $(${pkgs.curl}/bin/curl -s -o /dev/null -I -w '%{http_code}' https://tenta.ltu.se) >> /home/tmplt/ladok.stats.csv"
      ];
    };

    users.groups.libvirtd.members = [ "root" "tmplt" ];
    virtualisation.libvirtd.enable = true;

    system.stateVersion = "19.09";
  };
}
