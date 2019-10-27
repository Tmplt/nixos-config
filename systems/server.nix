{
  praecursoris = { pkgs, lib, ... }: rec {
    deployment.targetHost = "praecursoris.campus.ltu.se";
    time.timeZone = "Europe/Stockholm";

    imports = [
      ../hardware-configurations/praecursoris.nix
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
    };

    boot.loader.grub = {
      enable = true;
      version = 2;
      devices = [ "/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd" ];
    };
    boot.supportedFilesystems = [ "zfs" ];

    nix.trustedUsers = [ "root" "@builders" ];
    users.groups.builders = {};
    users.users.builder = {
      isNormalUser = false;
      group = "builders";
      shell = "${pkgs.bash}/bin/bash";
      openssh.authorizedKeys.keys = [ (import ../ssh-keys.nix).builder ];
    };

    services.syncthing.enable = true;

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
          locations."/".root = (fetchTarball {
            url = "https://github.com/tmplt/tmplt.dev/archive/master.tar.gz";
            sha256 = "1y2813rbz267j4j4cdpq8hz65b9jj3vx1ncdw799jlj9sa4wdsvj";
          });
        };

        "www.tmplt.dev" = {
          forceSSL = true;
          enableACME = true;
          locations."/".extraConfig = "return 301 $scheme://tmplt.dev$request_uri;";
        };

        "mumble.dragons.rocks" = {
          enableACME = true;
          locations."/".extraConfig = "return 301 $scheme://tmplt.dev;";
        };
      };
    };

    system.stateVersion = "19.09";
  };
}
