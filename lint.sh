#/bin/sh


lint() {
    # SC2016: Expressions don't expand in single quotes, use double quotes for that.
    # SC2086: Double quote to prevent globbing and word splitting.
    # SC2119: Use hashstr "$@" if function's $1 should mean script's $1

    gccformat=
    for file in \
        $(find ./libexec/enve -maxdepth 1 -type f ! -name '.*' ! -name '*.ini' ! -name '_*') \
        $(find ./libexec/enve/script -maxdepth 1 -type f \
                ! -name '.*' ! -name '*.ini' ! -name '_*' \
                ! -name '*.applescript' ! -name '*.cmd')
    do
        shellcheck -x -s sh ${gccformat:+-f gcc} -e 2016 -e 2086 -e 2119 "$file"
        echo "shellcheck [$?] $file " >&2
    done
}