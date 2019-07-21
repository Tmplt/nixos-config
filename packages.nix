# This file contains configuration for packages to install.
# It does not contain configuration for software that is already covered
# by other NixOS options.

{ config, pkgs, lib, ... }:

let
  fetchChannel = { rev, sha256 }: import (fetchTarball {
    inherit sha256;
    url = "https://github.com/NixOS/nixpkgs-channels/archive/${rev}.tar.gz";
  }) { config.allowUnfree = true; };

  # Channels last updated: 2019-07-21 (19.03)
  #
  # Instead of relying on Nix channels and ending up with out-of-sync
  # situations between machines, the commit for the stable Nix channel
  # is pinned here.
  stable = fetchChannel {
    rev = "55b8860aa209e987f6f15c523811e4861d97d6af";
    sha256 = "0ri58704vwv6gnyw33vjirgnvh2f1201vbflk0ydj5ff7vpyy7hf";
  };

  # Certain packages from unable are hand-picked into the package set.
  unstable = fetchChannel {
    rev = "104f8a0e1a17a894b320f86add409d9aebb36fe4";
    sha256 = "0442zswlvgwl7g3cv2w7hhpm5wfkzq11b7isnspibkb5nfpkasva";
  };

  # Certain packages of mine own haven't been merged yet.
  tmplt = import (fetchTarball {
    url = "https://github.com/Tmplt/nixpkgs/archive/ce27f2b964ae001bf9e5f1d3b708205804d51356.tar.gz";
    sha256 = "0bmdmshz5v42bdxmf810p2hcq6qwn82kns4d7v9mlcnyf3j56ndk";
  }) { config.allowUnfree = true; };

  onTemeraire = config.networking.hostName == "temeraire";
  onPerscitia = config.networking.hostName == "perscitia";
in {
  # Configure the Nix package manager
  nixpkgs = {
    config.allowUnfree = true;
    # To use the pinned channel, the original package set is thrown away in
    # the overrides:
    config.packageOverrides = oldPkgs: stable // {
      # Store whole unstable channel in case any module need it
      inherit unstable;

      # Teamspeak links inproperly with Qt in 19.03
      teamspeak_client = tmplt.teamspeak_client;

      # v1.8.5 required for OAUTH2
      msmtp = unstable.msmtp;

      # Fix Alt+u xurls | dmenu | xargs qutebrowser
      xst = lib.overrideDerivation stable.xst (old: {
        patches = [ patches/xst.patch ];
      });
    };
  };

  # ... and declare packages to be installed.
  environment.systemPackages = with pkgs; [
    # Base
    binutils
    curl
    file
    htop
    imagemagick
    libnotify
    lxappearance
    maim
    mpc_cli
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
    compton
    aria
    fzf
    texlive.combined.scheme-full
    wine
    winetricks
    sxhkd
    xst
    xurls
    dmenu
    acpi
    irssi
    hibernate
    ncdu
    arc-theme
    arc-icon-theme
    youtube-dl
    thunderbird
    nfs-utils
    qutebrowser
    exa

    # Development
    gitAndTools.gitFull
    git-crypt
    cmake
    python3
    gnumake
    curlFull
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
    font-manager

    pandoc
    teamspeak_client
    pass-otp
    arandr
    python36Packages.pygments
    xdotool
    xsel
    p7zip
    direnv
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
    clang

    haskellPackages.xmobar

    neomutt
    msmtp
    offlineimap
  ] ++ (if onTemeraire then [
    firefox
    ncmpcpp
    beets
    calibre
    bspwm
    mpd
    (polybar.override {
      mpdSupport = true;
    })
    gimp

  ] else []) ++ (if onPerscitia then [
    # palemoon
  ] else []);

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
