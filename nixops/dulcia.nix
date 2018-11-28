let
  sshKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJYN8rD5DIP21cv7CgY3nL7AQ9CG5kWOIZS53zikeqmKZPfs+/Y9Q8udNslVmomSFkEFnKMsm6ye8e3eaBtPov0= tmplt@den-2016-06-26";
in
{
  dulcia = {
    deployment.targetHost = "192.168.2.77";
    imports =
      [ # Include the results of the hardware scan.
        ./hardware-configuration.nix
      ];

    # Use the GRUB 2 boot loader.
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    # boot.loader.grub.efiSupport = true;
    # boot.loader.grub.efiInstallAsRemovable = true;
    # boot.loader.efi.efiSysMountPoint = "/boot/efi";
    # Define on which hard drive you want to install Grub.
    boot.loader.grub.device = "/dev/disk/by-id/ata-INTEL_SSDSA2CW080G3_CVPR135202U4080BGN"; # or "nodev" for efi only
    boot.supportedFilesystems = [ "zfs" ];

    networking.hostName = "dulcia"; # Define your hostname.
    networking.hostId = "ff7870de";
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    fileSystems."/export/media" = {
      device = "/media";
      options = [ "bind" ];
    };

    # Select internationalisation properties.
    # i18n = {
    #   consoleFont = "Lat2-Terminus16";
    #   consoleKeyMap = "us";
    #   defaultLocale = "en_US.UTF-8";
    # };

    # Set your time zone.
    time.timeZone = "Europe/Stockholm";

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      wget vim zsh atool

      # VM stuff
      virtmanager
      qemu
      OVMF
      pciutils
    ];

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # programs.bash.enableCompletion = true;
    # programs.mtr.enable = true;
    # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

    # List services that you want to enable:

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;
    services.openssh.permitRootLogin = "yes";

    services.nfs.server.enable = true;
    services.nfs.server.exports = ''
      /export	 	temeraire(rw,sync,no_subtree_check,fsid=0)
      /export/media 	temeraire(rw,sync,no_subtree_check)

      /export             192.168.2.228(sync,no_subtree_check,fsid=0)
      /export/media       192.168.2.228(sync,no_subtree_check)
    '';

    services.zfs.autoScrub.enable = true;
    services.zfs.autoSnapshot = {
      enable = true;
      frequent = 8; # keep the latest eight 15-minute snapshorts
      monthly = 1; # keep only one monthly snapshot
    };


    # qemu/kvm
    users.groups.libvirtd.members = [ "root" "tmplt" ];
    virtualisation.libvirtd = {
      enable = true;
    };

    # Open ports in the firewall.
    networking.firewall.allowedTCPPorts = [ 2049 ];
    networking.firewall.allowedUDPPorts = [ 2049 ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;

    # Enable CUPS to print documents.
    # services.printing.enable = true;

    # Enable sound.
    # sound.enable = true;
    # hardware.pulseaudio.enable = true;

    # Enable the X11 windowing system.
    # services.xserver.enable = true;
    # services.xserver.layout = "us";
    # services.xserver.xkbOptions = "eurosign:e";

    # Enable touchpad support.
    # services.xserver.libinput.enable = true;

    # Enable the KDE Desktop Environment.
    # services.xserver.displayManager.sddm.enable = true;
    # services.xserver.desktopManager.plasma5.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.extraUsers.tmplt = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" ];
      shell = "/run/current-system/sw/bin/zsh";
      password = "password";
      openssh.authorizedKeys.keys = [ sshKey ];
    };

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    system.stateVersion = "18.03"; # Did you read the comment?
  };
}
