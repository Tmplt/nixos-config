{
  perscitia = { config, pkgs, ... }:
  let
    secrets = (import ../secrets);

    nixos-hardware = fetchTarball {
      sha256 = "1l9h3knw1rz2kl03cv9736i0j79lrfmsq1j2f56pflb00rbzj956";
      url = "https://github.com/NixOS/nixos-hardware/archive/34f24f248033d6418da82f12b3872d5f5401a310.tar.gz";
    };
  in
  {
    deployment.targetHost = "localhost";
    networking.hostName = "perscitia";

    imports = [
      ../hardware-configurations/perscitia.nix
      "${nixos-hardware}/lenovo/thinkpad/t430"
      ../common.nix
      ../wlan.nix
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

    hardware.trackpoint = {
      emulateWheel = true;
      enable = true;
    };

    nix = {
      distributedBuilds = true;
      buildMachines = [{
        hostName = "praecursoris.campus.ltu.se";
        sshUser = "builder";
        sshKey = "/home/tmplt/.ssh/id_builder";
        system = "x86_64-linux";
        maxJobs = 4;
      }];

      # Builder has much faster Internet connection.
      extraOptions = ''
        builders-use-substitutes = true
      '';
    };

    programs.light.enable = true;

    services.xserver = {
      enable = true;

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

    services.acpid.enable = true;

    services.physlock = {
      enable = true;
      allowAnyUser = true;

      # While already encrypted, it is now obvious that the system is entering hiberation without this enabled.
      # (Framebuffer isn't cleared; the system appears unresponsive for a few seconds.)
      lockOn.hibernate = true;
    };

    # See logind.conf(5).
    # To actually shutdown, use poweroff(8)
    services.logind.extraConfig = ''
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

    services.openvpn.servers = secrets.openvpnConfigs;

    systemd.services.fetch-mail = {
      description = "Periodically fetch email with offlineimap(1)";
      serviceConfig.Type = "oneshot";
      serviceConfig.User = "tmplt";
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      startAt = "*:0/15";

      path = with pkgs; [ offlineimap notmuch ];
      script = ''
        offlineimap
      '';
    };

    systemd.extraConfig = ''
      DefaultTimeoutStopSec=30s
    '';

    powerManagement = {
      enable = true;
      powertop.enable = true;

      # Properly recover VPN connection from hibernation/sleep.
      resumeCommands = "${pkgs.systemd}/bin/systemctl restart openvpn-*.service";
    };
  };
}

