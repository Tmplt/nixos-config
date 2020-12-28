# Declare common options for hands-on systems.

{ config, lib, pkgs, ... }:

let
  sshKeys = import ./ssh-keys.nix;
in
{
  imports = [
    ./tmplt.nix
    ./packages.nix
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

  # Setup a local SSH server for nixops to work.
  services.openssh = {
    enable = true;
    permitRootLogin = "without-password";
    passwordAuthentication = false;
    listenAddresses = [ { addr = "127.0.0.1"; port = 22; } ];
  };
  users.users.root.openssh.authorizedKeys.keys = [ sshKeys.tmplt ];

  # Make ~/Downloads a tmpfs, so I don't end up using is as a non-volatile 'whatever'-directory
  # XXX: find an alternative that does not utilize system memory
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

  programs.command-not-found.enable = true;

  systemd.coredump.enable = true;

  services.udisks2.enable = true;

  services.dictd.enable = true;

  services.tor = {
    enable = false;
    client.enable = true;
    client.dns.enable = true;
    controlPort = 9051;
  };

  # DNS over Tor
  services.dnsmasq = {
    enable = true;
  };

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
  in setWorldReadable [
    "0483:374b" "0483:3748" "0483:3752" # ST-LINK/V2.1 rev A/B/C+
    "15ba:002a" # ATM-USB-TINY-H JTAG interface
    "1366:1015" # SEGGER (JLink firmware)
  ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}
