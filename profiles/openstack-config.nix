# Ad-hoc patch to the openstack-config virtualisation profile.
{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/openstack-config.nix>
  ];

  # Either broken on used host or Amazon-specific. Either case, all declarations set their hostname.
  # Otherwise used to ask Openstack for the hostname.
  systemd.services.openstack-init.script = ''
    exit 0
  '';
}
