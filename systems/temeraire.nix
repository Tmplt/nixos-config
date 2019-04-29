{
  temeraire = { config, pkgs, ... }:
  {
    deployment.targetHost = "localhost";
    networking = {
      hostName = "temeraire";
      firewall.allowedTCPPorts = [ 8080 ];
    };

    imports = [
      ../hardware-configurations/temeraire.nix
      ../modules/pci-passthrough/pci-passthrough.nix
      ../common.nix
    ];

    nixpkgs.config.allowUnfree = true;

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

      kernelPackages = pkgs.linuxPackages_latest;
    };

    pciPassthrough = {
      enable = true;

      pciIDs = [
        "1002:687f" "1002:aaf8" # Radeon Vega 56
      ];

      periphiralPaths = [
        /dev/input/by-id/usb-La-VIEW_CO._QPAD_Gaming_Mouse-event-mouse
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

      xrandrHeads = [
        "HDMI-A-0"
        { output = "DVI-D-0"; primary = true; }
      ];
    };
  };
}