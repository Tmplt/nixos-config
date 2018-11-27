{ config, pkgs, lib, ... }:

with lib; let cfg = config.pciPassthrough;
  edge = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/master.tar.gz) { };

  cpuset = pkgs.python2Packages.buildPythonApplication rec {
    name = "cpuset-${version}";
    version = "1.5.7";

    src = pkgs.fetchurl {
      url = "https://github.com/lpechacek/cpuset/archive/v1.5.7.tar.gz";
      sha256 = "32334e164415ed5aec83c5ffc3dc01c418406eb02d96d881fdfd495587ff0c01";
    };

    # Required for shield creation on this machine
    patches = [ ./patches/cpuset-fix-shield.patch ];

    doCheck = false;
  };

  qemuHookEnv = pkgs.buildEnv {
    name = "qemu-hook-env";
    paths = with pkgs; [
      bash
      cpuset
      coreutils
      gnugrep
      procps # for sysctl(8)
      python # for calculating hugepages
      gawk
    ];
  };
in
{
  ###### interface
  options.pciPassthrough = {
    enable = mkEnableOption "PCI Passthrough";

    cpuType = mkOption {
      description = "One of `intel` or `amd`";
      default = "intel";
      type = types.str;
    };

    pciIDs = mkOption {
      description = "Comma-separated list of PCI IDs to pass-through";
      type = types.str;
    };

    libvirtUsers = mkOption {
      description = "Extra users to add to libvirtd (root is already included)";
      type = types.listOf types.str;
      default = [];
    };

    qemuUser = mkOption {
      description = "User to run QEmu as";
      type = types.str;
      default = "root";
    };
  };

  ###### implementation
  config = (mkIf cfg.enable {

    boot.kernelParams = [
      "pcie_acs_override=downstream"
      "${cfg.cpuType}_iommu=on"
    ];

    # These modules are required for PCI passthrough, and must come before early modesetting stuff
    boot.kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];

    boot.extraModprobeConfig ="options vfio-pci ids=${cfg.pciIDs}";

    environment.systemPackages = with pkgs; [
      virtmanager
      qemu
      OVMF
      pciutils
    ];

    users.groups.libvirtd.members = [ "root" ] ++ cfg.libvirtUsers;

    virtualisation.libvirtd = {
      enable = true;

      qemuPackage = ((pkgs.qemu.overrideAttrs (old: {
        version = "2.12.1";
        src = pkgs.fetchurl {
          url = "https://download.qemu.org/qemu-2.12.1.tar.xz";
          sha256 = "33583800e0006cd00b78226b85be5a27c8e3b156bed2e60e83ecbeb7b9b8364f";
        };

        patches = [
          # Some yet-to-be-merged audio fixes. Highly recommended.
          ./patches/qemu-sound-improvements-2.12.0.patch
          ./patches/qemu-no-etc-install.patch
        ];
      })).override {
        hostCpuOnly = true;
      });

      qemuVerbatimConfig = ''
        user = "${cfg.qemuUser}"
        nvram = [
        "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd"
        ]
        cgroup_device_acl = [
          "/dev/input/by-id/usb-Laview_Technology_Mionix_Naos_7000_STM32-event-mouse",
          "/dev/input/by-id/usb-04d9_USB_Keyboard-event-kbd",
          "/dev/input/by-id/usb-04d9_USB_Keyboard-event-if01",
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
          "/dev/rtc","/dev/hpet", "/dev/vfio/vfio"
        ]
      '';

    };

    systemd.services.libvirtd.path = [ qemuHookEnv ];

  });

}
