{ config, pkgs, lib, ... }:

let
  stable = pkgs;
  rolling = import (fetchTarball https://github.com/nixos/nixpkgs-channels/archive/nixos-unstable.tar.gz) { };
  edge = import (fetchTarball https://github.com/nixos/nixpkgs/archive/master.tar.gz) { };

  base = (with stable; [
    bc
    binutils
    curl
    file
    gparted
    htop
    imagemagick
    libnotify
    lm_sensors
    lxappearance
    maim
    mpc_cli
    mpd
    mpv
    mumble
    neofetch
    openssl
    atool
    parallel
    pass
    pavucontrol
    stow
    tree
    neovim
    wget
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

    virtmanager
    qemu
    OVMF
    pciutils
    gnome3.dconf
  ]);

  extra = (with stable; [
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
    haskellPackages.xmobar
    youtube-dl
    thunderbird
    octave
    nfs-utils
    qutebrowser
  ]) ++ (with rolling; [
    exa
    pbpst
  ]) ++ (with edge; [
    # pbpst
  ]);

  development = (with stable; [
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
  ]);

in
{
  # config.allowUnfree = true;

  environment.systemPackages =
    base ++
    extra ++
    development ++
    [];

  nixpkgs.config.allowUnfree = true;

  fonts = {
    enableCoreFonts = true;
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fontconfig.enable = true;

    fonts = (with pkgs; [
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
    ]);
  };
}
