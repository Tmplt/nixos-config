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
    rev = "bb5c29107e355ce0db61197df03c8b2c67cb1c8f";
    # TODO: check sha256?
  };
in
{
  imports = [
    "${home-manager}/nixos"
    ./dotfiles.nix
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

    # XXX: can only be set if X session is managed by HM <https://github.com/rycee/home-manager/issues/307>
    # home.sessionVariables = {
    #   BROWSER = if onPerscitia then "qutebrowser" else "firefox";
    # };

    programs.zsh = {
      enable = true;

      history.expireDuplicatesFirst = true;

      initExtra = ''
        setopt interactivecomments
        setopt nonomatch # forward wildcard if no match
        unsetopt correct # don't guess my misspellings

        # Change default zim location
        # TODO: nixify
        export ZIM_HOME=''${ZDOTDIR:-''${HOME}}/.zim

        # Start zim
        [[ -s ''${ZIM_HOME}/init.zsh ]] && source ''${ZIM_HOME}/init.zsh

        # source direnv
        eval "$(direnv hook zsh)"

        mkcd() {
          mkdir -p "$1" && cd "$1"
        }
      '';

      shellAliases = {
        xsel = "xsel -b";
        cpr = "rsync -ahX --info=progress2";
        e = "nvim";
        pls = "sudo $(fc -ln -1)"; # Run previous command as sudo
        ll = "exa --long --group-directories-first";
        mkdir = "mkdir -p";
        ag = "ag --color --color-line-number '0;35' --color-match '46;30' --color-path '4;36'";
        rock = "ncmpcpp";
        disks = "echo '╓───── m o u n t . p o i n t s'; echo '╙────────────────────────────────────── ─ ─ '; lsblk -a; echo ''; echo '╓───── d i s k . u s a g e'; echo '╙────────────────────────────────────── ─ ─ '; df -h;";
        ren = "ranger";
        wtf = "dmesg | tail -n 50";
        ytdl = "youtube-dl --output '%(uploader)s - %(title)s.%(ext)s'";
        tzat = "tzathura &>/dev/null";
        virsh = "virsh -c qemu:///system";
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

    programs.autorandr = {
      enable = onPerscitia;
      profiles = {
        "mobile" = {
          fingerprint = {
            LVDS-1 = "00ffffffffffff0006af3e210000000021140104901f11780261959c59528f2621505400000001010101010101010101010101010101f82a409a61840c30402a330035ae10000018a51c409a61840c30402a330035ae10000018000000fe0041554f0a202020202020202020000000fe004231343052573032205631200a00d0";
          };
          config.LVDS-1 = {
            enable = true;
            mode = "1600x900";
            rate = "60";
            primary = true;
          };
        };

        "docked" = {
          fingerprint = {
            LVDS-1 = "00ffffffffffff0006af3e210000000021140104901f11780261959c59528f2621505400000001010101010101010101010101010101f82a409a61840c30402a330035ae10000018a51c409a61840c30402a330035ae10000018000000fe0041554f0a202020202020202020000000fe004231343052573032205631200a00d0";
            VGA-1 = "00ffffffffffff004c2d390838313130011601030e3420782a01f1a257529f270a5054bfef80714f8100814081809500950fa940b300283c80a070b023403020360006442100001a000000fd00384b1e5111000a202020202020000000fc00534d533234413435300a202020000000ff0048344d433130313433370a202000b2";
          };
          config = {
            LVDS-1 = {
              enable = true;
              mode = "1600x900";
              rate = "60";
              primary = true;
              position = "${toString (1920 / 2 - 1600 / 2)}x1200";
            };
            VGA-1 = {
              enable = true;
              mode = "1920x1200";
              rate = "60";
              primary = false;
            };
          };
        };
      };

      hooks.postswitch = {
        "restart-xmonad" = "xmonad --restart";
        "change-background" = "${pkgs.feh}/bin/feh --bg-fill -z ~/wallpapers/";
      };
    };

    #
    # Services
    #

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
