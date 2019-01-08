NixOS configuration
===

My NixOS configurations for all my systems - sans mobile phone, for now - managed via nixops(1).
This repository is published as a convenience for myself, but also as a resource for people interested in Nix(OS).

Feel free to ping me with any questions you might have.

* **temeraire**: multi-head desktop with GPU-passthrough for vidya.
* **perscitia**: laptop for university studies and work.
* **voip**: VoIP-server, as the hostname implies.
* **dulcia**: NAS and future seed-box, shares media with **temeraire**.
* **excidium**: main server: [taskd](https://taskwarrior.org/), website, [syncthing node](https://syncthing.net/) ([sr.ht](https://meta.sr.ht/) server in the future).

All hands-on systems run a simple [bspwm](https://github.com/baskerville/bspwm) graphical interface with one or more [polybar](https://github.com/jaagr/polybar)s.

Expressions
===

All systems above are declared under `systems/`.
This directory contains some utilities and shared expressions.
Except for `misc/` that contains some non-Nix files, remaining files are self-explanatory.

Building Instructions
===

After setting up prerequisites for nixops (SSH server with root):

```sh
$ nixops [create|modify] -d $(hostname) systems/$(hostname).nix
$ nixops deploy -d $(hostname)
```
