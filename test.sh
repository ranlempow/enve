#/bin/sh

check_shebang() {
    other_shebang=
    for file in $(find . -type f); do
        if [ -n "${file%%\./\.*}" ]; then
            read -r firstline < "$file"
            if [ -n "$firstline" ] && [ -z "${firstline%%\#\!*}" ]; then
                shebang=${firstline#\#\!}
                case $shebang in
                    /bin/sh) ;;
                    # "/usr/bin/env bash") ;;
                    "/usr/bin/osascript") ;;
                    "/usr/bin/env enve") ;;
                    "/usr/bin/env bats") ;;
                    *)
                            echo "#!$shebang in $file"
                            other_shebang=1
                        ;;
                esac
            fi
        fi
    done
    echo "### Check Shebang"
    if [ -n "${tap:-}" ]; then
        echo "1..1"
        if [ -z "$other_shebang" ]; then
            echo "${tap:+ok 1 }shebang "
        else
            echo "${tap:+not ok 1 }shebang [1]"
        fi
    fi
    if [ -n "$other_shebang" ]; then
        return 1
    fi
}


check_style() {
    echo "### Check Style"
    if [ -n "${tap:-}" ]; then
        echo "1..1"
        result=$(eclint check 2>&1)
        retcode=$?
        if [ $retcode -eq 0 ]; then
            echo "${tap:+ok 1 }eclint "
        else
            echo "${tap:+not ok 1 }eclint [$retcode]"
            while read -r line; do
                echo "# $line"
            done <<EOF
$result
EOF
        fi
    else
        eclint check
    fi
}

_exclude_libexec() {
    for d in ./*; do
        if [ "$d" != "./libexec" ]; then
            echo "$d"
        fi
    done
}

_cloc() {
    if [ -n "${tap:-}" ]; then
        cloc --quiet "$@" 2>/dev/null | while read -r line; do
            echo "# $line"
        done
    else
        cloc "$@" 2>/dev/null
    fi
}

check_cloc() {
    echo "### Total Code ###"
    _cloc .
    echo "#"
    echo "### Libexec Libs Code ###"
    _cloc $(find ./libexec/enve -type f -depth 1)
    echo "#"
    echo "### Libexec Others Code ###"
    _cloc $(find ./libexec/enve/*/ -type f)
    echo "#"
    echo "### Root Code ###"
    _cloc $(find $(_exclude_libexec) -type f)
}


check_lint() {
    # SC2016: Expressions don't expand in single quotes, use double quotes for that.
    # SC2086: Double quote to prevent globbing and word splitting.
    # SC2119: Use hashstr "$@" if function's $1 should mean script's $1
    # SC2043: This loop will only ever run once for a constant value. Did you perhaps mean to loop over dir/*, $var or $(cmd)?

    set --
    while read -r script; do
        if [ -n "$script" ]; then
            set -- "$@" "$script"
        fi
    done <<EOF
$(find ./libexec/enve -depth 1 -type f \
        ! -name '.*' ! -name '*.ini' ! -name '_*' \
        ! -name 'isolation' \
        )
$(find  ./libexec/enve/cilib \
        ./libexec/enve/preset \
        ./libexec/enve/core \
        ./libexec/enve/thirdparty \
        ./libexec/enve/contrib \
        -type f \
        ! -name '.*' ! -name '*.ini' ! -name '_*' \
        ! -name 'inputrc' ! -name '*.nix' ! -name '*.conf' \
        )
# $(find ./libexec/enve/script -type f \
#         ! -name '.*' ! -name '*.ini' ! -name '_*' \
#         ! -name '*.applescript' ! -name '*.cmd' ! -name '*.bat' \
#         )
EOF

# $(find ./libexec/enve -maxdepth 1 -type f ! -name '.*' ! -name '*.ini' ! -name '_*')
# $(find ./libexec/enve/script -maxdepth 1 -type f \
#                 ! -name '.*' ! -name '*.ini' ! -name '_*' \
#                 ! -name '*.applescript' ! -name '*.cmd')

    if [ -n "${tap:-}" ]; then
        echo "1..$#"
    fi
    cnt=1
    for file in "$@"; do
        output=$(shellcheck --color=always -x -s sh ${tap:+-f gcc} -e 2016 -e 2086 -e 2119 -e 2043 "$file" 2>&1)
        retcode="$?"
        if [ $retcode -eq 0 ]; then
            echo "${tap:+ok $cnt }shellcheck $file"
        else
            echo "${tap:+not ok $cnt }shellcheck [$retcode] $file"
            while read -r line; do
                echo "${tap:+# }$line"
            done <<EOF
$output
EOF
        fi
        cnt=$((cnt + 1))
    done
}

check_test() {
    echo "### Test At Bash ###"
    _cloc .
    TEST_SHELL=bash bats ${tap:+--tap} ./test/test_*
}

check_test_all_shell() {
    echo "### Test At Dash ###"
    TEST_SHELL=dash bats ${tap:+--tap} ./test/test_*
    echo "#"
    echo "### Test At Bash ###"
    TEST_SHELL=bash bats ${tap:+--tap} ./test/test_*
    echo "#"
    echo "### Test At sh ###"
    TEST_SHELL=sh bats ${tap:+--tap} ./test/test_*
    echo "#"
    echo "### Test At Zsh ###"
    TEST_SHELL=zsh bats ${tap:+--tap} ./test/test_*
}

check_all() {
    for t in shebang style cloc lint test; do
        "check_$t"
    done
}

check_stdio() {
    echo "# write to stdout"
    echo "# write to error" >&2
}

# check_dummy_runner() {
#     echo "1..3"
#     echo "ok 1 dummy 1"
#     echo "ok 2 dummy 2"
#     echo "ok 3 dummy 3"
# }

tap=${tap:-}
"check_${1:-shell}"

