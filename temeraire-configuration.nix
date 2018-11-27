# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  cpuset = pkgs.python2Packages.buildPythonApplication rec {
    name = "cpuset-${version}";
    version = "1.5.7";

    src = pkgs.fetchurl {
      url = "https://github.com/lpechacek/cpuset/archive/v1.5.7.tar.gz";
      sha256 = "32334e164415ed5aec83c5ffc3dc01c418406eb02d96d881fdfd495587ff0c01";
    };

    # Required for shield creation on this machine
    patches = [ ./patches/cpuset-fix-shield.patch ];

    doCheck = false;
  };

  qemuHookFile = ./hooks/qemu;
  hugepagesSizeFile = ./hooks/vm-mem-requirements;
  qemuHookEnv = pkgs.buildEnv {
    name = "qemu-hook-env";
    paths = with pkgs; [
      bash
      cpuset
      coreutils
      gnugrep
      procps # for sysctl(8)
      python # for calculating hugepages
      gawk
    ];
  };
in
{

  nixpkgs.config.allowUnfree = true;

  imports =
    [ # Include the results of the hardware scan.
      ./temeraire-hardware-configuration.nix
      (import ./packages.nix { inherit config pkgs lib; })
      ./pci-passthrough.nix
    ];

  # TODO: move this to pci-passthrough
  systemd.services.libvirtd.path = [ qemuHookEnv ];
  systemd.services.libvirtd.preStart = ''
    # source ${pkgs.stdenv}/setup

    mkdir -p /var/lib/libvirt/hooks
    chmod 755 /var/lib/libvirt/hooks

    # Copy hook files
    # substituteAll ${qemuHookFile} /var/lib/libvirt/hooks/qemu
    cp -f ${qemuHookFile} /var/lib/libvirt/hooks/qemu
    # cp -f ${hugepagesSizeFile} /var/lib/libvirt/hooks/vm-mem-requirements

    # Make them executable
    chmod +x /var/lib/libvirt/hooks/qemu
    # chmod +x /var/lib/libvirt/hooks/vm-mem-requirements
  '';

  # Allow me to login and have the required Pulseaudio daemon start before
  # running the domains that require it.
  systemd.services.libvirt-guests.preStart = ''
    ${pkgs.coreutils}/bin/coreutils --coreutils-prog=sleep 10
  '';

  virtualisation.libvirtd.onShutdown = "suspend";

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    cleanTmpDir = true;

    # Enable IOMMU and fix IOMMU-groups for this particular system.
    # Bind the vfio drivers to devices that are going to be passed though.
    # You might need to block whatever drivers they use.
    blacklistedKernelModules = [ "nouveau" "nvidia" "r8169" ];
    kernelPatches = [ {
      name = "add-acs-overrides";
      patch = ./patches/add-acs-overrides.patch;
    } ];

    initrd.kernelModules = [ "dm_cache" "dm_cache_smq" ];

    # Fix LVM caches working on startup
    # <https://github.com/NixOS/nixpkgs/issues/15516>
    initrd.extraUtilsCommands = ''
      for BIN in ${pkgs.thin-provisioning-tools}/bin/*; do
        copy_bin_and_libs $BIN
        SRC="(?<all>/[a-zA-Z0-9/]+/[0-9a-z]{32}-[0-9a-z-.]+(?<exe>/bin/$(basename $BIN)))"
        REP="\"$out\" . \$+{exe} . \"\\x0\" x (length(\$+{all}) - length(\"$out\" . \$+{exe}))"
        PRP="s,$SRC,$REP,ge"
        ${pkgs.perl}/bin/perl -p -i -e "$PRP" $out/bin/lvm
      done
    '';
    initrd.extraUtilsCommandsTest = ''
      $out/bin/pdata_tools cache_check -V
    '';
  };

  pciPassthrough = {
    enable = true;
    pciIDs = "10de:13c2,10de:0fbb,10ec:8186";
    libvirtUsers = [ "tmplt" ];
    qemuUser = "tmplt";
  };

  fileSystems."/home/tmplt/media" = {
    device = "dulcia:/media";
    fsType = "nfs";
    options = ["x-systemd.automount" "noauto" "x-systemd.idle-timeout=1min" "x-systemd.device-timeout=175" "timeo=15"];
  };

  fileSystems."/home/tmplt/Downloads" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["rw" "size=2G" "uid=1000" "nodev" "nosuid"];
  };

  # fileSystems."/mnt/volatile/tv-series" = {
  #   device = "192.168.1.77:/mnt/volatile";
  #   fsType = "nfs";
  #   options = ["x-systemd.automount,noauto"];
  # };

  # fileSystems."/home/tmplt/watch" = {
  #   device = "192.168.1.77:/mnt/main/apps/rtorrent/watch";
  #   fsType = "nfs";
  #   options = ["x-systemd.automount,noauto"];
  # };

  # TODO: move this to pci-passthrough.nix
  fileSystems."/dev/hugepages" = {
    device = "hugetlbfs";
    fsType = "hugetlbfs";
    options = ["defaults"];
  };

  fileSystems."/home/tmplt/vidya" = {
    device = "/dev/pool/linux-extra";
    fsType = "xfs";
  };


  networking = {
    hostName = "temeraire"; # Define your hostname.
  };

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim git
  ];

  # Open ports in the firewall.
  # TODO: what are these for?
  networking.firewall.allowedTCPPorts = [ 6600 ];
  networking.firewall.allowedUDPPorts = [ 6600 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware = {
    pulseaudio = {
      enable = true;
      support32Bit = true;

      # Don't mute audio streams when Teamspeak's running.
      extraConfig = ''
        unload-module module-role-cork
      '';

      daemon.config = {
        flat-volumes = "no";
        resample-method = "speex-float-5";
        default-sample-format = "s32le";
        default-sample-rate = 384000;
      };
    };
    opengl.driSupport32Bit = true;
  };

  # Update Intel microcode on boot
  hardware.cpu.intel.updateMicrocode = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.tmplt = {
    isNormalUser = true;
    uid = 1000;

    extraGroups = [
      "wheel" "dialout" "video" "audio" "input"
    ];

    createHome = true;
    home = "/home/tmplt";
    shell = "/run/current-system/sw/bin/zsh";
    password = "password";
  };

  programs = {
    zsh = {
      enable = true; # required for command-not-found to work
      enableCompletion = true;
    };

    command-not-found.enable = true;
  };

  systemd.coredump.enable = true;
  systemd.coredump.extraConfig = "Storage=external";

  services = {
    udisks2.enable = true;

    xserver = {
      enable = true;
      autorun = true;

      # These make everything so much better
      autoRepeatDelay = 300;
      autoRepeatInterval = 35;

      videoDrivers = [ "amdgpu" ];
      deviceSection = ''
        Option "TearFree" "true"
      '';

      # From left to right, Hammerhead setup
      xrandrHeads = [
        "HDMI-A-0"
        { output = "DisplayPort-2"; primary = true; }
        "DVI-D-0"
      ];
    };

    dnsmasq.enable = true;
  };

  services.compton = {
      enable = true;

      shadow = false;
      shadowOffsets = [ (-2) (-2) ];
      shadowOpacity = "0.60";

      fade = true;
      fadeDelta = 20;
      fadeSteps = [ "0.12" "1.0" ];

      vSync = "none";
      backend = "glx";

      extraOptions = ''
        no-dnd-shadow        = true;
        no-dock-shadow       = true;
        clear-shadow         = true;
        shadow-ignore-shaped = true;
      '';
  };

  services.mysql = {
    enable = true;
    package = pkgs.mysql;
  };

  nix.buildCores = 0; # Uses nproc(1) to query core count
  nix.gc.automatic = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?

}
