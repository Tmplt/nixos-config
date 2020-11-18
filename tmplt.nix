# This file contains the declaration of my user.
# It configures some user-specific files/services via home-manager.

{ config, lib, pkgs, ... }:

let
  secrets = import ./secrets;

  home-manager = let
    json = builtins.fromJSON (builtins.readFile ./pkgs-revs/home-manager.json);
  in (import <nixpkgs> {}).pkgs.fetchFromGitHub {
    inherit (json) rev sha256;
    owner = "rycee";
    repo = "home-manager";
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

        define() {
          dict -d english $1 | less --quit-if-one-screen
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
        e = "emacsclient -t";
        pls = "sudo $(fc -ln -1)"; # Run previous command as sudo
        ll = "ls -lh";
        mkdir = "mkdir -p";
        rock = "ncmpcpp";
        disks = "echo '╓───── m o u n t . p o i n t s'; echo '╙────────────────────────────────────── ─ ─ '; lsblk -a; echo ''; echo '╓───── d i s k . u s a g e'; echo '╙────────────────────────────────────── ─ ─ '; df -h;";
        wtf = "dmesg | tail -n 50";
        ytdl = "youtube-dl --output '%(uploader)s - %(title)s.%(ext)s'";
        zathura = "zathura --fork";
      };

      sessionVariables = {
        ALTERNATE_EDITOR = "";  # start emacs server on connect if not already running
        EDITOR = "emacsclient -t";
        VISUAL = "emacsclient -c -a emacs";
        BROWSER = "qutebrowser";
      };
    };

    programs.git = {
      enable = true;
      userName = "tmplt";
      userEmail = "v@tmplt.dev";
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
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

    programs.autorandr = let
      laptopEDID = "00ffffffffffff0030e4d8020000000000160103801c1078ea8855995b558f261d505400000001010101010101010101010101010101601d56d85000183030404700159c1000001b000000000000000000000000000000000000000000fe004c4720446973706c61790a2020000000fe004c503132355748322d534c42330059";
      dockedEDID = "00ffffffffffff00232f9b040000000028150103a53c2278226fb1a7554c9e250c505400000001010101010101010101010101010101565e00a0a0a029503020350055502100001a000000fc004455414c2d4456490a20202020000000fc000a202020202020202020202020000000fc000a2020202020202020202020200012";
    in {
      enable = false;           # TODO: port to sway
      profiles = {
        "mobile" = {
          fingerprint.LVDS-1 = laptopEDID;
          config = {
            VGA-1.enable = false;
            HDMI-1.enable = false;
            DP-1.enable = false;
            DP-2.enable = false;

            LVDS-1 = {
              enable = true;
              mode = "1366x768";
            };
          };

        };

        "docked" = {
          fingerprint.LVDS-1 = laptopEDID;
          fingerprint.DP-2 = dockedEDID;
          config = {
            VGA-1.enable = false;
            HDMI-1.enable = false;
            DP-1.enable = false;

            LVDS-1 = {
              enable = true;
              mode = "1366x768";
            };

            DP-2 = {
              enable = true;
              position = "1367x0";
              mode = "2560x1440";
            };
          };
        };
      };

      hooks.postswitch = {
        "change-background" = "${pkgs.systemd}/bin/systemctl --user start random-background";
        # TODO: change different xmonad modes depending on monitor layout
      };
    };

    #
    # Services
    #

    systemd.user.services.offlineimap = {
      Unit = {
        Description = "Offlineimap Service";
        Documentation = "man:offlineimap(1)";
      };

      Service = {
        ExecStart = "${pkgs.bash}/bin/bash -c \'PATH=${pkgs.mu}/bin:$PATH ${pkgs.offlineimap}/bin/offlineimap -u basic\'";
        Restart = "on-failure";
        RestartSec = 60;
      };

      Install.WantedBy = [ "default.target" ];
    };

    services.mpd = {
      enable = true;
      musicDirectory = "/home/tmplt/dulcia/music";
      extraConfig = ''
        audio_output {
                type    "pulse"
                name    "Local pulseaudio output"
        }
      '';
    };

    xdg = {
      userDirs = {
        enable = true;
        download = "\$HOME/tmp";
      };

      mimeApps = {
        enable = true;
        defaultApplications = {
          "application/pdf" = [ "org.pwmt.zathura.desktop" ];
          "x-scheme-handler/https" = [ "qutebrowser.desktop" ];
          "x-scheme-handler/http" = [ "qutebrowser.desktop" ];
          "image/png" = [ "sxiv.desktop" ];
          "image/jpeg" = [ "sxiv.desktop" ];
        };
      };
    };

    home.keyboard = {
      layout = "us,us";
      options = [ "caps:ctrl_modifier" "compose:prsc" "grp:rctrl_toggle" ];
      variant = "colemak,";
    };

    services.random-background = {
      enable = false;           # TODO: port to sway
      # TODO: package wallpapers?
      imageDirectory = "%h/wallpapers";
      interval = "3h";
    };

    services.gpg-agent = {
      enable = false;

      defaultCacheTtl = 1800; # 30 min
      defaultCacheTtlSsh = 1800;
      enableSshSupport = true;
      grabKeyboardAndMouse = true;
      enableScDaemon = false;
    };

    services.redshift = {
      enable = false;           # TODO: change to gammastep
      latitude = "65.5841500";
      longitude = "22.1546500";
    };

    services.syncthing = {
      enable = true;
      tray = false;
    };

    services.dunst = {
      enable = false;           # TODO: change to mako

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
