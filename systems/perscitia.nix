let
  secrets = (import ../secrets);
in
{
  perscitia = { config, pkgs, ... }:
  {
    deployment.targetHost = "localhost";
    networking.hostName = "perscitia";

    imports = [
      ../hardware-configurations/perscitia.nix
      <nixos-hardware/lenovo/thinkpad/t430>
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

    programs.light.enable = true;

    services.xserver = {
      layout = "us";
      xkbOptions = "ctrl:swapcaps,compose:menu";

      libinput = {
        enable = true;
        accelProfile = "flat"; # No acceleration
        disableWhileTyping = true;
        tapping = false; # Disable tap-to-click behavior.
        middleEmulation = false; # Don't emulate middle-click by pressing left and right button simultaneously.
        scrollMethod = "twofinger";
      };

      multitouch.ignorePalm = true;

      displayManager.sessionCommands = ''
        ${pkgs.xorg.xsetroot}/bin/xset -cursor_name left_ptr
        ${pkgs.wmname}/bin/wmname LG3D
      '';

      desktopManager.xterm.enable = false;
      windowManager.default = "xmonad";
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = haskellPackages: [
          haskellPackages.xmobar
        ];
      };
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

    powerManagement = {
      enable = true;
      powertop.enable = true;

      # Properly recover VPN connection from hibernation/sleep.
      resumeCommands = "${pkgs.systemd}/bin/systemctl restart openvpn-*.service";
    };
  };
}

