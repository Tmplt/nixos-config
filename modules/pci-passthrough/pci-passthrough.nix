# This file configures prerequisites for creating a libvirt/qemu/KVM/terms VM with GPU-passthrough.

{ config, pkgs, lib, ... }:

with lib; let cfg = config.pciPassthrough;
  cpuset = pkgs.python2Packages.buildPythonApplication rec {
    name = "cpuset-patched-${version}";
    version = "1.5.7";

    src = pkgs.fetchurl {
      url = "https://github.com/lpechacek/cpuset/archive/v1.5.7.tar.gz";
      sha256 = "32334e164415ed5aec83c5ffc3dc01c418406eb02d96d881fdfd495587ff0c01";
    };

    # Required for shield creation on this machine
    patches = [ ./patches/cpuset-fix-shield.patch ];

    doCheck = false;
  };

  qemuPatched = ((pkgs.qemu.overrideAttrs (old: {
    version = "4.0.0";
    name = "qemu-4.0.0";

    src = pkgs.fetchgit {
      url = "https://github.com/spheenik/qemu";
      branchName = "4.0-glorious";
      sha256 = "12bgznn29p8rnjxd4fd8rpclzv9vvd6vp21gv7vjgvphj8s55q9n";
    };

    patches = [ ./patches/qemu-no-etc-install.patch ];

  })).override {
    hostCpuOnly = true;
  });

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

  qemuHookFile = ./hooks/qemu;
  hugepagesSizeFile = ./hooks/vm-mem-requirements;
  vidyaConfig = domains/vidya.xml;
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
      description = "List of PCI IDs to pass through";
      type = types.listOf types.str;
    };

    periphiralPaths = mkOption {
      description = "List of paths to hardware periphirals to pass though";
      type = types.listOf types.path;
      default = [];
    };

    blacklistedKernelModules = mkOption {
      description = "List of blacklisted kernel modules";
      default = [];
      type = types.listOf types.str;
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

    boot = {
      # Fix IOMMU groups for this particular system.
      kernelPatches = [
        {
          name = "add-acs-overrides";
          patch = ./patches/add-acs-overrides.patch;
        }
        {
          name = "fix-vega-reset";
          patch = ./patches/fix-vega-reset.patch;
        }
      ];

      kernelParams = [
        "pcie_acs_override=downstream"
        "${cfg.cpuType}_iommu=on"
        "iommu=pt"
        "kvm.ignore_msrs=1"
        "vfio_iommu_type1.allow_unsafe_interrupts=1"
      ];

      # Enable required IOMMU modules.
      kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
        "vfio_virqfd"
      ];

      # Bind the vfio drivers to the devices that are going to be passed though.
      extraModprobeConfig = "options vfio-pci ids=${lib.concatStringsSep "," cfg.pciIDs} disable_idle_d3=1";

      # Blocklist their drivers, telling Linux we don't want to use them on the host.
      blacklistedKernelModules = cfg.blacklistedKernelModules;
    };

    environment.systemPackages = with pkgs; [
      virtmanager
      gnome3.dconf  # so that virtmanager remembers remote servers
    ];

    users.groups.libvirtd.members = [ "root" ] ++ cfg.libvirtUsers;

    # Enable dynamic hugepages
    fileSystems."/dev/hugepages" = {
      device = "hugetlbfs";
      fsType = "hugetlbfs";
      options = ["defaults"];
    };

    virtualisation.libvirtd = {
      enable = true;
      qemuPackage = qemuPatched;
      onShutdown = "suspend";

      qemuVerbatimConfig = let
        periphirals = toString (map (e: "\"" + toString e + "\",\n") cfg.periphiralPaths);
      in ''
        user = "${cfg.qemuUser}"
        nvram = [
          "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd"
        ]
        cgroup_device_acl = [
          ${periphirals}
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
          "/dev/rtc","/dev/hpet", "/dev/vfio/vfio"
        ]
      '';

    };

    # Install qemu hook
    systemd.services.libvirtd.preStart =
      # XXX: Disgusting hack that allows me to login and kick Pulseaudio alive before
      # qemu starts looking for it, in case the guest wasn't shutdown before the host was.
      #
      # Thread on the issue: <https://discourse.nixos.org/t/resuming-libvirt-guests-after-pulseaudio-units/1048/6>
      # TODO: make it so guests must be manually started instead?
      ''
      ${pkgs.coreutils}/bin/coreutils --coreutils-prog=sleep 10
      '' +
      # TODO: calculate hugepage size instead of hard coding it.
      ''
      # source ${pkgs.stdenv}/setup

      mkdir -p /var/lib/libvirt/hooks
      chmod 755 /var/lib/libvirt/hooks

      # Copy hook files
      # substituteAll ${qemuHookFile} /var/lib/libvirt/hooks/qemu
      cp -f ${qemuHookFile} /var/lib/libvirt/hooks/qemu
      # cp -f ${hugepagesSizeFile} /var/lib/libvirt/hooks/vm-mem-requirements

      # Make them executable
      chmod +x /var/lib/libvirt/hooks/qemu
      # chmod +x /var/lib/libvirt/hooks/vm-mem-requirements
    '';

    systemd.services.libvirtd.path = [ qemuHookEnv ];

    # Import VM configuration:
    # TODO: mustn't this be run before libvirt-guests.service, in case domain isn't defined?
    systemd.user.services.libvirt-import = {
      description = "Oneshot importer of libvirt domains";
      wantedBy = [ "multi-user.target" ];

      serviceConfig.ExecStart = "${pkgs.libvirt}/bin/virsh -c qemu:///system define ${vidyaConfig} --validate";

      restartIfChanged = false;
    };
  });
}
