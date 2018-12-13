{ config, lib, pkgs, ... }:

{
  imports = [
    ./local-configuration.nix
    ./tmplt.nix
    (import ./packages.nix {inherit config pkgs; })
  ];

  time.timeZone = "Europe/Stockholm";
  sound.enable = true;
  boot.cleanTmpDir = true;

  hardware = {
    # Update Intel microcode on boot (both systems use Intel)
    cpu.intel.updateMicrocode = true;

    pulseaudio = {
      enable = true;
      support32Bit = true;
    };

    opengl = {
      driSupport = true;
      driSupport32Bit = true;
    };
  };

  # Make ~/Downloads a tmpfs, so I don't end up using is as a non-volatile 'whatever'-directory
  # XXX: is this stored in RAM?
  fileSystems."/home/tmplt/Downloads" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "rw" "size=2G" "uid=tmplt" ];
  };

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
    };

    command-not-found.enable = true;
  };

  # `coredumpctl gdb` can't find dumps unless they are external.
  systemd.coredump.enable = true;
  systemd.coredump.extraConfig = "Storage=external";

  services.udisks2.enable = true;
  services.dnsmasq.enable = true;

  services.xserver = {
    enable = true;
    autorun = true;

    autoRepeatDelay = 300;
    autoRepeatInterval = 35;
  };

  services.mysql = {
    enable = true;
    package = pkgs.mysql;
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

  # Allow some USB devices to be accessed without root privelages.
  services.udev.extraRules = with lib; let
    toUdevRule = vid: pid: ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="${vid}", ATTR{idProduct}=="${pid}", TAG+="uaccess", RUN{builtin}+="uaccess" MODE:="0666"
    '';
    setWorldReadable = idPairs:
      concatStrings (map (x: let l = splitString ":" x; in toUdevRule (head l) (last l)) idPairs);
  in setWorldReadable [
    "0483:374b" "0483:3748" # ST-LINK/V2.1 rev A/B/C+
    "15ba:002a" # ATM-USB-TINY-H JTAG interface
  ];

  nix.buildCores = 0;
  nix.gc.automatic = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}
