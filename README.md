NixOS configuration
===

My NixOS configurations for all my systems - sans mobile phone, for now - managed via nixops(1).
This repository is published as a convenience for myself, but also as a resource for people interested in Nix(OS).

Feel free to ping me with any questions you might have.

* systems/**desktop**: multi-head desktop with GPU-passthrough for vidya.
* systems/**laptop**: laptop for university studies and work.
* systems/**router**: NAS, pfSense router, and future seed-box. Shares media with **temeraire** over NFS.
* systems/**server**: main server: [taskd](https://taskwarrior.org/), [website](https://dragons.rocks), [syncthing node](https://syncthing.net/) ([sr.ht](https://meta.sr.ht/) server in the future).

All systems with a running X server hosts a simple [bspwm](https://github.com/baskerville/bspwm) or [xmonad](https://xmonad.org/) configuration with one or more status bars.

Expressions
===

All systems above are declared under `systems/`.
The root directory contains some utilities and shared expressions.
Except for `misc/` that contains some non-Nix files (dotfiles, etc.), remaining files are self-explanatory.

Building Instructions
===

After setting up prerequisites for nixops (SSH server with root):

```sh
$ nixops [create|modify] -d $(hostname) systems/$(hostname).nix
$ nixops deploy -d $(hostname)
```

or alternatively

```sh
$ make $(hostname)
```
