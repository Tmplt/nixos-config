# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;

  imports =
    [ # Include the results of the hardware scan.
      ./temeraire-hardware-configuration.nix
      modules/pci-passthrough/pci-passthrough.nix
    ];

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

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

    pciIDs = [
      "10de:13c2" "10de:0fbb" # GPU
      "10ec:8186" # NIC
    ];
    blacklistedKernelModules = [
      "nouveau" "nvidia" # GPU
      "r8169" # NIC
    ];

    periphiralPaths = [
      /dev/input/by-id/usb-Laview_Technology_Mionix_Naos_7000_STM32-event-mouse
      /dev/input/by-id/usb-04d9_USB_Keyboard-event-kbd
      /dev/input/by-id/usb-04d9_USB_Keyboard-event-if01
    ];

    libvirtUsers = [ "tmplt" ];
    qemuUser = "tmplt";
  };

  fileSystems."/home/tmplt/media" = {
    device = "dulcia:/media";
    fsType = "nfs";
    options = ["x-systemd.automount" "noauto" "x-systemd.idle-timeout=1min" "x-systemd.device-timeout=175" "timeo=15"];
  };

  fileSystems."/home/tmplt/vidya" = {
    device = "/dev/pool/linux-extra";
    fsType = "xfs";
  };

  networking.hostName = "temeraire";

  hardware.pulseaudio = {
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

  services.xserver = {
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
}
