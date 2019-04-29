let
  secrets = (import ../secrets.nix);
in
{
  perscitia = { config, pkgs, ... }:
  {
    deployment.targetHost = "localhost";
    networking = {
      hostName = "perscitia";
      wireless.enable = true;
      wireless.userControlled.enable = true;
    };

    imports = [
      ../hardware-configurations/perscitia.nix
      <nixos-hardware/lenovo/thinkpad/t430>
      ../common.nix
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

    networking.wireless.networks = let
      networkSecrets = secrets.networkCredentials;
    in secrets.networkConfigs // {
        "WiiVafan" = {
          psk = networkSecrets."WiiVafan";
        };

        "COMHEM_9cfcd4-5G" = {
          psk = networkSecrets."COMHEM_9cfcd4-5G";
        };

        "Tele2Gateway59D6" = {
          psk = networkSecrets."Tele2Gateway59D6";
        };

        "Normandy SR2" = {
          psk = networkSecrets."Normandy SR2";
          priority = 10;
        };

        "'; DROP TABLE ludd" = {
          psk = networkSecrets."ludd";
          priority = 10;
        };

        "eduroam" = {
          priority = 5;
          auth = ''
            key_mgmt=WPA-EAP
            eap=PEAP
            proto=RSN
            identity="${networkSecrets."eduroam".username}"
            password="${networkSecrets."eduroam".password}"
            phase2="auth=MSCHAPV2"
          '';
        };
    };

    environment.systemPackages = with pkgs; [
      wpa_supplicant_gui
    ];

    i18n = {
      consoleFont = "Lat2-Terminus16";
      consoleKeyMap = "sv-latin1";
      defaultLocale = "en_US.UTF-8";
    };

    hardware.trackpoint = {
      emulateWheel = true;
      enable = true;
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

    services.openvpn.servers = secrets.openvpnConfigs;

    powerManagement = {
      enable = true;
      powertop.enable = true;

      # Properly recover VPN connection from hibernation/sleep.
      resumeCommands = "${pkgs.systemd}/bin/systemctl restart openvpn-*.service";
    };

    nix.buildMachines = [{
      hostName = "builder";
      system = "x86_64-linux";
      maxJobs = 4;
      speedFactor = 2;
      supportedFeatures = ["big-parallel" "kvm"];
    }];
    nix.distributedBuilds = true;
    # Builder most likely has a faster Internet connection
    nix.extraOptions = ''
      builders-use-substitutes = true
    '';
  };
}
