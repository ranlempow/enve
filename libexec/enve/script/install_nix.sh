#!/bin/sh


create_directories() {
    _sudo "to make the basic directory structure of Nix (part 1)" \
        mkdir -pv -m 0755 \
            /nix /nix/var /nix/var/log /nix/var/log/nix /nix/var/log/nix/drvs \
            /nix/var/nix/db \
            /nix/var/nix/gcroots \
            /nix/var/nix/profiles \
            /nix/var/nix/temproots \
            /nix/var/nix/userpool

    _sudo "to make the basic directory structure of Nix (part 2)" \
        mkdir -pv -m 1777 \
            /nix/var/nix/gcroots/per-user \
            /nix/var/nix/profiles/per-user

    _sudo "to make the basic directory structure of Nix (part 3)" \
        mkdir -pv -m 1775 /nix/store

    _sudo "to make the basic directory structure of Nix (part 4)" \
        chgrp 30000 /nix/store

    # _sudo "to set up the root user's profile (part 1)" \
    #       mkdir -pv -m 0755 /nix/var/nix/profiles/per-user/root

    # _sudo "to set up the root user's profile (part 2)" \
    #       mkdir -pv -m 0700 "$ROOT_HOME/.nix-defexpr"

    if [ -z "${NO_SYSTEM_SETUP:-}" ]; then
        _sudo "to place the default nix daemon configuration (part 1)" \
                mkdir -pv -m 0555 /etc/nix
    fi
}

install_from_extracted_nix() {
    (
        if ! cd "$EXTRACTED_NIX_PATH"; then
            failure "cannot change directory to '$EXTRACTED_NIX_PATH'"
        fi

        _sudo "to copy the basic Nix files to the new store at $NIX_ROOT/store" \
              rsync -rlpt ./store/* "$NIX_ROOT/store/"

        if [ -d "$NIX_INSTALLED_NIX" ]; then
            echo "      Alright! We have our first nix at $NIX_INSTALLED_NIX"
        else
            failure <<EOF
Something went wrong, and I didn't find Nix installed at
$NIX_INSTALLED_NIX.
EOF
        fi

        # _sudo "to initialize the Nix Database" \
        #       $NIX_INSTALLED_NIX/bin/nix-store --init --option build-users-group 30000

        # cat ./.reginfo \
        #     | _sudo "to load data for the first time in to the Nix Database" \
        #            "$NIX_INSTALLED_NIX/bin/nix-store" --load-db --option build-users-group 30000
        # _sudo "to load data for the first time in to the Nix Database" \
        #         "$NIX_INSTALLED_NIX/bin/nix-store" --load-db --option build-users-group 30000 \
        #         < "./.reginfo"

        _sudo "to load data for the first time in to the Nix Database" \
                "$NIX_INSTALLED_NIX/bin/nix-store" --load-db \
                < "./.reginfo"

        echo "      Just finished getting the nix database ready."
    )
}


main() {
    if [ "$(uname -s)" = "Darwin" ]; then
        # shellcheck source=./install-darwin-multi-user.sh
        # shellcheck disable=1091
        . "$EXTRACTED_NIX_PATH/install-darwin-multi-user.sh"
    elif [ "$(uname -s)" = "Linux" ] && [ -e /run/systemd/system ]; then
        # shellcheck source=./install-systemd-multi-user.sh
        # shellcheck disable=1091
        . "$EXTRACTED_NIX_PATH/install-systemd-multi-user.sh"
    else
        failure "Sorry, I don't know what to do on $(uname)"
    fi
    # welcome_to_nix
    # chat_about_sudo

    # if [ "${ALLOW_PREEXISTING_INSTALLATION:-}" = "" ]; then
    #     validate_starting_assumptions
    # fi

    # setup_report

    # if ! ui_confirm "Ready to continue?"; then
    #     ok "Alright, no changes have been made :)"
    #     contactme
    #     trap finish_cleanup EXIT
    #     exit 1
    # fi
    if [ -z "${NO_SYSTEM_SETUP:-}" ]; then
        create_build_group
        create_build_users
    fi
    create_directories
    # place_channel_configuration
    install_from_extracted_nix

    # configure_shell_profile

    # set +eu
    # . /etc/profile
    # set -eu

    # setup_default_profile
    new_profile=$(
    export NIX_PATH=nixpkgs=https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz
    # NIX_PATH=nixpkgs=http://d3g5gsiof5omrk.cloudfront.net/nixpkgs/nixpkgs-18.09pre132003.13e74a838db/nixexprs.tar.xz

    NIX_SSL_CERT_FILE=$NIX_INSTALLED_CACERT/etc/ssl/certs/ca-bundle.crt \
    sudo -E $NIX_INSTALLED_NIX/bin/nix-build --no-out-link - <<EOF
    with import <nixpkgs> { };
    buildEnv {
      name = "user-environment";
      paths = [
        $NIX_INSTALLED_NIX $NIX_INSTALLED_CACERT
      ];
    }
EOF

    )
    sudo ln -s "$new_profile" /nix/var/nix/profiles/default || die "fail to link $new_profile to default profile"
    echo "link $new_profile to default profile"


    if [ -z "${NO_SYSTEM_SETUP:-}" ]; then
        place_nix_configuration
        poly_configure_nix_daemon_service
    fi

    trap finish_success EXIT
}



install_nix() {

    if [ -n "$BOOTNIX_TEST" ]; then
        dd if=/dev/zero of=/run/cacheimage bs=1M count=256
        dd if=/dev/zero of=/run/niximage bs=1M count=768
        mkfs.ext4 /run/cacheimage
        mkfs.ext4 /run/niximage
        mkdir -p /root/.cache
        mkdir -p /nix
        mount -o loop=/dev/loop1 /run/cacheimage /root/.cache
        mount -o loop=/dev/loop2 /run/niximage /nix
        # mkdir -p /root/.cache/tmp
        # tmpDir=/root/.cache/tmp
    fi

    # curl https://nixos.org/nix/install
    curl https://nixos.org/nix/install > "$tmpDir/nix-get.sh"
    chmod 755 "$tmpDir/nix-get.sh"

    # hack to nix-get.sh
    # sed -i -e 's#script=.*# echo "$unpack"/*/install ; exit 0#' -e 's#trap cleanup.*##' "$tmpDir/nix-get.sh"
    sed -i -e 's#script=.*# echo "$unpack"/*/install ; exit 0#' "$tmpDir/nix-get.sh"
    sed -i -e 's#trap cleanup.*##' "$tmpDir/nix-get.sh"

    install_script="$($tmpDir/nix-get.sh | tail -n 1)"

    multi_install_script="$(dirname "$install_script")/install-multi-user"
    sed -i -e 's#readonly NIX_USER_COUNT="32"#readonly NIX_USER_COUNT="4"#' "$multi_install_script"
    # sed -i -e 's#readonly NIX_INSTALLED_CACERT=#NIX_INSTALLED_CACERT=#' "$multi_install_script"
    sed -i -e 's#^main$##' "$multi_install_script"

    {
        # echo "$(declare -f create_directories)" >> "$multi_install_script"

        type create_directories | tail -n +2
        # TODO: remove this
        # type install_from_extracted_nix | tail -n +2

        # TODO: remove this
        type poly_configure_nix_daemon_service | tail -n +2

        # echo "$(declare -f install_from_extracted_nix)" >> "$multi_install_script"
        # echo "$(declare -f main)" >> "$multi_install_script"
        type main | tail -n +2
        echo "main"
    } >> "$multi_install_script"

    # to fix: error: the group 'nixbld' specified in 'build-users-group' does not exist
    mkdir $tmpDir/nixconf
    echo "build-users-group =
" > $tmpDir/nixconf/nix.conf

    NIX_CONF_DIR=$tmpDir/nixconf "$install_script" --daemon

    # export NIX_SSL_CERT_FILE=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt

}

# TODO: nix 2.2.1: remove this after nix fix the bug
poly_configure_nix_daemon_service() {
    # _sudo "to set up the nix-daemon as a LaunchDaemon" \
    #       ln -sfn "/nix/var/nix/profiles/default$PLIST_DEST" "$PLIST_DEST"

    # reference: https://github.com/NixOS/nix/issues/2523
    _sudo sudo cat > "/Library/LaunchDaemons/org.nixos.nix-daemon.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>org.nixos.nix-daemon</string>
    <key>EnvironmentVariables</key>
    <dict>
      <key>OBJC_DISABLE_INITIALIZE_FORK_SAFETY</key>
      <string>YES</string>
    </dict>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>Program</key>
    <string>/nix/store/1jz25hcma179wbpi56blgajw47n5kgqd-nix-2.2.1/bin/nix-daemon</string>
    <key>StandardErrorPath</key>
    <string>/var/log/nix-daemon.log</string>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
  </dict>
</plist>
EOF
    _sudo chown root:30000 "/Library/LaunchDaemons/org.nixos.nix-daemon.plist"
    _sudo chmod 444 "/Library/LaunchDaemons/org.nixos.nix-daemon.plist"
    _sudo "to load the LaunchDaemon plist for nix-daemon" \
          launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist

    _sudo "to start the nix-daemon" \
          launchctl start org.nixos.nix-daemon

}


linux_runtime() {
    ETCROOT=${1:-/etc}

    mkdir -p $ETCROOT/sysusers.d
    cat > $ETCROOT/sysusers.d/nix-daemon.conf <<-EOF
    #Type  Name   ID              GECOS                     Home directory      Shell
    g      nixbld   30000
    u      nixbld1  "30001:30000" "Nix Build Daemon User"   /var/empty          /sbin/nologin
    u      nixbld2  "30002:30000" "Nix Build Daemon User"   /var/empty          /sbin/nologin
    u      nixbld3  "30003:30000" "Nix Build Daemon User"   /var/empty          /sbin/nologin
    u      nixbld4  "30004:30000" "Nix Build Daemon User"   /var/empty          /sbin/nologin
    m      nixbld1  nixbld
    m      nixbld2  nixbld
    m      nixbld3  nixbld
    m      nixbld4  nixbld
EOF

    cat > $ETCROOT/systemd/system/nix-daemon.service <<-EOF
[Unit]
Description=Nix Daemon
RequiresMountsFor=/nix/store
RequiresMountsFor=/nix/var
ConditionPathIsReadWrite=/nix/var/nix/daemon-socket

[Service]
ExecStart=@/nix/var/nix/profiles/default/bin/nix-daemon nix-daemon --daemon
KillMode=process
EOF

    cat > $ETCROOT/systemd/system/nix-daemon.socket <<-EOF
[Unit]
Description=Nix Daemon Socket
Before=multi-user.target
RequiresMountsFor=/nix/store
ConditionPathIsReadWrite=/nix/var/nix/daemon-socket

[Socket]
ListenStream=/nix/var/nix/daemon-socket/socket

[Install]
WantedBy=sockets.target
EOF

    mkdir -p $ETCROOT/systemd/system/sockets.target.wants
    ln -sf ../nix-daemon.socket $ETCROOT/systemd/system/sockets.target.wants/nix-daemon.socket

    mkdir -p $ETCROOT/nix
    cat <<EOF > $ETCROOT/nix/nix.conf
build-users-group = nixbld

max-jobs = 4
cores = 1
EOF
    chmod 0664 $ETCROOT/nix/nix.conf
}

boot_nix() {
    # NIX_REMOTE=daemon \
    NIX_PATH=nixpkgs=http://d3g5gsiof5omrk.cloudfront.net/nixpkgs/nixpkgs-18.09pre132003.13e74a838db/nixexprs.tar.xz \
    NIX_SSL_CERT_FILE=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt \
    /nix/var/nix/profiles/default/bin/nix-build --option build-users-group "" --no-out-link - <<'EOF'
    with import <nixpkgs> { };
    buildEnv {
      name = "gnu-environment";
      paths = [
        bashInteractive
      ];
    }
EOF
}



oops() {
    echo "$0:" "$@" >&2
    exit 1
}

tmpDir="$(mktemp -d -t nix-bootstrap.XXXXXXXXXX || \
          oops "Can\\'t create temporary directory")"
cleanup() {
    rm -rf "$tmpDir"
}
trap cleanup EXIT INT QUIT TERM


main2() {
    case ${1:-} in
        install)
            shift
            install_nix 2>&1 | tee install_nix.log
            ;;
        runtime)
            shift
            linux_runtime "$@"
            ;;
        boot)
            shift
            boot_nix
    esac
}


main2 "$@"


