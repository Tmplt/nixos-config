let
  secrets = (import ../secrets).dulcia;
in
{
  dulcia = {
    deployment.targetHost = "dulcia.localdomain";
    time.timeZone = "Europe/Stockholm";
    networking.hostName = "dulcia";
    networking.hostId = "61ceb5ad";

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    networking.useDHCP = false;
    networking.interfaces.enp10s0f0.useDHCP = true;
    networking.interfaces.enp10s0f1.useDHCP = true;
    networking.interfaces.enp4s0.useDHCP = true;
    networking.interfaces.enp9s0f0.useDHCP = true;
    networking.interfaces.enp9s0f1.useDHCP = true;

    imports = [
        ../hardware-configurations/nas.nix
        <nixpkgs/nixos/modules/profiles/headless.nix>
        ../common-server.nix
      ];

    # Use the GRUB 2 boot loader.
    boot.loader.grub = {
      enable = true;
      version = 2;
      devices = [
        "/dev/disk/by-id/ata-WDC_WD60EFRX-68L0BN1_WD-WX11D76EPVX7"
        "/dev/disk/by-id/ata-WDC_WD60EFRX-68L0BN1_WD-WX31D95842XA"
      ];
    };
    boot.supportedFilesystems = [ "zfs" ];

    # fileSystems."/export/media" = {
    #   device = "/media";
    #   options = [ "bind" ];
    # };

    # fileSystems."/export/media/tv-series4" = {
    #   device = "/volatile/tv-series";
    #   options = [ "bind" ];
    # };

    services.nfs.server.enable = false;
    services.nfs.server.exports = ''
      /export         192.168.0.122(rw,sync,no_subtree_check,fsid=0,crossmnt)
      /export/media   192.168.0.122(rw,sync,no_subtree_check)
    '';

    services.zfs.autoScrub.enable = true;
    services.zfs.autoSnapshot.enable = true;

    services.mpd = {
      enable = false;
      user = "tmplt";
      group = "users";
      musicDirectory = "/media/music";
      extraConfig = ''
        password "${secrets.mpdPassword}@read,control,add,admin"
        bind_to_address "192.168.0.101"
        port "6600"
        max_output_buffer_size "${toString (8192 * 16)}"

        audio_output {
          type "shout"
          encoding "ogg"
          name "local icecast stream"
          host "localhost"
          port "8000"
          mount "/mpd.ogg"
          password "${secrets.icecast.sourcePassword}"
          quality "10.0"
          format "44100:16:1"
          description "find /media/music | xargs mpv --shuffle"
          genre "madness"
        }

        audio_output {
          type "null"
          name "fake out"
        }
      '';
    };

    services.icecast = {
      enable = false;
      admin.password = secrets.icecast.adminPassword;
      hostname = "den.dragons.rocks";
      listen.port = 8000;
      extraConf = ''
        <authentication>
          <source-password>${secrets.icecast.sourcePassword}</source-password>
        </authentication>
      '';
    };

    # Open ports in the firewall.
    networking.firewall.allowedTCPPorts = [
      6600 8000 # MPD and Icecast
    ];

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    system.stateVersion = "19.09"; # Did you read the comment?
  };
}
