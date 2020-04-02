{
  perscitia = { config, lib, pkgs, ... }:
  let
    secrets = (import ../secrets);

    nixos-hardware = fetchTarball {
      sha256 = "1l9h3knw1rz2kl03cv9736i0j79lrfmsq1j2f56pflb00rbzj956";
      url = "https://github.com/NixOS/nixos-hardware/archive/34f24f248033d6418da82f12b3872d5f5401a310.tar.gz";
    };

    uuid = lib.removeSuffix "\n" (builtins.readFile ../hardware-configurations/laptop-luks.uuid);
  in
  {
    deployment.targetHost = "localhost";
    networking.hostName = "perscitia";

    networking.interfaces.enp0s25.useDHCP = true;

    imports = [
      ../hardware-configurations/laptop.nix
      "${nixos-hardware}/lenovo/thinkpad/x230"
      ../common.nix
      ../wlan.nix
    ];

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

    fileSystems."/home/tmplt/dulcia" = {
      device = "dulcia.localdomain:/rpool/media";
      fsType = "nfs";
      options = [
        "_netdev" # we depend on network access
        "defaults"
        "noexec"
        "noauto" # dont mount until accessed
        "timeo=15" # 1.5s before sending the next NFS request
        "x-systemd.automount"
        "x-systemd.mount-timeout=30s"
        "x-systemd.idle-timeout=30s" # dismount after 30s idle
      ];
    };

    boot.initrd.luks.devices = [
      {
        name = "root";
        device = "/dev/disk/by-uuid/${uuid}";
        preLVM = true;
        allowDiscards = true;
      }
    ];

    hardware.trackpoint = {
      emulateWheel = true;
      enable = true;
    };

    nix = {
      distributedBuilds = true;
      buildMachines = [{
        hostName = "tmplt.dev";
        sshUser = "builder";
        sshKey = "/home/tmplt/.ssh/id_builder";
        system = "x86_64-linux";
        maxJobs = 12;
        supportedFeatures = [
          "kvm"
          "nixos-test"
          "big-parallel"
          "benchmark"
        ];
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

      lockOn.suspend = true;
      lockOn.extraTargets = [ "systemd-suspend-then-hibernate.service" ];

      # While already encrypted (so needless, really), it is not obvious that the system is entering hiberation without this enabled.
      # (Framebuffer isn't cleared; the system appears unresponsive for a few seconds.)
      lockOn.hibernate = true;
    };

    environment.etc."systemd/sleep.conf".text = "HibernateDelaySec=1h";
    services.logind = {
      lidSwitch = "suspend-then-hibernate";
      lidSwitchDocked = "suspend-then-hibernate";

      # See logind.conf(5).
      extraConfig = ''
        HandleSuspendKey=ignore
        handleHibernateKey=hibernate

        PowerKeyIgnoreInhibited=yes
        SuspendKeyIgnoreInhibited=yes
        HibernateKeyIgnoreInhibited=yes
        LidSwitchIgnoreInhibited=yes
      '';
    };

    systemd.services.fetch-mail = {
      description = "Periodically fetch email with offlineimap(1)";
      serviceConfig.Type = "simple";
      serviceConfig.User = "tmplt";
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      startAt = "*:0/5";

      path = with pkgs; [ offlineimap notmuch torsocks ];
      script = ''
        torsocks offlineimap
      '';
    };

    systemd.extraConfig = ''
      DefaultTimeoutStopSec=30s
    '';

    powerManagement = {
      enable = true;
      powertop.enable = true;
    };

    services.udev.extraRules =
    # Shutdown system on low battery level
    ''
      KERNEL=="BAT0" \
      , SUBSYSTEM=="power_supply" \
      , ATTR{status}=="Discharging" \
      , ATTR{capacity}=="[0-5]" \
      , RUN+="${pkgs.systemd}/bin/systemctl poweroff"
    ''
    # Automagically change monitor setup
    + ''
      SUBSYSTEM=="platform" \
      , ENV{EVENT}=="*dock" \
      , RUN+="${pkgs.autorandr}/bin/autorandr --change --batch"
    '';
  };
}

