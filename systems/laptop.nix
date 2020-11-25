{
  perscitia = { config, lib, pkgs, ... }:
  let
    secrets = (import ../secrets);

    nixos-hardware = fetchTarball {
      sha256 = "07mp73a5gyppv0cd08l1wdr8m5phfmbphsn6v7w7x54fa8p2ci6y";
      url = "https://github.com/NixOS/nixos-hardware/archive/40ade7c0349d31e9f9722c7331de3c473f65dce0.tar.gz";
    };
  in
  {
    deployment.targetHost = "localhost";
    networking.hostName = "perscitia";

    networking = {
      interfaces = {
        enp0s25.useDHCP = true;
        wlp3s0.useDHCP = true;
      };
    };

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

    fileSystems."/mnt/dulcia" = {
      device = "dulcia.localdomain:/rpool/media";
      fsType = "nfs";
      options = [
        "defaults" # XXX: is this causing us issues?
        "noexec"
        "noauto"
        "nofail"

        # Don't retry NFS requests indefinitely.
        # XXX: can cause data corruption, but its responsiveness I'm after.
        "soft"

        "timeo=1" # 0.1s before sending the next NFS request
        "retry=0"
        "retrans=10"

        "x-systemd.automount"
        "x-systemd.mount-timeout=1s"
      ];
    };

    boot.initrd.luks.devices.root = {
      name = "root";
      device = "/dev/disk/by-uuid/${lib.removeSuffix "\n" (builtins.readFile ../hardware-configurations/laptop-luks.uuid)}";
      preLVM = true;
      allowDiscards = true;
    };

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
        systems = [ "x86_64-linux" "aarch64-linux" ];
        maxJobs = 12;
        supportedFeatures = [ "big-parallel" ]; # build Linux
      }];

      # Builder has much faster Internet connection.
      extraOptions = ''
        builders-use-substitutes = true
      '';
    };

    programs.light.enable = true;

    programs.sway = {
      enable = true;
      extraPackages = with pkgs; [
        xwayland
        xorg.xrdb
        waybar
        swaylock
        swayidle

        mako
        kanshi
      ];
    };

    services.xserver.xkbVariant = "colemak";
    console.useXkbConfig = true;

    services.acpid.enable = true;

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

    systemd.extraConfig = ''
      DefaultTimeoutStopSec=30s
    '';

    powerManagement = {
      enable = true;
      powertop.enable = true;
    };

    services.udev.extraRules =
      # TODO: systemd-mount --umount --lazy?
      # TODO: kill all processes accessing files under mount?
      # /proc/*/fd | grep dulcia ...
      # Perhaps it would be easier to do in Python? Then we can do things like timeout before SIGKILL, etc.
      let undockScript = pkgs.writeShellScript "undock-script" ''
        ${pkgs.inetutils}/bin/logger -t DOCKING "Detected condition: undocked"
        ${pkgs.inetutils}/bin/logger -t DOCKING "TODO: kill pulseaudio, or rescan to find DAC again."
        ${pkgs.inetutils}/bin/logger -t DOCKING "TODO: SIGTERM all procs using files under /home/tmplt/dulcia, timeout to SIGKILL"
        ${pkgs.inetutils}/bin/logger -t DOCKING "TODO: systemd-mount --umount /home/tmplt/dulcia"
      ''; in
      let dockScript = pkgs.writeShellScript "dock-script" ''
        ${pkgs.inetutils}/bin/logger -t DOCKING "Detected condition: docked"
        ${pkgs.inetutils}/bin/logger -t DOCKING "TODO: systemctl start home-tmplt-dulcia.mount"
      ''; in
    # Shutdown system on low battery level to prevents fs corruption
    ''
      KERNEL=="BAT0" \
      , SUBSYSTEM=="power_supply" \
      , ATTR{status}=="Discharging" \
      , ATTR{capacity}=="[0-5]" \
      , RUN+="${pkgs.systemd}/bin/systemctl poweroff"
    ''
    # Automagically change monitor setup
    + ''
      SUBSYSTEM=="platform", ENV{EVENT}=="undock", RUN+="${undockScript}"
      SUBSYSTEM=="platform", ENV{EVENT}=="dock", RUN+="${dockScript}"
    '';
  };
}

