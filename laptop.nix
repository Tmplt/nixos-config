{
  perscitia = { config, lib, pkgs, ... }:
    let
      secrets = import ./secrets;

      # TODO deprecate
      zimfw = (import <nixpkgs> { }).pkgs.fetchFromGitHub {
        owner = "zimfw";
        repo = "zimfw";
        rev = "d19c8dde68b338fcc096bbce683c47ad068b46d3";
        fetchSubmodules = true;
        sha256 = "0cry0w6hvxb7m4bkrkgcr029w79j5lqsafml265wfvx0sr53x7va";
      };
    in {
      imports = [
        <nixos-hardware/lenovo/thinkpad/x220>
        <home-manager/nixos>
        ./hardware-configurations/laptop.nix
        ./wlan.nix
        ./packages.nix
        ./adhoc.nix
      ];

      # Basic options

      fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];
      # Configure unlock for the encrypted root (/) partition.
      boot.initrd.luks.devices.root = {
        name = "root";
        device = "/dev/disk/by-uuid/${
            lib.removeSuffix "\n"
            (builtins.readFile ./hardware-configurations/laptop-luks.uuid)
          }";
        preLVM = true;
        allowDiscards = true;
      };
      boot.loader.systemd-boot.enable = true;

      hardware = {
        pulseaudio.enable = true;
        # Don't mute audio streams when VOIP programs are running.
        pulseaudio.extraConfig = ''
          unload-module module-role-cork
        '';

        trackpoint.enable = true;
        trackpoint.emulateWheel = false;
      };

      deployment.targetHost = "localhost"; # for compatibility with nixops

      networking.hostName = "perscitia";
      networking.useDHCP = true;
      time.timeZone = "Europe/Stockholm";
      sound.enable = true;

      # User options

      users.extraUsers.tmplt = {
        description = "Viktor Sonsten";
        isNormalUser = true;
        uid = 1000; # for NFS permissions

        extraGroups = [ "wheel" "dialout" "video" "audio" "input" ];

        shell = "${pkgs.zsh}/bin/zsh";

        # Don't forget to set an actual password with passwd(1).
        initialPassword = "password";
      };

      # Make the default download directory a tmpfs, so I don't end up
      # using it as a non-volatile dir for whatever.
      #
      # TODO derive path from above attribute
      fileSystems."/home/tmplt/tmp" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "rw" "size=20%" "uid=tmplt" ];
      };

      programs.zsh = {
        enable = true;
        enableCompletion = true;

        # `compinit` is called in the user configuration. Don't call it twice.
        enableGlobalCompInit = false;
      };

      programs.light.enable = true;

      programs.sway = {
        enable = true;
        extraPackages = with pkgs; [
          xwayland
          xorg.xrdb
          waybar
          swaylock
          swayidle

          mako
          kanshi
        ];
      };

      services.xserver = {
        enable = false;
        windowManager.stumpwm.enable = true;
      };

      services.xserver.xkbVariant = "colemak";
      console.useXkbConfig = true;

      # Convenience symlinks for emacs, offlineimap
      environment.etc = {
        "nix/pins/cacert".source = pkgs.cacert;
        "nix/pins/mu".source = pkgs.mu;
      };

      # Fix for USB redirection in virt-manager(1).
      security.wrappers.spice-client-glib-usb-acl-helper.source =
        "${pkgs.spice_gtk}/bin/spice-client-glib-usb-acl-helper";
      environment.systemPackages = with pkgs; [ spice_gtk ];

      home-manager.users.tmplt = {
        manual.manpages.enable = true;

        home.file = {
          ".zim".source = "${zimfw}";
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

          plugins = [rec {
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
            disks =
              "echo '╓───── m o u n t . p o i n t s'; echo '╙────────────────────────────────────── ─ ─ '; lsblk -a; echo ''; echo '╓───── d i s k . u s a g e'; echo '╙────────────────────────────────────── ─ ─ '; df -h;";
            ytdl = "youtube-dl --output '%(uploader)s - %(title)s.%(ext)s'";
            zathura = "zathura --fork";
          };

          sessionVariables = {
            ALTERNATE_EDITOR =
              ""; # start emacs server on connect if not already running
            EDITOR = "emacsclient";
            VISUAL = "emacsclient -c -a emacs";
            BROWSER = "qutebrowser";

            # Fix telegram-desktop SEGV
            QT_QPA_PLATFORM = "wayland";
            XCURSOR_SIZE = "24";
          };
        };

        programs.git = {
          enable = true;
          userName = "Viktor Sonesten";
          userEmail = "v@tmplt.dev";
          package = pkgs.gitAndTools.gitFull;
        };

        programs.emacs = { enable = true; };

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

            "kobo" = {
              hostname = "192.168.2.190";
              user = "root";
            };

            "builder" = {
              hostname = "tmplt.dev";
              user = "builder";
              identityFile = "~/.ssh/id_builder";
            };

            "pi" = {
              hostname = "tmplt.dev";
              user = "root";
              port = 21013;
              extraOptions = { StrictHostKeyChecking = "no"; };
            };
          };
        };

        # Automatically fetch email every 5m.
        systemd.user.services.offlineimap = {
          Unit = {
            Description = "Offlineimap Service";
            Documentation = "man:offlineimap(1)";
          };

          Service = {
            ExecStart =
              "${pkgs.bash}/bin/bash -c 'PATH=${pkgs.mu}/bin:$PATH ${pkgs.offlineimap}/bin/offlineimap -u basic'";
            Restart = "on-failure";
            RestartSec = 60;
          };

          Install.WantedBy = [ "default.target" ];
        };

        services.mpd = {
          enable = true;
          musicDirectory = "/mnt/dulcia/music";
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
            download = "$HOME/tmp";
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

        services.gpg-agent = {
          enable = true;

          defaultCacheTtl = 1800; # 30 min
          defaultCacheTtlSsh = 1800;
          enableSshSupport = true;
          grabKeyboardAndMouse = true;
          enableScDaemon = false;
        };

        services.syncthing = {
          enable = true;
          tray = false;
        };
      };

      # System services

      systemd.coredump.enable = true;
      services.udisks2.enable = true;
      services.dictd.enable = true;
      services.dnsmasq.enable = true;
      services.acpid.enable = true;

      # Misc. options

      # Allow certain USB interfaces to be accessed without root privelages.
      services.udev.extraRules = with lib;
        let
          toUdevRule = vid: pid: ''
            SUBSYSTEM=="usb", ATTR{idVendor}=="${vid}", ATTR{idProduct}=="${pid}", TAG+="uaccess", RUN{builtin}+="uaccess" MODE:="0666"
          '';
          setWorldReadable = idPairs:
            concatStrings
            (map (x: let l = splitString ":" x; in toUdevRule (head l) (last l))
              idPairs);
        in (setWorldReadable [
          "0483:374b"
          "0483:3748"
          "0483:3752" # ST-LINK/V2.1 rev A/B/C+
          "15ba:002a" # ATM-USB-TINY-H JTAG interface
          "1366:1015" # SEGGER (JLink firmware)
          "0403:6014" # FT232H
        ]) +
        # Shutdown system on low battery level to prevents fs corruption
        ''
          KERNEL=="BAT0" \
          , SUBSYSTEM=="power_supply" \
          , ATTR{status}=="Discharging" \
          , ATTR{capacity}=="[0-5]" \
          , RUN+="${pkgs.systemd}/bin/systemctl poweroff"
        '';

      fileSystems."/mnt/dulcia" = {
        device = "dulcia.localdomain:/rpool/media";
        fsType = "nfs";
        options = [
          "defaults" # XXX: is this causing us issues?
          "noexec"
          "noauto"
          "nofail"

          # Don't retry NFS requests indefinitely.
          # XXX: can cause data corruption, but its responsiveness I'm after.
          "soft"

          "timeo=1" # 0.1s before sending the next NFS request
          "retry=0"
          "retrans=10"

          "x-systemd.automount"
          "x-systemd.mount-timeout=1s"
        ];
      };

      nix = {
        distributedBuilds = true;
        buildMachines = [{
          hostName = "tmplt.dev";
          sshUser = "builder";
          sshKey = "/home/tmplt/.ssh/id_builder";
          systems = [ "x86_64-linux" "aarch64-linux" ];
          maxJobs = 12;
          supportedFeatures = [ "big-parallel" ]; # build Linux
        }];

        # Builder has much faster Internet connection.
        extraOptions = ''
          builders-use-substitutes = true
        '';
      };

      # Hibernate after the lid has been closed for 1h.
      environment.etc."systemd/sleep.conf".text = "HibernateDelaySec=1h";
      services.logind = {
        lidSwitch = "suspend-then-hibernate";
        lidSwitchDocked = "suspend-then-hibernate";

        # See logind.conf(5).
        extraConfig = ''
          HandleSuspendKey=ignore
          handleHibernateKey=hibernate

          PowerKeyIgnoreInhibited=yes
          SuspendKeyIgnoreInhibited=yes
          HibernateKeyIgnoreInhibited=yes
          LidSwitchIgnoreInhibited=yes
        '';
      };

      powerManagement = {
        enable = true;
        powertop.enable = true;
      };

      systemd.extraConfig = ''
        DefaultTimeoutStopSec=30s
      '';

      system.stateVersion = "18.03";
    };
}
