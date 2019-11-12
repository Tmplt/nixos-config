{
  temeraire = { config, pkgs, ... }:
  {
    deployment.targetHost = "localhost";
    networking = {
      hostName = "temeraire";
      firewall.allowedTCPPorts = [ 8080 ];
    };

    imports = [
      ../hardware-configurations/desktop.nix
      ../modules/pci-passthrough/pci-passthrough.nix
      ../common.nix
    ];

    nixpkgs.config.allowUnfree = true;

    boot = {
      # Use the systemd-boot EFI boot loader.
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };

    pciPassthrough = {
      enable = true;

      pciIDs = [
        "1002:687f" "1002:aaf8" # Radeon Vega 56
        "10ec:8168" # NIC
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
        {
          output = "HDMI-A-0";
          monitorConfig = ''
            Option "Position" "0 0"
            Option "Rotate" "left"
            Option "PreferredMode" "1920x1080"
          '';
        }

        {
          output = "DVI-D-0";
          primary = true;
          monitorConfig = ''
            Option "Position" "1080 ${toString ((1920 - 1440) / 2)}"
            Option "Rotate" "normal"
            Option "PreferredMode" "2560x1440"
          '';
        }
      ];

      layout = "us";
      xkbModel = "hhk";
      xkbVariant = "colemak";
      xkbOptions = "compose:rwin";

      displayManager.sessionCommands = ''
        ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr
        ${pkgs.wmname}/bin/wmname LG3D
        ${pkgs.mpd}/bin/mpd &disown
      '';

      desktopManager.xterm.enable = false;
      windowManager.default = "bspwm";
      windowManager.bspwm = {
        enable = true;
      };
    };
  };
}
