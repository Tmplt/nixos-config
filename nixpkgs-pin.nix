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
}
