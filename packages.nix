# This file contains configuration for packages to install.
# It does not contain configuration for software that is already covered
# by other NixOS options.

{ config, pkgs, lib, ... }:

let
  stable = (import ./nixpkgs-pin.nix).stable;
  unstable = (import ./nixpkgs-pin.nix).unstable;

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

      # Enable printing figures to PDF
      octave = stable.octave.overrideAttrs (cur: {
        buildInputs = cur.buildInputs ++ [ stable.gl2ps ];
      });

      # Patch for <M-u> bind to `xurls | dmenu | xargs qutebrowser`
      xst = lib.overrideDerivation stable.xst (old: {
        patches = [ patches/xst.patch ];
      });

      # improved debugging for C++
      gdb = stable.gdb.overrideAttrs (old: {
        configureFlags = old.configureFlags ++ [ "--with-auto-load-safe-path=${stable.stdenv.cc.cc.lib}" ];
      });
    };
  };

  environment.systemPackages = with pkgs; [
    acpi
    aerc
    arandr
    arc-icon-theme
    arc-theme
    aria
    atool
    binutils
    curl
    dmenu
    exa
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
    maim
    manpages
    mkskel
    mpc_cli
    mpv
    msmtp
    mumble
    ncdu
    neofetch
    neomutt
    urlscan
    nfs-utils
    notmuch
    octave
    offlineimap
    p7zip
    pandoc
    pass
    pass-otp # TODO: investigate why this doesn't work
    pavucontrol
    qutebrowser
    ranger
    steam
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
    xmobar
    xorg.xev
    xorg.xmodmap
    xorg.xprop
    xorg.xwininfo
    xsel

    # Unicode crash work-around <https://github.com/gnotclub/xst/issues/70>
    # TODO: build xst with this font instead
    symbola
    xst

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
    gitAndTools.gitFull
    git-crypt
    gnumake
    neovim
    nixops
    nix-prefetch-git
    patchelf
    python3
    python3
    ripgrep
    sqlite

    # (Embedded) Rust programming
    clang
    gcc-arm-embedded
    gdb-multitarget
    openocd
    openssl
    pkgconfig
    rustup

    arduino
  ];

  # ... and install some fonts.
  fonts = {
    enableFontDir = true;
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
    ];
  };
}
