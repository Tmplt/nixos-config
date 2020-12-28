{
  perscitia = { config, lib, pkgs, ... }:
  let
    secrets = (import ../secrets);

    # TODO use a channel instead
    nixos-hardware = fetchTarball {
      sha256 = "07mp73a5gyppv0cd08l1wdr8m5phfmbphsn6v7w7x54fa8p2ci6y";
      url = "https://github.com/NixOS/nixos-hardware/archive/40ade7c0349d31e9f9722c7331de3c473f65dce0.tar.gz";
    };
  in
  {
    deployment.targetHost = "localhost";
    networking.hostName = "perscitia";

    time.timeZone = "Europe/Stockholm";
    sound.enable = true;
    boot.cleanTmpDir = true;

    hardware = {
      # Update Intel microcode on boot (both systems use Intel)
      cpu.intel.updateMicrocode = true;

      pulseaudio = {
        enable = true;
        support32Bit = true;

        # Don't mute audio streams when VOIP programs are running.
        extraConfig = ''
          unload-module module-role-cork
        '';
      };

      opengl = {
        enable = true;            # required by sway
        driSupport = true;
        driSupport32Bit = true;
      };
    };

    networking = {
      interfaces = {
        enp0s25.useDHCP = true;
        wlp3s0.useDHCP = true;
      };

      firewall.allowedUDPPorts = [ 7667 ]; # lcm
    };

    imports = [
      ./hardware-configurations/laptop.nix
      ./wlan.nix
      ./email.nix
      ./tmplt.nix
      ./packages.nix
    ];

    # Make the default download directory a tmpfs, so I don't end up
    # using it as a non-volatile dir for whatever.
    #
    fileSystems."/home/tmplt/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "rw" "size=20%" "uid=tmplt" ];
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;

      # `compinit` is called in the user configuration. Don't call it twice.
      enableGlobalCompInit = false;
    };

    environment.etc = {
      "nix/pins/cacert".source = pkgs.cacert;
      "nix/pins/mu".source = pkgs.mu;
    };

    systemd.coredump.enable = true;
    services.udisks2.enable = true;
    services.dictd.enable = true;
    services.dnsmasq.enable = true;

    # Fix for USB redirection in virt-manager(1).
    security.wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice_gtk}/bin/spice-client-glib-usb-acl-helper";
    environment.systemPackages = with pkgs; [ spice_gtk ];

    # Allow some USB devices to be accessed without root privelages.
    services.udev.extraRules = with lib; let
      toUdevRule = vid: pid: ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="${vid}", ATTR{idProduct}=="${pid}", TAG+="uaccess", RUN{builtin}+="uaccess" MODE:="0666"
    '';
      setWorldReadable = idPairs:
        concatStrings (map (x: let l = splitString ":" x; in toUdevRule (head l) (last l)) idPairs);
    in (setWorldReadable [
      "0483:374b" "0483:3748" "0483:3752" # ST-LINK/V2.1 rev A/B/C+
      "15ba:002a" # ATM-USB-TINY-H JTAG interface
      "1366:1015" # SEGGER (JLink firmware)
      "0403:6014" # FT232H
    ]) +
    # Shutdown system on low battery level to prevents fs corruption
    ''
      KERNEL=="BAT0" \
      , SUBSYSTEM=="power_supply" \
      , ATTR{status}=="Discharging" \
      , ATTR{capacity}=="[0-5]" \
      , RUN+="${pkgs.systemd}/bin/systemctl poweroff"
    '';

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
      device = "/dev/disk/by-uuid/${lib.removeSuffix "\n" (builtins.readFile ./hardware-configurations/laptop-luks.uuid)}";
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

    services.xserver = {
      enable = false;
      windowManager.stumpwm.enable = true;
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
  };

  system.stateVersion = "18.03";
}
