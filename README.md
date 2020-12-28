NixOS configuration
===

(Note: this documentation is likely to be out of sync with the repo content.)

My NixOS configurations for all my systems - sans mobile phone, for now - managed via nixops(1).
This repository is published as a convenience for myself, but also as a resource for people interested in Nix(OS).

Feel free to ping me with any questions you might have.

* systems/**laptop**: laptop for general-purpose work.
* systems/**nas**: ZFS storage with periodical dataset backup, scrubbing, disk self-tests; future seed-box. Shares media with **laptop** over NFS.
* systems/**server**: [taskd](https://taskwarrior.org/) server, [website](https://tmplt.dev) host, with Let's Encrypt certificate, etc..

All systems with a running X server hosts a simple [xmonad](https://xmonad.org/) configuration with one or more status bars.

Expressions
===

All systems above are declared under `systems/*.nix`.
This root directory contains some utilities and shared expressions,

`bootstrap/` contains ISO declarations for bootstrapping into my configurations from bare-metal.

Building Instructions
===

After setting up prerequisites for nixops (SSH server with root):

```sh
$ nixops [create|modify] -d [laptop|router|server] systems/[laptop|router|server].nix
$ nixops deploy -d [laptop|router|server]
```

or alternatively

```sh
$ make [laptop|router|server]
```
