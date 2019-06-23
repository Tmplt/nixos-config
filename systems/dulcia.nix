let
  secrets = (import ../secrets).dulcia;
in
{
  dulcia = {
    deployment.targetHost = "den.dragons.rocks";
    time.timeZone = "Europe/Stockholm";
    networking.hostName = "dulcia";

    imports = [
        ../hardware-configurations/dulcia.nix
        <nixpkgs/nixos/modules/profiles/headless.nix>
        ../common-server.nix
      ];

    # Use the GRUB 2 boot loader.
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.grub.device = "/dev/disk/by-id/ata-INTEL_SSDSA2CW080G3_CVPR135202U4080BGN";
    boot.supportedFilesystems = [ "zfs" ];

    networking.hostId = "ff7870de";

    fileSystems."/export/media" = {
      device = "/media";
      options = [ "bind" ];
    };

    fileSystems."/export/media/tv-series4" = {
      device = "/volatile/tv-series";
      options = [ "bind" ];
    };

    services.nfs.server.enable = true;
    services.nfs.server.exports = ''
      /export         temeraire(rw,sync,no_subtree_check,fsid=0,crossmnt)
      /export/media   temeraire(rw,sync,no_subtree_check)
    '';

    services.zfs.autoScrub.enable = true;
    services.zfs.autoSnapshot = {
      enable = true;
      frequent = 8; # keep the latest eight 15-minute snapshorts
      monthly = 1; # keep only one monthly snapshot
    };

    services.mpd = {
      enable = true;
      user = "tmplt";
      group = "users";
      musicDirectory = "/media/music";
      extraConfig = ''
        password "${secrets.mpdPassword}@read,control,add,admin"
        bind_to_address "192.168.0.101"
        port "6600"

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
      enable = true;
      admin.password = secrets.icecast.adminPassword;
      hostname = "den.dragons.rocks";
      listen.port = 8000;
      extraConf = ''
        <authentication>
          <source-password>${secrets.icecast.sourcePassword}</source-password>
        </authentication>
      '';
    };

    # qemu/kvm
    users.groups.libvirtd.members = [ "root" "tmplt" ];
    virtualisation.libvirtd.enable = true;

    # Open ports in the firewall.
    networking.firewall.allowedTCPPorts = [
      2049 # ?
      6600 8000 # MPD and Icecast
    ];
    networking.firewall.allowedUDPPorts = [ 2049 ];

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    system.stateVersion = "18.03"; # Did you read the comment?
  };
}
