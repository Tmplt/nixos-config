# This file contains configuration for packages to install.
# It does not contain configuration for software that is already covered
# by other NixOS options.

{ config, pkgs, ... }:

let
  fetchChannel = { rev, sha256 }: import (fetchTarball {
    inherit sha256;
    url = "https://github.com/NixOS/nixpkgs-channels/archive/${rev}.tar.gz";
  }) { config.allowUnfree = true; };

  # Channels last updated: 2019-02-25
  #
  # Instead of relying on Nix channels and ending up with out-of-sync
  # situations between machines, the commit for the stable Nix channel
  # is pinned here.
  stable = fetchChannel {
    rev = "aabc61049c011b40ef15c354d7d84c840d6b6a6d";
    sha256 = "043npvvr8zxndhq6mfyzriv3b363biy2cnskpngv9fkxmizszrfl";
  };

  # Certain packages from unable are hand-picked into the package set.
  unstable = fetchChannel {
    rev = "19eedaf867da3155eec62721e0c8a02895aed74b";
    sha256 = "06k0hmdn8l1wiirfjcym86pn9rdi8xyfh1any6vgb5nbx87al515";
  };

  # Certain packages of mine own haven't been merged yet.
  tmplt = import (fetchTarball {
    url = "https://github.com/Tmplt/nixpkgs/archive/ce27f2b964ae001bf9e5f1d3b708205804d51356.tar.gz";
    sha256 = "0bmdmshz5v42bdxmf810p2hcq6qwn82kns4d7v9mlcnyf3j56ndk";
  }) { config.allowUnfree = true; };

  onTemeraire = config.networking.hostName == "temeraire";
in {
  # Configure the Nix package manager
  nixpkgs = {
    config.allowUnfree = true;
    # To use the pinned channel, the original package set is thrown away in
    # the overrides:
    config.packageOverrides = oldPkgs: stable // {
      # Store whole unstable channel in case any module need it
      inherit unstable;

      # Backport Exa from unstable until a fix for the Rust builder is
      # backported.
      #
      # <https://github.com/NixOS/nixpkgs/pull/48020>
      exa = unstable.exa;

      # Not available in 18.09
      pbpst = tmplt.pbpst;
    };
  };

  # ... and declare packages to be installed.
  environment.systemPackages = with pkgs; [
    # Base
    binutils
    curl
    file
    gparted
    htop
    imagemagick
    libnotify
    lxappearance
    maim
    mpc_cli
    mpd
    mpv
    mumble
    neofetch
    atool
    pass
    pavucontrol
    stow
    tree
    neovim
    wmname
    xorg.xev
    xorg.xmodmap
    xorg.xprop
    xorg.xwininfo
    zathura
    zsh
    usbutils
    unrar
    unzip
    patchelf
    manpages
    gnupg

    # Extra
    firefox
    audacity
    compton
    aria
    fzf
    gimp
    inkscape
    wireshark
    texlive.combined.scheme-full
    wine
    winetricks
    firejail
    bspwm
    sxhkd
    st
    dmenu
    acpi
    irssi
    hibernate
    ncdu
    arc-theme
    arc-icon-theme
    youtube-dl
    thunderbird
    octave
    nfs-utils
    qutebrowser
    exa
    pbpst

    # Development
    gitAndTools.gitFull
    git-crypt
    cmake
    python3
    gnumake
    curlFull
    rtags
    ghc
    # jdk8
    # rustc
    # rustPlatform.rustcSrc
    # rustracer
    sqlite
    # rustfmt
    gdb
    nix-prefetch-git

    # From old home-manager configs.
    # TODO: categorize this list?
    rofi
    termite
    silver-searcher
    xfontsel
    xorg.mkfontscale
    xorg.mkfontdir
    font-manager
    bind

    (polybar.override {
      mpdSupport = onTemeraire;
    })

    unifont
    pandoc
    libreoffice
    teamspeak_client
    rofi-pass
    pass-otp
    i3lock
    feh
    arandr
    ncmpcpp
    python36Packages.pygments
    xdotool
    xsel
    p7zip
    beets
    direnv
    calibre
    sxiv
    steam

    # Embedded Rust programming
    gcc-arm-embedded
    gdb-multitarget
    openocd
    rustup
    cargo
    openssl
    pkgconfig
    qemu
    clang

    # Java stuff
    jetbrains.idea-community
    jetbrains.jdk
  ];

  # ... and install some fonts.
  fonts = {
    enableCoreFonts = true;
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fontconfig.enable = true;

    fonts = with pkgs; [
      liberation_ttf
      libertine
      freefont_ttf
      dejavu_fonts
      iosevka
      source-code-pro
      siji
      opensans-ttf
      noto-fonts
      inconsolata
      font-awesome-ttf
      fira-code
      envypn-font
      gohufont
    ];
  };
}
