# Declare wlan configuration for mobile devices.

{ config, lib, pkgs, ... }:

let
  secrets = (import ./secrets);
  networkSecrets = secrets.networkCredentials;
in
{
  networking.wireless = {
    enable = true;
    userControlled.enable = true;
  };

  environment.systemPackages = with pkgs; [
    wpa_supplicant_gui
  ];

  networking.wireless.networks = secrets.networkConfigs // {
      "WiiVafan" = {
        psk = networkSecrets."WiiVafan";
      };

      "COMHEM_9cfcd4-5G" = {
        psk = networkSecrets."COMHEM_9cfcd4-5G";
      };

      "Tele2Gateway59D6" = {
        psk = networkSecrets."Tele2Gateway59D6";
      };

      "Normandy SR2" = {
        psk = networkSecrets."Normandy SR2";
        priority = 10;
      };

      "#Telia-5A1580" = {
        psk = networkSecrets."#Telia-5A1580";
        priority = 10;
      };

      # ":(){ :|:& };:" = {
      #   psk = networkSecrets."ludd";
      #   priority = 10;
      # };

      "eduroam" = {
        priority = 5;
        auth = ''
          key_mgmt=WPA-EAP
          eap=PEAP
          proto=RSN
          identity="${networkSecrets."eduroam".username}"
          password="${networkSecrets."eduroam".password}"
          phase2="auth=MSCHAPV2"
        '';
      };
  };
}
