{ config, lib, pkgs, ... }:

{
  virtualisation.docker.enable = true;

  # Make sure intra-container networks exist
  # TODO can we generalize this?
  systemd.services.init-docker-networks = {
    description = "Create the network bridges used by docker containers.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "oneshot";
    script = let dockercli = "${config.virtualisation.docker.package}/bin/docker";
             in ''
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
  };

  networking.firewall.allowedTCPPorts = [
    7878 # radarr
    8888 # rutorrent
  ];
}
