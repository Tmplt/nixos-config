let
  sshKeys = import ../ssh-keys.nix;
in
{
  excidium = {
    deployment.targetHost = "excidium.campus.ltu.se";
    networking.hostName = "excidium";

    imports = [
      ../profiles/openstack-config.nix
      ../modules/webserver.nix
      ../common-server.nix
    ];

    users.users.tmplt.openssh.authorizedKeys.keys = [ sshKeys.mako sshKeys.tmplt ];

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
