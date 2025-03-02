#!/usr/bin/env bats

load common
ENVE_VERBOSE=TRACE

# setup() {
#     mkstab ../libexec/enve/findutils \
#         fnmatch fnmatch_pathname_transform \
#         make_gitignore_filter gitignore_filter \
#         files_stats files_stats_contents
# }

@test "build_minmax_slashs" {
    . "$ENVE_HOME/enve/findutils"
    build_minmax_slashs 'a/b/c/d'
    [ "$maxp" = '/*/*/*/*' ]
    [ "$minp" = '/*/*/*' ]
}

@test "build_gitignore_to_find_logic" {
    . "$ENVE_HOME/enve/findutils"
    build_gitignore_to_find_logic "root" "**" "--action"
    [ "$ARGSTR" = "'-path' 'root/*' '-name' '*' '-prune' '-o'" ]
    build_gitignore_to_find_logic "root" "!**" "--action"
    [ "$ARGSTR" = "'-path' 'root/*' '-name' '*' '--action' '-o'" ]
    build_gitignore_to_find_logic "root" "a/*/b/*/c" "--action"
    [ "$ARGSTR" = "'(' '!' '-path' 'root/*/*/*/*/*/*' '-path' 'root/*/*/*/*/*' '-path' 'root/a/*/b/*/*' '-name' 'c' '-prune' ')' '-o'" ]
}

@test "gitignore_ls2" {
    . "$ENVE_HOME/enve/findutils"
    list=$(gitignore_ls2 "$ENVE_HOME" --ignore "enve/*/macos/*" --ignore "_*" -name "*.setup")
    enve_home=$(normalize "$ENVE_HOME")
    names=
    while read -r filename; do
        filename=${filename#"${enve_home}/enve/core/"}
        names=${names}${filename}${newl}
    done <<EOF
$list
EOF
    echo "$list"
    [ "$names" = 'nix/nix.setup
terminal/terminal.setup
pyvenv/python-msvc.setup
base/hostpkgs.setup
base/enve.setup
' ]
}

@test "gitignore_walk" {
    . "$ENVE_HOME/enve/prjlib"
    devfile=$(normalize "$ENVE_HOME/../.dev")
    gitignore_walk "$ENVE_HOME/.." -print | grep -v "$devfile"
}

@test "fnmatch" {
    . "$ENVE_HOME/enve/findutils"

    fnmatch 'a*c' 'abbbc'
    fnmatch 'a*c' 'ac'
    fnmatch 'a?c' 'abc'
    fnmatch 'a[b]c' 'abc'
    fnmatch 'a[a-c]c' 'abc'
    ! fnmatch 'a[xy]c' 'abc'

    fnmatch 'a[b/]c' 'abc'
    fnmatch 'a[b/]c' 'a/c'

    fnmatch '.a?c' '.abc'
    fnmatch '?a?c' '.abc'

    fnmatch 'a[!z]c' 'abc'
    # non-posix but bash supported
    # fnmatch 'a[^z]c' 'abc'

    fnmatch 'a[[:lower:]]c' 'abc'
    fnmatch 'a[![:upper:]]c' 'abc'
    ! fnmatch 'a[[:upper:]]c' 'abc'

    fnmatch 'a\[\!z\]c' 'a[!z]c'
    fnmatch 'a\\c' 'a\c'


    # shopt -s extglob
    # {
    #     fnmatch 'a+(b)c' 'abbbc'
    #     fnmatch 'a+(b+(1))c' 'ab1b11b111c'
    #     ! fnmatch 'a+(b)c' 'abccc'
    # }
    # {
    #     fnmatch 'a/+([!/])/+([!/])/c' 'a/b/b/c'
    #     fnmatch 'a/+([!/])123/c' 'a/b123/c'
    #     fnmatch 'a/@(+(?)/|)c' 'a/c'
    #     fnmatch 'a/@(+(?)/|)c' 'a/b/c'
    #     fnmatch 'a/@(+(?)/|)c' 'a/b/b/c'
    #     ! fnmatch 'a/+([!/])/+([!/])/c' 'a/b/b/b/c'
    #     ! fnmatch_pathname_transform 'a/**b/c'
    #     [ "$(fnmatch_pathname_transform 'a/*/c')" = 'a/+([!/])/c' ]
    #     [ "$(fnmatch_pathname_transform 'a/b/?c')" = 'a/b/@([!/])c' ]
    #     [ "$(fnmatch_pathname_transform 'a/**/c')" = 'a/@(+(?)/|)c' ]
    # }
}


@test "make_gitignore_filter" {
    . "$ENVE_HOME/enve/findutils"

    ENVE_VERBOSE=TRACE

    list='abc
123
d/e/f
'
    # gitignore_include "$(printf %s\\n%s\\n '!abc' 'def')" "$list"
    # gitignore_exclude "$(printf %s\\n%s\\n 'a*c' '!abc' 'def')" "$list"

    [ "$(gitignore_exclude "$(printf %s\\n%s\\n 'abc' 'd/e/f')" "$list")" = \
      "123" ]
    [ "$(gitignore_exclude "$(printf %s\\n%s\\n 'a*c' '!abc' 'd/e/f')" "$list")" = \
      "123${newl}abc" ]
    [ "$(gitignore_exclude "" "$list")" = \
      "abc${newl}123${newl}d/e/f" ]
    [ "$(gitignore_include "" "$list")" = \
      "" ]
    [ "$(gitignore_include "d/**$newl" "$list")" = \
      "d/e/f" ]
    [ "$(gitignore_include "**/f$newl" "$list")" = \
      "d/e/f" ]
    [ "$(gitignore_include "d/**/f$newl" "$list")" = \
      "d/e/f" ]
    [ "$(gitignore_include "d/d/**/f$newl" "$list")" = \
      "" ]
    [ "$(gitignore_include "???${newl}!abc${newl}" "$list")" = \
      "123" ]

}


@test "files_stats" {
    . "$ENVE_HOME/enve/findutils"

    rm -rf /tmp/files_stats
    mkdir -p /tmp/files_stats
    touch -t 0001011200.00 /tmp/files_stats/abc
    touch -t 0001011200.00 /tmp/files_stats
    files_stats /tmp/files_stats >&2
    # false
    # [ "$(files_stats /tmp/files_stats)" = "$(printf %s\\n%s \
    #     "d 755 $(id -u) 0 0 2000/01/01 12:00:00.0000000000 ." \
    #     "f 644 $(id -u) 0 0 2000/01/01 12:00:00.0000000000 ./abc")" ]

    [ "$(files_stats /tmp/files_stats)" = "$(printf %s\\n%s \
        "-rw-r--r-- - $(id -u) 0 0 Jan 1 2000 ./abc")" ]

    # [ "$(files_stats_contents /tmp/files_stats)" = "$(printf %s\\n%s\\n%s \
    #     "d 755 $(id -u) 0 0 2000/01/01 12:00:00.0000000000 ." \
    #     "f 644 $(id -u) 0 0 2000/01/01 12:00:00.0000000000 ./abc" \
    #     "d41d8cd98f00b204e9800998ecf8427e  ./abc")" ]

    [ "$(files_stats_contents /tmp/files_stats)" = "$(printf %s\\n%s \
        "-rw-r--r-- - $(id -u) 0 0 Jan 1 2000 ./abc" \
        "d41d8cd98f00b204e9800998ecf8427e  ./abc")" ]

    # [ "$(files_stats_contents /tmp/files_stats /tmp/files_stats/abc)" = "$(printf %s\\n%s\\n%s\\n%s\\n%s \
    #     "d 755 $(id -u) 0 0 2000/01/01 12:00:00.0000000000 ." \
    #     "f 644 $(id -u) 0 0 2000/01/01 12:00:00.0000000000 ./abc" \
    #     "d41d8cd98f00b204e9800998ecf8427e  ./abc" \
    #     "f 644 $(id -u) 0 0 2000/01/01 12:00:00.0000000000 /tmp/files_stats/abc" \
    #     "d41d8cd98f00b204e9800998ecf8427e  /tmp/files_stats/abc")" ]
    files_stats_contents /tmp/files_stats /tmp/files_stats/abc >&2
    [ "$(files_stats_contents /tmp/files_stats /tmp/files_stats/abc)" = "$(printf %s\\n%s\\n%s\\n%s\\n%s \
        "-rw-r--r-- - $(id -u) 0 0 Jan 1 2000 ./abc" \
        "d41d8cd98f00b204e9800998ecf8427e  ./abc" \
        "-rw-r--r-- - $(id -u) 0 0 Jan 1 2000 /tmp/files_stats/abc" \
        "d41d8cd98f00b204e9800998ecf8427e  /tmp/files_stats/abc")" ]
}




