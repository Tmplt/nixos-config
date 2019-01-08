# TODO: create enable option for this!
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "dragons.rocks" = {
        locations."/".root = "/var/www/dragons.rocks";
        forceSSL = true;
        enableACME = true;
      };
      "www.dragons.rocks" = {
        locations."/".extraConfig = "return 301 $scheme://dragons.rocks$request_uri;";
        forceSSL = true;
        enableACME = true;
      };
    };
  };
}
