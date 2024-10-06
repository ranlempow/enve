#!/usr/bin/env bats

load common

ENVE_HOME="$BATS_TEST_DIRNAME/../libexec"

@test "b1" {
    . "$ENVE_HOME/enve/baselib"

    hascmd bats
    ! hascmd bats-xxxxxx
    # also detect shell function
    hascmd hascmd

    [ "$(echo | md5sum)" = "68b329da9893e34099c7d8ad5cb9c940  -" ]
    [ "$(echo | hashstr)" = "68b329da9893e34099c7d8ad5cb9c940" ]

    # tac will respact origin newline
    [ "$(printf %s\\n%s a b | tac)" = "ba" ]
    [ "$(printf %s\\n%s\\n a b | tac)" = "b${newl}a" ]

    ENVE_CACHED_OS=x
    fast_get_system
    [ "$ENVE_CACHED_OS" = "x" ]

    ENVE_CACHED_OS=
    [ -z "${ENVE_CACHED_OS:-}" ]
    fast_get_system
    [ -n "$ENVE_CACHED_OS" ]

    s="a1b1a"
    replace "1" "2"
    [ "$s" = "a2b2a" ]
    replace "2" ""
    [ "$s" = "aba" ]
    replace "" "xxx"
    [ "$s" = "aba" ]
    replace "a" "c" 1
    [ "$s" = "cba" ]

    rm -f "$BATS_TMPDIR/only_empty"
    write_file_only_nonexist "$BATS_TMPDIR/only_empty"
    ! write_file_only_nonexist "$BATS_TMPDIR/only_empty"
    [ "$(cat "$BATS_TMPDIR/only_empty" | wc -c)" -eq 0 ]

    rm -f "$BATS_TMPDIR/only_text"
    write_file_only_nonexist "$BATS_TMPDIR/only_text" "abc"
    [ "$(cat "$BATS_TMPDIR/only_text" | wc -c)" -eq 3 ]
    [ "$(cat "$BATS_TMPDIR/only_text")" = "abc" ]

    VAR1=1
    deftext=
    fast_append_variable_quote VAR1
    [ "$deftext" = "VAR1='1'" ]
    VAR2="'x'"
    fast_append_variable_quote VAR2
    [ "$deftext" = "VAR1='1' VAR2=''\\''x'\\'''" ]

    echo xx > "$BATS_TMPDIR/fast_readtext"
    fast_readtext "$BATS_TMPDIR/fast_readtext"
    [ "$text" = "xx$newl" ]

    d=a/b/c
    fast_dirname
    [ "$d" = "a/b" ]
    fast_basename
    [ "$d" = "b" ]

    # mkstemp() {
    #     _mkstemp create_file_mutex "$@"
    # }
    # mkdtemp() {
    #     _mkstemp create_dir_mutex "$@"
    # }

    yes | any_key_continue

    # obtain_pidlock() {
    # release_pidlock() {
    # obtain_filelock() {
    # release_filelock() {

}


@test "fast_sleep" {
    . "$ENVE_HOME/enve/baselib"

    tm1=$(date +%s)
    fast_sleep 1
    tm2=$(date +%s)
    [ $((tm2 - tm1)) -eq 1 ]
}

@test "fast_timestamp_ms" {
    . "$ENVE_HOME/enve/baselib"

    tm=
    fast_timestamp_ms
    tm2=$tm
    sleep 1
    fast_timestamp_ms
    [ "$tm" != "$tm2" ]
    [ ${#tm} -eq ${#tm2} ]
}
