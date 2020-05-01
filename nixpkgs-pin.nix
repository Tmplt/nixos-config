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

  # 2020-04-28 (20.03)
  stable = fetchChannel {
    rev = "3aeaf7498463c0e9406657afaf5cc0266bbb1593";
    sha256 = "0s185rc2mfjm6n45abwfcbcv6wyb0dfrpyj258wq1q5gyjc0dm9p";
  };
}
