#!/bin/sh

what_is_this() {


ENVE_HOME="$(dirname $0)/../libexec"


. "$ENVE_HOME/enve/gitlib"

BATS_TMPDIR=$TMPDIR/test_gitlib
rm -rf "$BATS_TMPDIR"
mkdir "$BATS_TMPDIR"


CLONE_TO="$BATS_TMPDIR/enve-test-clone" \
GIT_REMOTE_URL="https://github.com/ranlempow/enve.git" clone_to

echo "$BATS_TMPDIR"

}
