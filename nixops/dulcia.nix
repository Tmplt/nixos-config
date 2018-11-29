{
  dulcia = {
    deployment.targetHost = "192.168.2.77";
    time.timeZone = "Europe/Stockholm";
    networking.hostName = "dulcia";

    imports = [
        ./hardware-configuration.nix
        ./common.nix
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

    services.nfs.server.enable = true;
    services.nfs.server.exports = ''
      /export         temeraire(rw,sync,no_subtree_check,fsid=0)
      /export/media   temeraire(rw,sync,no_subtree_check)

      /export         192.168.2.228(sync,no_subtree_check,fsid=0)
      /export/media   192.168.2.228(sync,no_subtree_check)
    '';

    services.zfs.autoScrub.enable = true;
    services.zfs.autoSnapshot = {
      enable = true;
      frequent = 8; # keep the latest eight 15-minute snapshorts
      monthly = 1; # keep only one monthly snapshot
    };

    # qemu/kvm
    users.groups.libvirtd.members = [ "root" "tmplt" ];
    virtualisation.libvirtd.enable = true;

    # Open ports in the firewall.
    networking.firewall.allowedTCPPorts = [ 2049 ];
    networking.firewall.allowedUDPPorts = [ 2049 ];

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    system.stateVersion = "18.03"; # Did you read the comment?
  };
}
