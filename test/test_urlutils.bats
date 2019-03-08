#!/usr/bin/env bats

load common

setup() {
    mkstab ../libexec/enve/urlutils \
        parse_unified_download unified_fetch

    fixture="$BATS_TMPDIR/envetest/fixture"
    # rm -rf "$fixture"
    rm -rf "$BATS_TMPDIR/envetest"
    mkdir -p "$fixture"
    echo "This is just a test repository to work with Git commands." > "$fixture/README"
    
    (
        cd "$fixture"
        zip -r "$BATS_TMPDIR/envetest/fixture.zip" . >/dev/null
        tar -cvf "$BATS_TMPDIR/envetest/fixture.tar" . >/dev/null
        tar -zcvf "$BATS_TMPDIR/envetest/fixture.tar.gz" . >/dev/null
        tar -jcvf "$BATS_TMPDIR/envetest/fixture.tar.bz2" . >/dev/null
        tar -Jcvf "$BATS_TMPDIR/envetest/fixture.tar.xz" . >/dev/null
    )
    
    gzip -c "$fixture/README" > "$BATS_TMPDIR/envetest/README.gz"
    bzip2 -zc "$fixture/README" > "$BATS_TMPDIR/envetest/README.bz2"
    xz -zc "$fixture/README" > "$BATS_TMPDIR/envetest/README.xz"
}


@test "simple unified_fetch" {
    src="$BATS_TMPDIR/fetch_src"
    dest="$BATS_TMPDIR/fetch_dest"
    echo xxx > $src
    rm -rf "$dest"
    url=$src dl='cp "$url" "$dest"' dest=$dest decomp= keepdir= unified_fetch
    [ "$(cat "$dest")" = "xxx" ]
}


exam() {
    echo "EXAM: $1" >&2
    [ "$(cat "$1")" = "This is just a test repository to work with Git commands." ]
}

test_fetch() {
    FETCH_DEBUG=1 parse_unified_download "$@" >&2
    dest=$(unified_fetch "$@")
    exam "$dest${EXAM:+/}${EXAM:-}"
    
}

@test "normal file" {
    test_fetch "$fixture/README" "%cache" "file"
}
@test "normal dir" {
    EXAM=README test_fetch "$fixture" "%cache" "dir"
}
@test "normal URL file" {
    test_fetch "file://$fixture/README" "%cache" "file"
}
@test "relative file" {
    cd $fixture
    test_fetch "./README" "%cache" "file"
}
@test "normal http file" {
    test_fetch "https://raw.githubusercontent.com/ranlempow/test-repository/master/README" \
        "%cache" "file"
}

@test "non-cache dest file" {
    test_fetch "$fixture/README" "$BATS_TMPDIR/envetest/dest_README" "file"
}
@test "non-cache dest dir" {
    EXAM=README test_fetch "$fixture" "$BATS_TMPDIR/envetest/dest_fixture" "dir"
}
@test "tmp dest file" {
    test_fetch "$fixture/README" "%tmp" "file"
}
@test "tmp dest dir" {
    EXAM=README test_fetch "$fixture" "%tmp" "dir"
}
@test "auto dest file" {
    test_fetch "$fixture/README" "%auto" "file"
}
@test "auto dest dir" {
    EXAM=README test_fetch "$fixture" "%auto" "dir"
}



@test "local gz file" {
    test_fetch "$BATS_TMPDIR/envetest/README.gz" "%cache" "file"
}
@test "local bz2 file" {
    test_fetch "$BATS_TMPDIR/envetest/README.bz2" "%cache" "file"
}
@test "local xz file" {
    test_fetch "$BATS_TMPDIR/envetest/README.xz" "%cache" "file"
}

@test "local zip file" {
    EXAM=README test_fetch "$BATS_TMPDIR/envetest/fixture.zip" "%cache" "dir"
}
@test "local tar.gz file" {
    EXAM=README test_fetch "$BATS_TMPDIR/envetest/fixture.tar.gz" "%cache" "dir"
}
@test "local tar.bz2 file" {
    EXAM=README test_fetch "$BATS_TMPDIR/envetest/fixture.tar.bz2" "%cache" "dir"
}
@test "local tar.xz file" {
    EXAM=README test_fetch "$BATS_TMPDIR/envetest/fixture.tar.xz" "%cache" "dir"
}


@test "git repo format-1" {
    EXAM=README test_fetch "git+git@github.com:ranlempow/test-repository.git" "%cache" "dir"
}
@test "git repo format-2" {
    EXAM=README test_fetch "git+ssh://git@github.com/ranlempow/test-repository.git" "%cache" "dir"
}
@test "git repo format-3" {
    EXAM=README test_fetch "git+https://github.com/ranlempow/test-repository" "%cache" "dir"
}
@test "git repo format-4" {
    EXAM=README test_fetch "git+https://github.com/ranlempow/test-repository#master" "%cache" "dir"
}
@test "git repo format-5" {
    EXAM=README test_fetch \
        "git+https://github.com/ranlempow/test-repository#e53f405732f27aeeaa04ac07a542372d6f4b1a88" \
        "%cache" "dir"
}

@test "ftp file" {
    set -- "ftp://speedtest.tele2.net/1KB.zip" "%cache" "file"
    FETCH_DEBUG=1 parse_unified_download "$@" >&2
    dest=$(unified_fetch "$@")
    stat "$dest" | grep 'Size: 1024'
}

@test "zip http dir" {
    EXAM=test-repository-master/README test_fetch \
        "https://github.com/ranlempow/test-repository/archive/master.zip" "%cache" "dir"
}

@test "tar.gz http dir" {
    EXAM=test-repository-9.0.99/README test_fetch \
        "https://github.com/ranlempow/test-repository/archive/v9.0.99.tar.gz" "%cache" "dir"
}


