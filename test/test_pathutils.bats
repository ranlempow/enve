#!/usr/bin/env bats


# EVNE_EXEC="$BATS_TEST_DIRNAME/../enve"
# echo "$BATS_TEST_DIRNAME"
# echo "$BATS_TMPDIR"


setup() {
    mkdir -p $BATS_TMPDIR/cmds
    for func in normalize readlink_posix canonicalize_symlinks; do
        cat > "$BATS_TMPDIR/cmds/$func" <<EOF
set -euo pipefail
. "$BATS_TEST_DIRNAME/../libexec/enve/pathutils"
$func "\$@"
EOF
    done
    chmod 755 $BATS_TMPDIR/cmds/*
    export PATH="$BATS_TMPDIR/cmds:$PATH"


    # . "$EVNE_EXEC" define
    rm -rf $BATS_TMPDIR/test_readlinkf
    mkdir -p $BATS_TMPDIR/test_readlinkf
    (
        # ./a/1
        # ./a/2 -> 1
        # ./a/3 -> 2
        # ./aa/a -> ../a
        # ./aaa/aa -> ../aa
        # ./b/1 -> ../a/1
        # ./c -> b
        # ./badfile -> ../a/nonexist
        # ./baddir -> ../nonexist/1

        cd $BATS_TMPDIR/test_readlinkf
        mkdir a
        echo bingo > a/1
        ln -s 1 a/2
        ln -s 2 a/3

        mkdir b
        ln -s ../a/1 b/1
        ln -s b c
        ln -s ../a/nonexist badfile
        ln -s ../nonexist/1 baddir

        mkdir aa
        ln -s ../a aa/a
        mkdir aaa
        ln -s ../aa aaa/aa
    )
}

@test "symlink content match" {
    cd $BATS_TMPDIR/test_readlinkf
    [ "$(cat a/1)" = "bingo" ]
    [ "$(cat a/2)" = "bingo" ]
    [ "$(cat a/3)" = "bingo" ]
    [ "$(cat b/1)" = "bingo" ]
    [ "$(cat c/1)" = "bingo" ]
    [ "$(cat aa/a/1)" = "bingo" ]
    [ "$(cat aaa/aa/a/1)" = "bingo" ]   

    [ -L badfile ]
    [ -L baddir ]

}

@test "normalize" {
    [ "$(normalize "")" = "" ]
    [ "$(normalize "/")" = "/" ]
    [ "$(normalize ".")" = "." ]
    [ "$(normalize "..")" = ".." ]
    [ "$(normalize "/abc")" = "/abc" ]
    [ "$(normalize "abc/")" = "abc/" ]
    [ "$(normalize "abc///")" = "abc/" ]
    [ "$(normalize "///abc")" = "/abc" ]
    [ "$(normalize "/.//abc")" = "/abc" ]
    [ "$(normalize "/a/b/c")" = "/a/b/c" ]
    [ "$(normalize "/a/b/../c")" = "/a/c" ]
    [ "$(normalize "/a/b/../c/")" = "/a/c/" ]
    [ "$(normalize "../a/b/../c")" = "../a/c" ]
    [ "$(normalize "../../")" = "../../" ]
    [ "$(normalize "/../a/b/../c")" = "/a/c" ]
    [ "$(normalize "//.././a/b/../c")" = "/a/c" ]
    [ "$(normalize "./a")" = "./a" ]
    [ "$(normalize "./a/..")" = "." ]
    [ "$(normalize "./a/../..")" = ".." ]
    [ "$(normalize "./a/../../..")" = "../.." ]
    [ "$(normalize "a/..")" = "." ]
    
}


@test "readlink_posix" {
    cd $BATS_TMPDIR/test_readlinkf
    [ "$(readlink_posix a/1 || true)" = "" ]
    [ "$(readlink_posix a/2 || true)" = "1" ]
    [ "$(readlink_posix a/3 || true)" = "2" ]
    [ "$(readlink_posix b   || true)" = "" ]
    [ "$(readlink_posix b/1 || true)" = "../a/1" ]
    [ "$(readlink_posix c   || true)" = "b" ]
    [ "$(readlink_posix c/1 || true)" = "../a/1" ]
    [ "$(readlink_posix aa/a || true)" = "../a" ]
    [ "$(readlink_posix aaa/aa || true)" = "../aa" ]

    [ "$(readlink_posix badfile || true)" = "../a/nonexist" ]
    [ "$(readlink_posix baddir || true)" = "../nonexist/1" ]
}


test_links() {
    cd $BATS_TMPDIR/test_readlinkf
    target="$(set -P; cd $BATS_TMPDIR; echo $PWD)/test_readlinkf"
    [ "$(eval $READLINK_F_EXEC a/1)" = "$target/a/1" ]
    [ "$(eval $READLINK_F_EXEC a/2)" = "$target/a/1" ]
    [ "$(eval $READLINK_F_EXEC a/3)" = "$target/a/1" ]
    [ "$(eval $READLINK_F_EXEC b/1)" = "$target/a/1" ]
    [ "$(eval $READLINK_F_EXEC c/1)" = "$target/a/1" ]
    [ "$(eval $READLINK_F_EXEC b/)" = "$target/b" ]
    [ "$(eval $READLINK_F_EXEC c/)" = "$target/b" ]
    [ "$(eval $READLINK_F_EXEC b/.)" = "$target/b" ]
    [ "$(eval $READLINK_F_EXEC c/.)" = "$target/b" ]
    [ "$(eval $READLINK_F_EXEC aa/a/.)" = "$target/a" ]
    [ "$(eval $READLINK_F_EXEC aa/a/..)" = "$target" ]
    [ "$(eval $READLINK_F_EXEC b/../aa/a/..)" = "$target" ]
    [ "$(eval $READLINK_F_EXEC aaa/aa/a/..)" = "$target" ]
    [ "$(eval $READLINK_F_EXEC aaa/aa/a/../..)" = "$(dirname $target)" ]
    [ "$(eval $READLINK_F_EXEC a/../b/../aaa/aa/a/../..)" = "$(dirname $target)" ]
    [ "$(eval $READLINK_F_EXEC .)" = "$target" ]
    [ "$(eval $READLINK_F_EXEC .////././///.)" = "$target" ]
    [ "$(eval $READLINK_F_EXEC nonexist)" = "$target/nonexist" ]
    [ "$(eval $READLINK_F_EXEC a/nonexist)" = "$target/a/nonexist" ]
    [ "$(eval $READLINK_F_EXEC b/nonexist)" = "$target/b/nonexist" ]
    [ "$(eval $READLINK_F_EXEC c/nonexist)" = "$target/b/nonexist" ]


    # not a directory
    eval run $READLINK_F_EXEC a/1/nonexist
    [ "$status" -eq 1 ]
    eval run $READLINK_F_EXEC b/1/nonexist
    [ "$status" -eq 1 ]
    eval run $READLINK_F_EXEC a/1/nonexist/..
    [ "$status" -eq 1 ]
    # not a directory with ending slash
    eval run $READLINK_F_EXEC a/1/
    [ "$status" -eq 1 ]

    eval run $READLINK_F_EXEC badfile
    [ "$status" -eq 1 ]
    eval run $READLINK_F_EXEC baddir
    [ "$status" -eq 1 ]

    # not exist directory
    eval run $READLINK_F_EXEC nonexist/1
    [ "$status" -eq 1 ]
}

@test "canonicalize_symlinks" {
    READLINK_F_EXEC="canonicalize_symlinks"
    test_links
}


@test "realpath" {
    READLINK_F_EXEC="realpath"
    test_links
}


@test "readlink -f" {
    READLINK_F_EXEC="readlink -f"
    test_links
}

