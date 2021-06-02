# This file contains configuration for packages to install.
# It does not contain configuration for software that is already covered
# by other NixOS options.

{ config, pkgs, ... }:

{
  nixpkgs = {
    config.allowUnfree = true;
    config.packageOverrides = pkgs: {

      # Latest tagged release is from 2017, which lacks some scripts I need.
      openocdRecent = with pkgs; openocd.overrideAttrs (old: {
        src = fetchgit {
          url = "https://git.code.sf.net/p/openocd/code";
          rev = "7c88e76a76588fa0e3ab645adfc46e8baff6a3e4";
          sha256 = "0qli4zyqc8hvbpkhwscsfphk14sdaa1zxav4dqpvj21kgqxnbjr8";
          fetchSubmodules = false; # available in nixpkgs
        };

        # no longer applies
        patches = [ ];
        postPatch = ''
          ${gnused}/bin/sed -i "s/\''${libtoolize}/libtoolize/g" ./bootstrap
          ${gnused}/bin/sed -i '7,14d' ./bootstrap
        '';

        buildInputs = old.buildInputs ++ [ automake autoconf m4 libtool tcl jimtcl ];

        preConfigure = ''
          ./bootstrap nosubmodule
        '';
        configureFlags = old.configureFlags ++ [
          "--disable-internal-jimtcl"
          "--disable-internal-libjaylink"
        ];
      });
    };
  };

  environment.systemPackages = with pkgs; [
    gammastep
    foot

    acpi
    arc-icon-theme
    arc-theme
    aria
    atool
    binutils
    curl
    dmenu
    file
    fzf
    getmail
    gnupg
    htop
    imagemagick
    irssi
    krita
    libnotify
    lxappearance
    manpages
    mpc_cli
    mpv
    msmtp
    mumble
    ncdu
    neofetch
    nfs-utils
    octave
    offlineimap
    p7zip
    pandoc
    pass
    pass-otp # TODO: investigate why this doesn't work
    pavucontrol
    qutebrowser
    sxiv
    tdesktop # Telegram
    tomb
    tree
    unrar
    unzip
    usbutils
    virtmanager
    w3m
    wine
    winetricks
    xdotool
    xorg.xev
    xorg.xmodmap
    xorg.xprop
    xorg.xwininfo
    xsel
    xdg_utils

    xurls
    youtube-dl
    zathura

    # Typesetting
    python3Packages.pygments
    texlive.combined.scheme-full # for minted

    # Development
    cmake
    direnv
    gdb
    git-crypt
    gnumake
    neovim
    nixops
    nix-prefetch-git
    patchelf
    python3
    ripgrep
    sqlite

    # (Embedded) Rust programming
    clang
    gcc-arm-embedded
    gdb-multitarget
    # openocdRecent # compilation warnings must not become errors
    openssl
    pkgconfig
    rustup

    zoom-us
    # nyxt

    ntfs3g # so we can mount NTFS parts
  ];

  # ... and install some fonts.
  fonts = {
    fontDir.enable = true;
    enableDefaultFonts = true;
    enableGhostscriptFonts = true;
    fontconfig.enable = true;

    fonts = with pkgs; [
      corefonts
      dejavu_fonts
      envypn-font
      fira-code
      font-awesome
      freefont_ttf
      gohufont
      inconsolata
      iosevka
      liberation_ttf
      libertine
      noto-fonts
      opensans-ttf
      siji
      source-code-pro
      go-font
    ];
  };
}
