#!/usr/bin/env bats

load common

setup() {
    mkstab ../libexec/enve/findutils \
        fnmatch fnmatch_pathname_transform \
        make_gitignore_filter gitignore_filter \
        files_stats files_stats_contents

}


@test "fnmatch" {

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

    # make_gitignore_filter "$(printf abc\\ndef\\n)" >&2

    [ "$(printf abc\\n123\\ndef\\n | gitignore_filter "$(printf %s\\n%s\\n 'abc' 'def')")" = "123" ]
    # shopt -s extglob
    [ "$(printf abc\\n123\\ndef\\n | gitignore_filter "$(printf %s\\n%s\\n 'a*' 'd?f')")" = "123" ]
    [ "$(printf abc/def\\n123\\ndef\\n | gitignore_filter "$(printf %s\\n '**/def')")" = "123" ]
    [ "$(printf abc/def\\n123\\n | gitignore_filter "$(printf %s\\n 'abc/**')")" = "123" ]
    [ "$(printf abc/def/123\\n123\\n | gitignore_filter "$(printf %s\\n '**/def/**')")" = "123" ]

    [ "$(printf abc/def\\n123\\ndef\\n | gitignore_filter "$(printf %s\\n%s\\n '**/def' '!def')")" = "123
def" ]

    [ "$(printf abc\\n123\\ndef\\n | gitignore_filter "")" = "abc
123
def" ]

    [ "$(printf abc\\n123\\ndef\\n | gitignore_filter "$(printf %s\\n%s\\n '*' '!abc')")" = "abc" ]

}

@test "files_stats" {

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




