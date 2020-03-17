# Instead of relying on Nix channels and ending up with out-of-sync
# situations between machines, the commit for the stable Nix channel
# is pinned here.

let
  fetchChannel = { rev, sha256 }: import (fetchTarball {
    inherit sha256;
    url = "https://github.com/NixOS/nixpkgs-channels/archive/${rev}.tar.gz";
  }) { config.allowUnfree = true; };
in {
  unstable = fetchChannel {
    rev = "e89b21504f3e61e535229afa0b121defb52d2a50";
    sha256 = "0jqcv3rfki3mwda00g66d27k6q2y7ca5mslrnshfpbdm7j8ya0kj";
  };

  # 2020-02-15T12:39:36+01:00
  stable = fetchChannel {
    rev = "6b47f71542931d4a5d6e18cdccd7d477a3cb0817";
    sha256 = "1p7l3kchyh8fslz2cajz7krigz2lr0dv11kfck1v7mzwj2iffj7g";
  };
}
