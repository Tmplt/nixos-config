# Configuration of $EDITOR

{ config, lib, pkgs, ... }:

let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    rev = "14a0dce9e809d222a85ad19aa7d3479cc104e475";
    ref = "release-19.03";
  };

  local = import ./nixpkgs { inherit config; };
in
{
  home-manager.users.tmplt.programs.neovim = {
    enable = true;
    configure = {
      customRC = builtins.readFile etc/init.vim;

      packages.myVimPackage = with local.pkgs.vimPlugins; {
        start = [
          vim-cpp-enhanced-highlight
          seoul256-vim
          vim-nix
          haskell-vim
          rust-vim
          commentary
          fzf-vim
          nerdtree
          nerdtree-git-plugin
          vimtex
          gitgutter
          vim-colorschemes
          fugitive
          lightline-vim
          ctrlp-vim
          delimitMate
        ];
      };
    };
  };
}
