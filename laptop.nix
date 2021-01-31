{
  perscitia = { config, lib, pkgs, ... }:
    let
      secrets = import ./secrets;
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

        bluetooth.enable = true;
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

        extraGroups = [ "wheel" "dialout" "video" "audio" "input" "libvirtd" ];

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

      programs.light.enable = true;

      services.xserver = {
        enable = true;
        xkbVariant = "colemak";
        xkbOptions = "ctrl:nocaps,compose:menu,compose:rwin";
        autoRepeatDelay = 300;
        autoRepeatInterval = 35;
      };
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
        accounts.email.maildirBasePath = "mail";
        accounts.email.accounts = {
          "tmplt" = rec {
            primary = true;
            address = "v@tmplt.dev";
            aliases = [ "tmplt@dragons.rocks" ];
            userName = address;
            flavor = "plain";
            folders = {
              inbox = "INBOX";
              trash = "Junk";
            };
            imap = {
              host = "imap.migadu.com";
              port = 993;
              tls.enable = true;
            };
            smtp = {
              host = "smtp.migadu.com";
              port = 587;
              tls.enable = true;
              tls.useStartTls = true;
            };
            passwordCommand = "${pkgs.pass}/bin/pass show email/migadu/v@tmplt.dev | head -1";

            # mbsync.enable = true;
            # mbsync.create = "both";
            offlineimap = {
              enable = true;
              extraConfig.remote.remotepass = secrets.emails.tmplt;
              extraConfig.account = {
                autorefresh = 5;
                postsynchook = "mu index";
              };
            };
            mu.enable = true;
            msmtp.enable = true;
          };

          "personal" = rec {
            address = "viktor.sonesten@mailbox.org";
            userName = address;
            flavor = "plain";
            folders.inbox = "INBOX";
            imap = {
              host = "imap.mailbox.org";
              port = 993;
              tls.enable = true;
            };
            smtp = {
              host = "smtp.mailbox.org";
              port = 587;
              tls.enable = true;
              tls.useStartTls = true;
            };
            passwordCommand = "${pkgs.pass}/bin/pass show email/mailbox.org | head -1";

            # mbsync.enable = true;
            # mbsync.create = "both";
            offlineimap = {
              enable = true;
              extraConfig.remote.remotepass = secrets.emails.personal;
              extraConfig.account = {
                autorefresh = 5;
                postsynchook = "mu index";
              };
            };
            mu.enable = true;
            msmtp.enable = true;
          };

          "ludd" = rec {
            address = "tmplt@ludd.ltu.se";
            userName = "tmplt";
            flavor = "plain";
            folders.inbox = "INBOX";
            imap = {
              host = "imaphost.ludd.ltu.se";
              port = 993;
              tls.enable = true;
            };
            smtp = {
              host = "mailhost.ludd.ltu.se";
              port = 465;
            };
            passwordCommand = "${pkgs.pass}/bin/pass show uni/ludd | head -1";

            offlineimap = {
              enable = true; # FIXME generic SASL error when mbsync is used
              extraConfig.remote.remotepass = secrets.emails.ludd;
              extraConfig.account = {
                autorefresh = 5;
                postsynchook = "mu index";
              };
            };
            mu.enable = true;
            msmtp.enable = true;
            msmtp.extraConfig.tls_starttls = "off";
          };

          "uni" = rec {
            address = "vikson-6@student.ltu.se";
            aliases = [ "viktor.vilhelm.sonesten@alumni.cern" ];
            userName = address;
            flavor = "gmail.com";
            passwordCommand = "${pkgs.getmail}/bin/getmail-gmail-xoauth-tokens ~/nixops/secrets/gmail.uni.json";

            offlineimap = {
              enable = true;
              extraConfig.remote = secrets.emails.uniRemoteConfig;
              extraConfig.account = {
                autorefresh = 5;
                postsynchook = "mu index";
              };
            };
            mu.enable = true;
            msmtp.enable = true;
            msmtp.extraConfig.auth = "oauthbearer";
          };
        };
        programs.mbsync.enable = false; # See <https://github.com/NixOS/nixpkgs/issues/108480>
        programs.offlineimap = {
          enable = true;
          extraConfig.general.maxsyncaccounts = 4;
        };
        programs.mu.enable = true;
        programs.msmtp.enable = true;

        manual.manpages.enable = true;

        programs.git = {
          enable = true;
          userName = "Viktor Sonesten";
          userEmail = "v@tmplt.dev";
          package = pkgs.gitAndTools.gitFull;
        };

        programs.emacs = {
          enable = true;
          extraPackages = epkgs: [ epkgs.pdf-tools epkgs.org-pdftools ]; # non-trivial
        };
        services.emacs.enable = true;

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
              "${pkgs.bash}/bin/bash -c 'PATH=${pkgs.mu}/bin:$PATH ${pkgs.offlineimap}/bin/offlineimap -u syslog'";
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

        # Graphical services

        xsession = {
          enable = true;
          windowManager.command = "${pkgs.lispPackages.stumpwm}/bin/stumpwm";
        };

        services.screen-locker = {
          enable = true;
          inactiveInterval = 10; # lock after 10min of inactivity
          lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 000000";
        };

        services.picom = {
          enable = true;
          vSync = true;
        };

        services.random-background = {
          enable = true;
          enableXinerama = true;
          imageDirectory = "%h/wallpapers";
        };

        services.gammastep = {
          # FIXME kill immidiately on SIGTERM. Don't wait for it to dim
          # back; that blocks WM termination.
          enable = true;
          provider = "geoclue2";
        };

        services.unclutter.enable = true;
      };

      # System services

      systemd.coredump.enable = true;
      services.geoclue2.enable = true;
      services.udisks2.enable = true;
      services.dictd.enable = true;
      services.acpid.enable = true;
      virtualisation.libvirtd.enable = true;

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
