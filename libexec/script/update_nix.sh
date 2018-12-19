#!/usr/bin/env bash

readlink() {
    python -c "import os; print(os.path.realpath('$2'))"
}

new_profile=$(
NIX_REMOTE=daemon \
NIX_PATH=nixpkgs=https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz \
NIX_SSL_CERT_FILE=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt \
$(readlink -f "/nix/var/nix/profiles/default")/bin/nix-build --no-out-link - <<'EOF'
with import <nixpkgs> { };
buildEnv { 
  name = "user-environment";
  paths = [
    nix cacert
  ];
}
EOF
) || {
    echo "fail to build new profile in /nix/store"
    exit 1
}

sudo rm /nix/var/nix/profiles/default
sudo ln -s "$new_profile" /nix/var/nix/profiles/default || {
    echo "fail to link $new_profile to default profile"
    exit 1
}
echo "link $new_profile to default profile"
