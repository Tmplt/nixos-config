let
  sshKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJYN8rD5DIP21cv7CgY3nL7AQ9CG5kWOIZS53zikeqmKZPfs+/Y9Q8udNslVmomSFkEFnKMsm6ye8e3eaBtPov0= tmplt@den-2016-06-26";
in
{
  excidium = {
    deployment.targetHost = "excidium.campus.ltu.se";
    networking.hostName = "excidium";
    time.timeZone = "Europe/Stockholm";
    nix.gc.automatic = true;

    imports = [
      <nixpkgs/nixos/modules/virtualisation/nova-config.nix>
      ./modules/webserver.nix
    ];

    users.extraUsers.tmplt = {
      createHome = true;
      extraGroups = [ "wheel" ];
      isNormalUser = true;
      openssh.authorizedKeys.keys = [ sshKey ];
    };

    services.openssh = {
      passwordAuthentication = false;
    };

    services.syncthing.enable = true;

    services.taskserver = {
      enable = true;
      fqdn = "excidium.campus.ltu.se";
      listenHost = "::";
      organisations.personal.users = [ "tmplt" ];

      pki.auto.expiration = {
        ca = 365;
        client = 365;
        crl = 365;
        server = 365;
      };
    };
  };

  network.description = "example network";
}
