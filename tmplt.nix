# This file contains the declaration of my user.
# It configures some user-specific files/services via home-manager.

{ config, lib, pkgs, ... }:

let
  onTemeraire = config.networking.hostName == "temeraire";
in
{
  imports = [
    "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos"
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
    home.file.".config/mpv/scripts/youtube-quality.lua".source = ./misc/youtube-quality.lua;
    home.file.".config/mpv/scripts/youtube-quality.conf".source = ./misc/youtube-quality.conf;

    xsession = {
      enable = true;

      windowManager.command = if onTemeraire then ''
        ~/.xlayout
        mpd &
        ${pkgs.bspwm}/bin/bspwm
      '' else ''
        ${pkgs.bspwm}/bin/bspwm
      '';

      initExtra = ''
        ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr
      '';
    };

    manual.manpages.enable = true;

    home.keyboard.layout = if onTemeraire then "en" else "se";

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

      config.taskd = {
        confirmation = false;
        # TODO: make it so this can take regular paths
        certificate = "\\/home\\/tmplt\\/.task\\/keys\\/public.cert";
        key = "\\/home\\/tmplt\\/.task\\/keys\\/private.key";
        ca = "\\/home\\/tmplt\\/.task\\/keys\\/ca.cert";
        server = "excidium.campus.ltu.se:53589";
        credentials = "personal\\/tmplt\\/f98b48c2-f191-4b36-a93a-dad6aba2c0a7";
      };
    };

    #
    # Services
    #

    services.random-background = {
      enable = !onTemeraire;
      # TODO: package wallpapers?
      imageDirectory = "%h/wallpapers";
      interval = "3h";
    };

    services.unclutter.enable = true;

    services.gpg-agent = {
      enable = true;

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
