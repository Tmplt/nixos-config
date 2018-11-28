{ config, lib, pkgs, ... }:

{
  imports = [
    ./local-configuration.nix
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

  users.users.tmplt = {
    isNormalUser = true;
    uid = 1000;

    extraGroups = [
      "wheel" "dialout" "video" "audio" "input"
    ];

    shell = "${pkgs.zsh}/bin/zsh";

    # Don't forget to set an actual password with passwd(1).
    initialPassword = "password";
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

  services.udev.extraRules = ''
    # Allow users to use the AVR avrisp2 programmer
    SUBSYSTEM=="usb", ATTR{idVendor}=="03eb", ATTR{idProduct}=="2104", TAG+="uaccess", RUN{builtin}+="uaccess"
  '';

  nix.buildCores = 0;
  nix.gc.automatic = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}
