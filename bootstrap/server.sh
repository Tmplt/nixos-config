#!/usr/bin/env bash
#
# Setup script for / on ZFS with 2-drive redundancy; drive data is RAIDZ2 (RAID 6),
# boot partition is mirrored across the start of all drives. After a `nixos-generate-config`,
# 
#    boot.loader.grub = {
#      enable = true;
#      version = 2;
#      devices = [ "#{sda}" "${sdb}" "${sdc}" "${sdd}" ];
#    };
#    boot.supportedFilesystems = [ "zfs" ];
#
# should be added to the system configuration (EFI-only system will differ). ZFS pools may
# fail to import on first boot: enter recovery, forcibly import them, and reboot.

set -euox pipefail

sda="/dev/disk/by-id/ata-WDC_WD20EZRZ-00Z5HB0_WD-WCC4N""2ZJDY8R"
sdb="/dev/disk/by-id/ata-WDC_WD20EZRZ-00Z5HB0_WD-WCC4N""2ZJDLRK"
sdc="/dev/disk/by-id/ata-WDC_WD20EZRZ-00Z5HB0_WD-WCC4N""5VVS651"
sdd="/dev/disk/by-id/ata-WDC_WD20EZRZ-00Z5HB0_WD-WCC4N""2ZJDCSR"

sgdisk --zap-all ${sda}
sgdisk --zap-all ${sdb}
sgdisk --zap-all ${sdc}
sgdisk --zap-all ${sdd}

sgdisk --set-alignment=1 -n 1:24K:+1000K -t 1:EF02 ${sda} # legacy (BIOS) boot
sgdisk                   -n 2:1M:+512M   -t 2:EF00 ${sda} # UEFI boot
sgdisk                   -n 3:0:+1G      -t 3:BF01 ${sda} # boot pool
sgdisk                   -n 4:0:0        -t 4:BF01 ${sda} # remainder for ZFS

# Copy the partition table to the other disks
sfdisk --dump ${sda} | sfdisk ${sdb}
sfdisk --dump ${sda} | sfdisk ${sdc}
sfdisk --dump ${sda} | sfdisk ${sdd}

# Create the boot pool
zpool create -o ashift=12 -d -f \
      -o feature@async_destroy=enabled \
      -o feature@bookmarks=enabled \
      -o feature@embedded_data=enabled \
      -o feature@empty_bpobj=enabled \
      -o feature@enabled_txg=enabled \
      -o feature@extensible_dataset=enabled \
      -o feature@filesystem_limits=enabled \
      -o feature@hole_birth=enabled \
      -o feature@large_blocks=enabled \
      -o feature@lz4_compress=enabled \
      -o feature@spacemap_histogram=enabled \
      -o feature@userobj_accounting=enabled \
      -O acltype=posixacl -O canmount=off -O compression=lz4 -O devices=off \
      -O normalization=formD -O relatime=on -O xattr=sa \
      -o altroot=/mnt/boot \
      bpool mirror ${sda}-part3 ${sdb}-part3 ${sdc}-part3 ${sdd}-part3

# Create the root pool
zpool create -o ashift=12 -f \
    -o altroot=/mnt \
    -O acltype=posixacl \
    -O xattr=sa \
    -O relatime=on \
    rpool raidz2 ${sda}-part4 ${sdb}-part4 ${sdc}-part4 ${sdd}-part4

# Create the file systems
zfs create -o mountpoint=none rpool/root
zfs create -o mountpoint=none bpool/boot
zfs create -o mountpoint=legacy bpool/boot/nixos
zfs create -o mountpoint=legacy rpool/root/nixos
zfs create -o mountpoint=legacy rpool/home
zfs set compression=lz4 rpool # compress the whole pool

# Create and use a swap partition
zfs create -V 8G -b $(getconf PAGESIZE) \
    -o logbias=throughput -o sync=always \
    -o primarycache=metadata \
    -o com.sun:auto-snapshot=false rpool/swap
mkswap -f /dev/zvol/rpool/swap
swapon /dev/zvol/rpool/swap

# Mount the file systems manually
mount -t zfs rpool/root/nixos /mnt
mkdir /mnt/home
mount -t zfs rpool/home /mnt/home
mkdir /mnt/boot
mount -t zfs bpool/boot/nixos /mnt/boot
