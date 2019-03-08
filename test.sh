#/bin/sh

tap=1

do_lint() {
    # SC2016: Expressions don't expand in single quotes, use double quotes for that.
    # SC2086: Double quote to prevent globbing and word splitting.
    # SC2119: Use hashstr "$@" if function's $1 should mean script's $1

    set -- 
    while read -r script; do
        set -- "$@" "$script"
    done <<EOF
$(find ./libexec/enve -maxdepth 1 -type f ! -name '.*' ! -name '*.ini' ! -name '_*')
$(find ./libexec/enve/script -maxdepth 1 -type f \
                ! -name '.*' ! -name '*.ini' ! -name '_*' \
                ! -name '*.applescript' ! -name '*.cmd')
EOF
    if [ -n "${tap:-}" ]; then
        echo "1..$#"
    fi
    cnt=1
    for file in "$@"; do
        
        output=$(shellcheck -x -s sh ${tap:+-f gcc} -e 2016 -e 2086 -e 2119 "$file" 2>&1)
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

do_test() {
    # TEST_SHELL=dash bats ${tap:+--tap} ./test/test_findutils.bats
    TEST_SHELL=dash bats ${tap:+--tap} ./test/test_*
    # TEST_SHELL=dash bats ./test/test_*
    # TEST_SHELL=bash bats ./test/test_*
    # TEST_SHELL=sh bats ./test/test_*
    # TEST_SHELL=zsh bats ./test/test_*
}


dummy_runner() {
    echo "1..3"
    echo "ok 1 dummy 1"
    echo "ok 2 dummy 2"
    echo "ok 3 dummy 3"
}

dummy_runner

