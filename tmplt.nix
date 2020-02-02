# This file contains the declaration of my user.
# It configures some user-specific files/services via home-manager.

{ config, lib, pkgs, ... }:

let
  secrets = import ./secrets;

  home-manager = (import <nixpkgs> {}).fetchFromGitHub {
    owner = "rycee";
    repo = "home-manager";
    rev = "bb5c29107e355ce0db61197df03c8b2c67cb1c8f";
    sha256 = "1b05kvcfmdbshjdc74ilqvfkln46sp6qvzsi0rjarm694462975b";
  };

  vim-plug = (import <nixpkgs> {}).pkgs.fetchFromGitHub {
    owner = "junegunn";
    repo = "vim-plug";
    rev = "0.10.0";
    sha256 = "11x10l75q6k4z67yyk5ll25fqpgb2ma88vplrakw3k41g79xn9d9";
  };

  zimfw = (import <nixpkgs> {}).pkgs.fetchFromGitHub {
    owner = "zimfw";
    repo = "zimfw";
    rev = "d19c8dde68b338fcc096bbce683c47ad068b46d3";
    fetchSubmodules = true;
    sha256 = "0cry0w6hvxb7m4bkrkgcr029w79j5lqsafml265wfvx0sr53x7va";
  };
in
{
  imports = [
    "${home-manager}/nixos"
    ./editor.nix
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

    home.file = {
    ".zim".source = "${zimfw}";
    ".local/share/nvim/site/autoload/plug.vim".source = "${vim-plug}/plug.vim";
    };

    programs.zsh = {
      enable = true;

      history = {
        expireDuplicatesFirst = true;
        extended = true;
      };

      initExtra = ''
        setopt interactivecomments
        setopt nonomatch # forward wildcard if no match
        unsetopt correct # don't guess my misspellings

        # Change default zim location
        # TODO: nixify
        export ZIM_HOME=''${ZDOTDIR:-''${HOME}}/.zim

        # Start zim
        [[ -s ''${ZIM_HOME}/init.zsh ]] && source ''${ZIM_HOME}/init.zsh

        mkcd() {
          mkdir -p "$1" && cd "$1"
        }
      '';

      plugins = [ rec {
        name = "zsh-z";
        src = pkgs.fetchFromGitHub {
          owner = "agkozak";
          repo = name;
          rev = "41439755cf06f35e8bee8dffe04f728384905077";
          sha256 = "1dzxbcif9q5m5zx3gvrhrfmkxspzf7b81k837gdb93c4aasgh6x6";
        };
      }];

      shellAliases = {
        xsel = "xsel -b";
        e = "nvim";
        pls = "sudo $(fc -ln -1)"; # Run previous command as sudo
        ll = "exa --long --group-directories-first";
        mkdir = "mkdir -p";
        rock = "ncmpcpp";
        disks = "echo '╓───── m o u n t . p o i n t s'; echo '╙────────────────────────────────────── ─ ─ '; lsblk -a; echo ''; echo '╓───── d i s k . u s a g e'; echo '╙────────────────────────────────────── ─ ─ '; df -h;";
        ren = "ranger";
        wtf = "dmesg | tail -n 50";
        ytdl = "youtube-dl --output '%(uploader)s - %(title)s.%(ext)s'";
        zathura = "zathura --fork";
      };

      sessionVariables = {
        EDITOR = "nvim";
        SUDO_EDITOR = "nvim";
        VISUAL = "nvim";
        SYSTEMD_EDITOR = "nvim";
        BROWSER = "qutebrowser";
        # PATH = "$PATH:$HOME/bin:$HOME/.cargo/bin";
        SKELPATH = "$HOME/.config/skeletons/";
      };
    };

    programs.git = {
      enable = true;
      userName = "tmplt";
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
        server = "praecursoris.campus.ltu.se:53589";
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

        "builder" = {
          hostname = "tmplt.dev";
          user = "builder";
          identityFile = "~/.ssh/id_builder";
        };
      };
    };

    #
    # Services
    #

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = [ "org.pwmt.zathura.desktop" ];
        "x-scheme-handler/https" = [ "qutebrowser.desktop" ];
        "x-scheme-handler/http" = [ "qutebrowser.desktop" ];
        "image/png" = [ "sxiv.desktop" ];
        "image/jpeg" = [ "sxiv.desktop" ];
      };
    };

    xdg.userDirs = {
      enable = true;
      download = "\$HOME/tmp";
    };

    home.keyboard = {
      layout = "us,us";
      options = [ "ctrl:swapcaps" "compose:menu" "grp:rctrl_toggle" ];
      variant = ",colemak";
    };

    xsession = {
      enable = true;
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = self: [ self.xmobar ];
      };

      initExtra = ''
        ${pkgs.xorg.xsetroot}/bin/xset -cursor_name left_ptr
        ${pkgs.wmname}/bin/wmname LD3D
      '';
    };

    services.random-background = {
      enable = true;
      # TODO: package wallpapers?
      imageDirectory = "%h/wallpapers";
      interval = "3h";
    };

    services.unclutter.enable = true;

    services.gpg-agent = {
      enable = false;

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
