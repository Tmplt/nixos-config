# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/bd3e002b-8dcb-435b-ae27-ae444a4d41a6";
      fsType = "xfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/4978-87C8";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/2ab176d9-222c-4c24-98a4-02f4073add44"; }
    ];

  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}