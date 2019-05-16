# This file contains the declaration of my user.
# It configures some user-specific files/services via home-manager.

{ config, lib, pkgs, ... }:

let
  onTemeraire = config.networking.hostName == "temeraire";
  onPerscitia = config.networking.hostName == "perscitia";
  secrets = import ./secrets;
  dotfiles = ./dotfiles;

  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "14a0dce9e809d222a85ad19aa7d3479cc104e475";
    ref = "release-19.03";
  };
in
{
  imports = [
    "${home-manager}/nixos"
    ./dotfiles.nix
  ];

  users.users.tmplt = {
    isNormalUser = true;
    uid = 1000;

    extraGroups = [
      "wheel" "dialout" "video" "audio" "input"
    ];

    shell = "${pkgs.zsh}/bin/zsh";

    # Don't forget to set an actual password with passwd(1).
    initialPassword = "password";
  };

  home-manager.users.tmplt = {
    manual.manpages.enable = true;

    #
    # Programs
    #

    programs.git = {
      enable = true;
      userName = "Tmplt";
      userEmail = "tmplt@dragons.rocks";
      signing.key = "0x4C2C6467";
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    programs.taskwarrior = {
      enable = true;

      config.taskd = let prefix = "\\/home\\/tmplt\\/nixops\\/secrets\\/task\\"; in {
        confirmation = false;
        # TODO: make it so this can take regular paths
        certificate = "${prefix}/public.cert";
        key = "${prefix}/private.key";
        ca = "${prefix}/ca.cert";
        server = "excidium.campus.ltu.se:53589";
        credentials = "personal\\/tmplt\\/${secrets.taskUID}";
      };
    };

    programs.ssh = {
      enable = true;
      compression = true;
      serverAliveInterval = 5;

      matchBlocks = secrets.sshHosts // {
        "*".identityFile = "~/.ssh/id_ecdsa";
        "github.com".identitiesOnly = true;
        "dulcia".hostname = "192.168.2.77";

        "kobo" = {
          hostname = "192.168.2.190";
          user = "root";
        };
      };
    };

    #
    # Services
    #

    services.random-background = {
      enable = onPerscitia;
      # TODO: package wallpapers?
      imageDirectory = "%h/wallpapers";
      interval = "3h";
    };

    services.unclutter.enable = true;

    services.gpg-agent = {
      enable = onTemeraire;

      defaultCacheTtl = 1800; # 30 min
      defaultCacheTtlSsh = 1800;
      enableSshSupport = true;
      grabKeyboardAndMouse = true;
      enableScDaemon = false;
    };

    services.redshift = {
      enable = true;
      latitude = "65.5841500";
      longitude = "22.1546500";
    };

    services.syncthing = {
      enable = true;
      tray = false;
    };

    services.dunst = {
      enable = true;

      settings.global = {
        follow = "mouse";
        indicate_hidden = true;
        transparency = 0;
        notification_height = 0;
        seperator_height = 2;
        padding = 8;
        horizontal_padding = 8;
        frame_width = 3;
        seperator_color = "auto";
        font = "Monospace 8";
        line_height = 0;
        markup = "full";
        format = "<b>%s</b>\n%b";
        alignment = "left";
        show_age_threshold = 60;
        word_wrap = true;
        ignore_newline = false;
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = true;
        icon_position = true;
        sticky_history = true;
        history_length = 20;
        title = "Dunst";
        class = "Dunst";
        startup_notification = false;
      };

      settings.shortcuts = {
        close = "ctrl+space";
        close_all = "ctrl+shift+space";
        history = "ctrl+grave";
        context = "ctrl+shift+period";
      };

      settings.urgency_low = {
        background = "#222222";
        foreground = "#888888";
        timeout = 10;
      };

      settings.urgency_normal = {
        background = "#285577";
        foreground = "#ffffff";
        timeout = 10;
      };

      settings.urgency_critical = {
        background = "#900000";
        foreground = "#ffffff";
        frame_color = "#ff0000";
        timeout = 0; # Never
      };
    };
  };
}
