NixOS configuration
===

My NixOS configuration.
This repository is published as a convenience for myself,
but also as a resource for people interested in Nix(OS).

Feel free to ping me with any questions you might have.

* **temeraire**: multi-head desktop with GPU-passthrough for vidya.
* **perscitia**: Thinkpad for university studies and work.
* **voip**: VoIP-server, as the hostname implies.
* **dulcia**: NAS and future seed-box, shares media with **temeraire**.
* **excidium**: main server: [taskd](https://taskwarrior.org/), website, [syncthing node](https://syncthing.net/) ([sr.ht](https://meta.sr.ht/) server in the future).

All hands-on system run a simple [bspwm](https://github.com/baskerville/bspwm) graphical interface with one or more [polybar](https://github.com/jaagr/polybar)s.

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
