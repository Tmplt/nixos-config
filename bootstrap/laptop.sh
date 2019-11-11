# Automagically partitions passed in disk for symetrical LUKS encryption and UEFI boot,
# installs nixos.
# TODO:
# * chroot into installation as tmplt
# * clone nixos-config recursively
# * replace hardware-configurations/perscitia.nix
# * make sure the previous boot.initrd.luks.devices entry is updated (use a dedicated file for holding the uuid).

set -euox pipefail

if [[ $# < 1 ]]; then
    echo "usage:" $0 "<block device>"
    exit 1
fi
sda="$1"

sgdisk --zap-all ${sda}

sgdisk --new=1:0:+500M --typecode=1:EF00 ${sda} # EFI
sgdisk --new=2:0:0     --typecode=2:8300 ${sda} # LVM

# Setup the encrypted LUKS partition and open it
cryptsetup luksFormat ${sda}-part2
cryptsetup luksOpen ${sda}-part2 enc-pv

# Create two logical volumes: 8G of swap, remainder for /
pvcreate /dev/mapper/enc-pv
vgcreate vg /dev/mapper/enc-pv
lvcreate -L 8G -n swap vg
lvcreate -l '100%FREE' -n root vg

# Format the partitions
mkfs.fat ${sda}-part1
mkfs.xfs -L root /dev/vg/root
mkswap -L swap /dev/vg/swap

# Mount the partitions
mount /dev/vg/root /mnt
mkdir /mnt/boot
mount ${sda}-part1 /mnt/boot
swapon /dev/vg/swap

# Generate and modify configuration
nixos-generate-config --root /mnt

# Get UUID of encrypted root
uuid=$(blkid ${sda}-part2 | awk '{gsub(/"/, "", $2); gsub(/UUID=/, "", $2); print $2;}')

mv /mnt/etc/nixos/{configuration.nix,generated.nix}

cat << EOF > /mnt/etc/nixos/configuration.nix
{ config, pkgs, ... }:

{
  imports = [
    ./generated.nix
  ];

  boot.initrd.luks.devices = [
    {
      name = "root";
      device = "/dev/disk/by-uuid/${uuid}";
      preLVM = true;
      allowDiscards = true;
    }
  ];

  networking.hostName = "perscitia";
  networking.wireless.enable = true;

  users.users.tmplt = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "password";
  };

  # Setup a local-only SSH server for nixops to work
  services.openssh = {
    enable = true;
    permitRootLogin = "without-password";
    passwordAuthentication = false;
    listenAddresses = [ { addr = "127.0.0.1"; port = 22; } ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJYN8rD5DIP21cv7CgY3nL7AQ9CG5kWOIZS53zikeqmKZPfs+/Y9Q8udNslVmomSFkEFnKMsm6ye8e3eaBtPov0= tmplt@den-2016-06-26"
  ];
}
# Yes, the empy line below is required

EOF

nixos-install

# TODO: clone nixos-config repo to /home/tmplt/nixos-config
