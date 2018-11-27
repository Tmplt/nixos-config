let
  sshKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJYN8rD5DIP21cv7CgY3nL7AQ9CG5kWOIZS53zikeqmKZPfs+/Y9Q8udNslVmomSFkEFnKMsm6ye8e3eaBtPov0= tmplt@den-2016-06-26";
in
{
  voip = {
    deployment.targetHost = "voip.campus.ltu.se";
    networking.hostName = "voip";
    time.timeZone = "Europe/Stockholm";
    nix.gc.automatic = true;

    imports = [
      <nixpkgs/nixos/modules/virtualisation/nova-config.nix>
    ];

    nixpkgs.config.allowUnfree = true;
    services.temspeak3.enable = true;
    networking.firewall = {
      allowedTCPPorts = [ 30033 10011 ];
      allowedUDPPorts = [ 9987 ];
    };

    users.extraUsers.tmplt = {
      createHome = true;
      extraGroups = [ "wheel" ];
      isNormalUser = true;
      openssh.authorizedKeys.keys = [ sshKey ];
    };

    services.openssh = {
      passwordAuthentication = false;
    };
  };
}
