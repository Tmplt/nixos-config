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
    rev = "4cd2cb43fb3a87f48c1e10bb65aee99d8f24cb9d";
    sha256 = "1d6rmq67kdg5gmk94wx2774qw89nvbhy6g1f2lms3c9ph37hways";
  };

  stable = fetchChannel {
    rev = "c75de8bc12cc7e713206199e5ca30b224e295041";
    sha256 = "1awipcjfvs354spzj2la1nzmi9rh2ci2mdapzf4kkabf58ilra6x";
  };
}
