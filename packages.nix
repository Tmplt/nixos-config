# This file contains configuration for packages to install.
# It does not contain configuration for software that is already covered
# by other NixOS options.

{ config, pkgs, ... }:

let
  fetchChannel = { rev, sha256 }: import (fetchTarball {
    inherit sha256;
    url = "https://github.com/NixOS/nixpkgs-channels/archive/${rev}.tar.gz";
  }) { config.allowUnfree = true; };

  # Channels last updated: 2018-12-13
  #
  # Instead of relying on Nix channels and ending up with out-of-sync
  # situations between machines, the commit for the stable Nix channel
  # is pinned here.
  stable = fetchChannel {
    rev = "4f3446f29910d21eb0fb942bd03091b089cdad63";
    sha256 = "0dqjkhhhckp881mns69qxn4dngcykal1gqrpaf9qy2vja4i41ay5";
  };

  # Certain packages from unable are hand-picked into the package set.
  unstable = fetchChannel {
    rev = "ad3e9191d16722ea3eec32f4cd689eea730f39f6";
    sha256 = "0nrdv87xnhgrispgm88zdbgkfkn9j0q31395sma5jsxiq9wpki5r";
  };

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
    # pbpst

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

    # Embedded Rust programming
    gcc-arm-embedded
    gdb-multitarget
    openocd
    rustup
    cargo
    openssl
    pkgconfig
    qemu
  ] ++ (lib.optional onTemeraire steam);

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
