{
  praecursoris = {
    deployment.targetHost = "praecursoris.campus.ltu.se";
    time.timeZone = "Europe/Stockholm";

    imports = [
      ../hardware-configurations/praecursoris.nix
      <nixpkgs/nixos/modules/profiles/headless.nix>
      ../common-server.nix
    ];

    networking = {
      hostName = "praecursoris";
      hostId = "61ceb5ac";

      interfaces.enp4s0.ipv4.addresses = [{
        address = "130.240.202.140";
        prefixLength = 24;
      }];

      defaultGateway = "130.240.202.1";
      nameservers = [ "130.240.16.8" ];
    };

    boot.loader.grub = {
      enable = true;
      version = 2;
      devices = [ "/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd" ];
    };
    boot.supportedFilesystems = [ "zfs" ];

    services.syncthing.enable = true;

    system.stateVersion = "19.09";
  };
}
