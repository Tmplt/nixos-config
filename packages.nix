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
    rev = "2436c27541b2f52deea3a4c1691216a02152e729";
    sha256 = "0p98dwy3rbvdp6np596sfqnwlra11pif3rbdh02pwdyjmdvkmbvd";
  };

  # Certain packages of mine own haven't been merged yet.
  tmplt = import (fetchTarball {
    url = "https://github.com/Tmplt/nixpkgs/archive/ce27f2b964ae001bf9e5f1d3b708205804d51356.tar.gz";
    sha256 = "0bmdmshz5v42bdxmf810p2hcq6qwn82kns4d7v9mlcnyf3j56ndk";
  }) { config.allowUnfree = true; };

  onTemeraire = config.networking.hostName == "temeraire";
  onPerscitia = config.networking.hostName == "perscitia";

  mkskel = pkgs.stdenv.mkDerivation rec {
    name = "mkskel-${version}";
    version = "1.0.0";
    src = pkgs.fetchurl {
      url = "https://git.sr.ht/~zge/${name}/archive/${version}.tar.gz";
      sha256 = "0z8hq5mymb5r7q5zdikjfr2gb0fihyh48sfs9y4qx68iflhzq4j5";
    };

    installPhase = ''
      mkdir -p $out/bin
      make install DESTDIR=$out
    '';
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

      # v1.8.5 required for OAUTH2
      msmtp = unstable.msmtp;

      # Let me print figures to pdf
      octave = unstable.octave.overrideAttrs (old: {
        buildInputs = old.buildInputs ++ [ unstable.gl2ps ];
      });

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
    python3
    python37Packages.pygments

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
    mkskel
    octave
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
