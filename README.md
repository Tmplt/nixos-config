NixOS configuration
===

My NixOS configuration.
This repository is published as a convenience for myself,
but also as a resource for people interested in Nix(OS).

Feel free to ping me with any questions you might have.

Expressions
===
Everything in this directory, except for `nixops/`, are Nix expressions for my hands-on machines;
expressions in `nixops/` are for remote systems managed with nixops(1), as the name implies.

Building Instructions
===

```sh
$ ln -s $(hostname)-configuration.nix local-configuration.nix
# nixos-rebuild switch -I nixos-config=./configuration.nix
```
