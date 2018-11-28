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
        psk = secrets."WiiVafan";
      };

      "Normandy SR2" = {
        psk = secrets."Normandy SR2";
        priority = 10;
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

  programs = {
    light.enable = true;
    wireshark.enable = true;
  };

  services = {
    xserver = {
      layout = "se";
      xkbOptions = "ctrl:swapcaps";

      libinput = {
        enable = true;
        accelProfile = "flat"; # No acceleration
        disableWhileTyping = true;
        tapping = false; # Disable tap-to-click behavior.
        middleEmulation = false; # Don't emulate middle-click by pressing left and right button simultaneously.
        scrollMethod = "twofinger";
      };

      multitouch.ignorePalm = true;
    };

    acpid.enable = true;

    physlock = {
      enable = true;
      allowAnyUser = true;

      # While already encrypted, it is now obvious that the system is entering hiberation without this enabled.
      # (Framebuffer isn't cleared; the system appears unresponsive for a few seconds.)
      lockOn.hibernate = true;
    };

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
}

