
mkstab() {
    sourcefile=$1
    shift

    ENVE_HOME="$BATS_TEST_DIRNAME/../libexec"

    if [ ! -t 0 ]; then
        _tail=$(cat)
    else
        _tail=${TAIL_CODE:-}
    fi

    mkdir -p $BATS_TMPDIR/cmds
    for func in "$@"; do
        cat > "$BATS_TMPDIR/cmds/$func" <<EOF
#!/usr/bin/env ${TEST_SHELL:-bash}
set -eu
ENVE_HOME="$ENVE_HOME"
TEST=test
. "$BATS_TEST_DIRNAME/$sourcefile"
$func "\$@"
$_tail
EOF
        chmod 755 "$BATS_TMPDIR/cmds/$func"
    done
    if  [ "${PATH%$BATS_TMPDIR/cmds:*}" = "$PATH" ]; then
        export PATH="$BATS_TMPDIR/cmds:$PATH"
    fi
    unset _tail
}

ENVE_HOME="$BATS_TEST_DIRNAME/../libexec"
