# Instead of relying on Nix channels and ending up with out-of-sync
# situations between machines, the commit for the stable Nix channel
# is pinned here.

let
  fetchChannel = { rev, sha256 }: import (fetchTarball {
    inherit sha256;
    url = "https://github.com/NixOS/nixpkgs-channels/archive/${rev}.tar.gz";
  }) { config.allowUnfree = true; };
in {
  # 2020-05-18 (20.03)
  unstable = fetchChannel {
    rev = "548872be20dcb78cdb1a554dcef51caf1d6055ca";
    sha256 = "0j44n9rjm5c0j4iw4qwcckh6kjcnp5jy58sb0j6h4rqrlysrrx3f";
  };

  # 2020-06-18 (20.03)
  stable = fetchChannel {
    rev = "7bb2e7e0f69150b659a444590f0208c42f3de6d5";
    sha256 = "11qa81rs490l0kv655g5jh3rfz6bc7w5vxgsfax1b51yqpslwfx3";
  };
}
