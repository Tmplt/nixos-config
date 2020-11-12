let
  secrets = (import ../secrets);
in
{
  dulcia = { pkgs, ... }: {
    deployment.targetHost = "home.tmplt.dev";
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

    environment.systemPackages = with pkgs; [
      beets
      ffmpeg
    ];

    services.zfs.autoReplication = {
      enable = true;
      username = "root"; # TODO: use a dedicated backup user <https://github.com/openzfs/zfs/issues/7294>
      host = "tmplt.dev";
      identityFilePath = /root/.ssh/id_backup;
      localFilesystem = "rpool/media/music";
      remoteFilesystem = "rpool/backups";
      followDelete = true;
    };

    services.nfs.server.enable = true;
    services.nfs.server.exports = ''
      /rpool/media         perscitia.localdomain(rw,crossmnt,no_subtree_check)
      /rpool/media         192.168.1.194(ro,crossmnt,no_subtree_check)
    '';

    services.mpd = {
      enable = false;
      user = "tmplt";
      group = "users";
      musicDirectory = "/media/music";
      extraConfig = ''
        password "${secrets.dulcia.mpdPassword}@read,control,add,admin"
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
          password "${secrets.dulcia.icecast.sourcePassword}"
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
      admin.password = secrets.dulcia.icecast.adminPassword;
      hostname = "den.dragons.rocks";
      listen.port = 8000;
      extraConf = ''
        <authentication>
          <source-password>${secrets.dulcia.icecast.sourcePassword}</source-password>
        </authentication>
      '';
    };

    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      declarative = {
        devices.mako.id = secrets.syncthing.phoneID;

        folders."/rpool/phone-mirror/" = {
          devices = [ "mako" ];
          label = "media";
        };
      };
    };

    # Open ports in the firewall.
    networking.firewall.allowedTCPPorts = [
      6600 8000 # MPD and Icecast
      2049 111 20048 # NFS
    ];

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    system.stateVersion = "19.09"; # Did you read the comment?
  };
}
