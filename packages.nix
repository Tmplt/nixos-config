# This file contains configuration for packages to install.
# It does not contain configuration for software that is already covered
# by other NixOS options.

{ config, pkgs, ... }:

let
  fetchChannel = { rev, sha256 }: import (fetchTarball {
    inherit sha256;
    url = "https://github.com/NixOS/nixpkgs-channels/archive/${rev}.tar.gz";
  }) { config.allowUnfree = true; };

  # Channels last updated: 2018-11-28
  #
  # Instead of relying on Nix channels and ending up with out-of-sync
  # situations between machines, the commit for the stable Nix channel
  # is pinned here.
  stable = fetchChannel {
    rev = "a7fd4310c0cc7f50d2e5eb1f6172c31969569930";
    sha256 = "1nvqrj34irg6bp6n6xp7ls5nmbzrcgkjzxxxv3hxqwfjdgyj218q";
  };

  # Certain packages from unable are hand-picked into the package set.
  unstable = fetchChannel {
    rev = "80738ed9dc0ce48d7796baed5364eef8072c794d";
    sha256 = "0anmvr6b47gbbyl9v2fn86mfkcwgpbd5lf0yf3drgm8pbv57c1dc";
  };
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
      pbpst = unstable.pbpst;
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
    # ghc
    # jdk8
    # rustc
    # rustPlatform.rustcSrc
    # rustracer
    sqlite
    # rustfmt
    gdb
    nix-prefetch-git
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
