# Declare dotfiles not generated by Nix options.

{ config, lib, pkgs, ... }:

let
  dotfiles = ./dotfiles;
  secrets = ./secrets;
  onPerscitia = config.networking.hostName == "perscitia";
  onTemeraire = config.networking.hostName == "temeraire";
in
{
  # TODO: clean this up with some neat functions
  home-manager.users.tmplt.home.file = if onPerscitia then {
    ".config/mpv/scripts/youtube-quality.lua".source = "${dotfiles}/mpv/.config/mpv/scripts/youtube-quality.lua";
    ".config/mpv/scripts/youtube-quality.conf".source = "${dotfiles}/mpv/.config/mpv/scripts/youtube-quality.conf";

    ".xmonad/xmonad.hs".source = "${dotfiles}/xmonad/.xmonad/xmonad.hs";
    ".xmobarrc".source = "${dotfiles}/xmonad/.xmobarrc";
    ".Xresources".source = "${dotfiles}/xfiles/.Xresources";
    ".zimrc".source = "${dotfiles}/zsh/.zimrc";
    ".zsh".source = "${dotfiles}/zsh/.zsh";
    ".zshrc".source = "${dotfiles}/zsh/.zshrc";

    # mutt & friends
    ".offlineimaprc".source = "${secrets}/mutt/.offlineimaprc";
    ".offlineimap.py".source = "${secrets}/mutt/.offlineimap.py";
    ".msmtprc".source = "${secrets}/mutt/.msmtprc";
    ".muttrc".source = "${secrets}/mutt/.muttrc";
    ".mutt".source = "${secrets}/mutt/.mutt";

  } else if onTemeraire then {
    # mutt & friends
    ".offlineimaprc".source = "${secrets}/mutt/.offlineimaprc";
    ".offlineimap.py".source = "${secrets}/mutt/.offlineimap.py";
    ".msmtprc".source = "${secrets}/mutt/.msmtprc";
    ".muttrc".source = "${secrets}/mutt/.muttrc";
    ".mutt".source = "${secrets}/mutt/.mutt";

    # ~/.config
    ".config/beets".source = "${dotfiles}/beets/.config/beets";
    ".config/bspwm".source = "${dotfiles}/bspwm/.config/bspwm";
    ".config/sxhkd/sxhkdrc".source = pkgs.writeText "sxhkdrc" ''
      ${builtins.readFile "${dotfiles}/sxhkd/.config/sxhkd/sxhkdrc.desktop"}
      ${builtins.readFile "${dotfiles}/sxhkd/.config/sxhkd/commons"}
    '';
    ".config/gtk-3.0".source = "${dotfiles}/termite/.config/gtk-3.0";
    ".config/mpv".source = "${dotfiles}/mpv/.config/mpv";
    ".config/ncmpcpp".source = "${dotfiles}/ncmpcpp/.config/ncmpcpp";
    ".config/polybar".source = "${dotfiles}/polybar/.config/polybar";
    ".config/termite".source = "${dotfiles}/termite/.config/termite";
    ".config/mpd/mpd.conf".source = "${dotfiles}/mpd/.config/mpd/mpd.conf";

    # ~/
    ".Xresources".source = "${dotfiles}/xfiles/.Xresources";
    ".zimrc".source = "${dotfiles}/zsh/.zimrc";
    ".zsh".source = "${dotfiles}/zsh/.zsh";
    ".zshrc".source = "${dotfiles}/zsh/.zshrc";

    # ~/bin
    "bin/fpass".source = "${dotfiles}/bin/bin/fpass";
    "bin/iommu".source = "${dotfiles}/bin/bin/iommu";
    "bin/lock".source = "${dotfiles}/bspwm/bin/lock";
    "bin/tzathura".source = "${dotfiles}/bin/bin/tzathura";
  } else {};
}
