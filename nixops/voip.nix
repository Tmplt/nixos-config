{
  voip = {
    deployment.targetHost = "voip.campus.ltu.se";
    networking.hostName = "voip";
    time.timeZone = "Europe/Stockholm";

    imports = [
      <nixpkgs/nixos/modules/virtualisation/nova-config.nix>
      ./common.nix
    ];

    nixpkgs.config.allowUnfree = true;
    services.temspeak3.enable = true;
    networking.firewall = {
      allowedTCPPorts = [ 30033 10011 ];
      allowedUDPPorts = [ 9987 ];
    };
  };
}
