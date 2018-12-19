ruby_build = pkgs.stdenv.mkDerivation rec {
  name    = "ruby_build-${version}";
  version = "20180618";
  src = fetchTarball {
    url    = "https://github.com/rbenv/ruby-build/archive/v${version}.tar.gz";
    # sha256 = "610c5fc08d0137c5270cefd14623120ab10cd81b9f48e43093893ac8d00484c9";
  };

  installPhase = ''
    PREFIX=$out ${src}/install.sh
  '';
};
