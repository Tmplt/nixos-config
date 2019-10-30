# This file contains configuration for packages to install.
# It does not contain configuration for software that is already covered
# by other NixOS options.

{ config, pkgs, lib, ... }:

let
  stable = (import ./nixpkgs-pin.nix).stable;
  unstable = (import ./nixpkgs-pin.nix).unstable;

  onTemeraire = config.networking.hostName == "temeraire";
  onPerscitia = config.networking.hostName == "perscitia";

  mkskel = pkgs.stdenv.mkDerivation rec {
    pname = "mkskel";
    name = "${pname}-${version}";
    version = "1.0.0";
    src = pkgs.fetchurl {
      url = "https://git.sr.ht/~zge/${pname}/archive/${version}.tar.gz";
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
    pass-otp
    pavucontrol
    neovim
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
    aria
    fzf

    texlive.combined.scheme-full
    python3
    python37Packages.pygments

    wine
    winetricks
    xst
    xurls
    dmenu
    acpi
    irssi
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
    sqlite
    gdb
    nix-prefetch-git

    pandoc
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
