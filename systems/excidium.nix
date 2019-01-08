{
  excidium = {
    deployment.targetHost = "excidium.campus.ltu.se";
    networking.hostName = "excidium";
    nix.gc.automatic = true;

    imports = [
      <nixpkgs/nixos/modules/virtualisation/nova-config.nix>
      ../modules/webserver.nix
      ../common-server.nix
    ];

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
}
