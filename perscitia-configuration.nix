# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  secrets = (import ./secrets.nix);
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./perscitia-hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  # fileSystems."/home/tmplt/media" = {
  #   device = "/dev/disk/by-partlabel/media";
  #   fsType = "xfs";
  #   options = [ "x-systemd.automount,noauto" ];
  # };

  fileSystems."/home/tmplt/Downloads" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["rw" "size=2G" "uid=tmplt"];
  };

  boot.cleanTmpDir = true;

  boot.initrd.luks.devices = [
    {
      name = "root";
      device = "/dev/disk/by-uuid/09d22890-005e-447d-959b-a52f0feb430b";
      preLVM = true;
      allowDiscards = true;
    }
  ];

  users.groups.libvirtd.members = [ "root" "tmplt" ];
  virtualisation.libvirtd.enable = false;

  networking = {
    hostName = "perscitia";
    wireless.enable = true;
    wireless.userControlled.enable = true;

    wireless.networks = {
      "WiiVafan" = {
        psk = secrets.WiiVafan;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    wpa_supplicant_gui
  ];

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "sv-latin1";
    defaultLocale = "en_US.UTF-8";
  };

  hardware = {
    opengl.driSupport = true;
    pulseaudio.enable = true;
    opengl.driSupport32Bit = true;
    pulseaudio.support32Bit = true;

    trackpoint = {
      emulateWheel = true;
      enable = true;
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  users.extraUsers.tmplt = {
    isNormalUser = true;
    uid = 1000;

    extraGroups = [
      "video" "wheel" "disk" "audio" "networkmanager" "systemd-journal" "vboxusers" "dialout"
    ];

    createHome = true;
    home = "/home/tmplt";
    shell = "/run/current-system/sw/bin/zsh";
    password = "password";
  };

  programs = {
    zsh = {
      enableCompletion = true;

      # Required for command-not-found (e.g. source /etc/zshrc) to work.
      enable = true;
    };

    light.enable = true;
    command-not-found.enable = true;
    wireshark.enable = true;
  };

  sound.enable = true;

  systemd.coredump.enable = true;
  systemd.coredump.extraConfig = "Storage=external";

  services = {
    udisks2.enable = true;

    xserver = {
      enable = true;
      autorun = true;
      layout = "se";
      xkbOptions = "ctrl:swapcaps";

      # These make everything so much better.
      autoRepeatDelay = 300;
      autoRepeatInterval = 35;

      libinput = {
        enable = true;
        accelProfile = "flat"; # No acceleration
        disableWhileTyping = true;
        tapping = false; # Disable tap-to-click behavior.
        middleEmulation = false; # Don't emulate middle-click by pressing left and right button simultaneously.
        scrollMethod = "twofinger";
      };

      multitouch.ignorePalm = true;

      displayManager.lightdm = {
        enable = true;
      };

      # desktopManager.plasma5.enable = true;
    };

    acpid.enable = true;

    physlock.enable = true;

    udev.extraRules = ''
      # Allow users to use the AVR avrisp2 programmer
      SUBSYSTEM=="usb", ATTR{idVendor}=="03eb", ATTR{idProduct}=="2104", TAG+="uaccess", RUN{builtin}+="uaccess"
    '';

    # See logind.conf(5).
    # To actually shutdown, use poweroff(8)
    logind.extraConfig = ''
      HandlePowerKey=hibernate
      HandleSuspendKey=ignore
      handleHibernateKey=hibernate
      HandleLidSwitch=suspend
      HandleLidSwitchDocked=ignore

      PowerKeyIgnoreInhibited=yes
      SuspendKeyIgnoreInhibited=yes
      HibernateKeyIgnoreInhibited=yes
      LidSwitchIgnoreInhibited=yes
    '';
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # Allow non-root to run physlock.
  # TODO: Have services.physlock.allowNonRoot been pushed?
  # Suggested change by infinisil on #nixos
  security.wrappers.physlock = {
    source = "${pkgs.physlock}/bin/physlock";
    user = "root";
  };

  security.wrappers.hibernate = {
    source = "${pkgs.hibernate}/bin/hibernate";
    user = "root";
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    buildCores = 4; # How can we use nproc here instead?
    maxJobs = 2;
    daemonNiceLevel = 19;
    daemonIONiceLevel = 7;
    useSandbox = false;

    extraOptions = ''
      gc-keep-outputs = true
      gc-keep-derivations = true
    '';
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?

}

