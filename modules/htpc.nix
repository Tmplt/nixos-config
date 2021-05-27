{ config, lib, pkgs, ... }:
let
  secrets = import ../secrets;
in
{
  virtualisation.docker.enable = true;

  # Make sure intra-container networks exist
  # TODO can we generalize this?
  systemd.services.init-docker-networks = {
    description = "Create the network bridges used by docker containers.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "oneshot";
    script =
      let dockercli = "${config.virtualisation.docker.package}/bin/docker";
      in
      ''
        # Put a true at the end to prevent getting non-zero return code, which will
        # crash the whole service.
        check=$(${dockercli} network ls | grep "adhoc" || true)
        if [ -z "$check" ]; then
          ${dockercli} network create adhoc
        else
          echo "adhoc already exists in docker"
        fi
      '';
  };

  virtualisation.oci-containers.containers = {
    rutorrent = {
      image = "ghcr.io/crazy-max/rtorrent-rutorrent";
      environment = {
        "TZ" = "Europe/Stockholm";
        "XMLRPC_PORT" = "8000";
        "RUTORRENT_PORT" = "8080";
        "WEBDAV_PORT" = "9000";
      };
      ports = [ "8888:8080" ];
      volumes = [
        "/rpool/dockers/rutorrent/data:/data"
        "/vpool/downloads:/downloads"

        # TODO Nixity the passwds
        "/rpool/dockers/rutorrent/passwd:/passwd"
      ];
      extraOptions = [ "--network=adhoc" ];
    };

    radarr = {
      image = "ghcr.io/linuxserver/radarr";
      environment = {
        "PUID" = "1000";
        "PGID" = "1000";
        "TZ" = "Europe/Stockholm";
      };
      ports = [ "7878:7878" ];
      volumes = [
        "/rpool/dockers/radarr:/config"
        "/rpool/media/movies:/movies"
        "/vpool/downloads:/downloads"
      ];
      extraOptions = [ "--network=adhoc" ];
    };

    # TODO sonarr

    jackett = {
      image = "ghcr.io/linuxserver/jackett";
      environment = {
        "PUID" = "1000";
        "GUID" = "1000";
        "TZ" = "Europe/Stockholm";
      };
      ports = [ "9117:9117" ];
      volumes = [
        "/rpool/dockers/jackett/config:/config"
        "/vpool/dockers/jackett/blackhole:/downloads"
      ];
      extraOptions = [ "--network=adhoc" ];
    };

    bazarr = {
      image = "ghcr.io/linuxserver/bazarr";
      environment = {
        "PUID" = "1000";
        "GUID" = "1000";
        "TZ" = "Europe/Stockholm";
      };
      ports = [ "6767:6767" ];
      volumes = [
        "/rpool/dockers/bazarr/config:/config"
        "/rpool/media/movies:/movies"
      ];
      extraOptions = [ "--network=adhoc" ];
    };
  };

  services.nginx.virtualHosts = {
    "den.dragons.rocks" = secrets.nasSettings // {
      default = true;
      forceSSL = true;
      enableACME = true;

      locations."/radarr".proxyPass = "http://localhost:7878";
      locations."/bazarr".proxyPass = "http://localhost:6767";
      locations."/jackett".proxyPass = "http://localhost:9117";

      locations."/" = {
        root = "/rpool/media/";
        extraConfig = ''
          autoindex on;
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    8888 # rutorrent
  ];
}
