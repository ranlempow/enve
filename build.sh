#!/bin/sh

webouts=doc/html


_build_webpage() {
    sed -i -E -e 's@</style>@.mp { text-align: left; } #SYNOPSIS + pre code { font-weight:bold;color:#131211; }</style>@' "$1"
    sed -i -E -e ':a;N;$!ba;s@(<h2 id="SYNOPSIS">SYNOPSIS</h2>)\s*<p>@\1<pre>@' "$1"
    sed -i -E -e ':a;N;$!ba;s@\s*</p>\s*(<h2 id="DESCRIPTION">DESCRIPTION</h2>)@</pre>\1@' "$1"
}

_build_command() {
    rm -rf /tmp/enve-cmd-man-build
    mkdir -p /tmp/enve-cmd-man-build
    cp doc/src/zh_TW/index.txt /tmp/enve-cmd-man-build
    last=
    while IFS=: read -r cur other; do
        if [ -n "$last" ]; then
            # echo "$last-$cur"
            title=$(sed -n "$((last - 1))p" "$1")
            title=${title%%(*}
            sed -n "$((last - 1)),$((cur - 2))p" "$1" > "/tmp/enve-cmd-man-build/$title.1.md"
        fi
        last=$cur
    done <<EOF
$(grep -n '=============================================' doc/src/zh_TW/envecommand.7.md)
EOF
}



build_manpage() {
    # outs="${outs:-/tmp/x}"

    rm -rf $webouts
    rm -rf doc/man
    {
        printf %s\\n "envechangelog(7) - 更新訊息
=============================================
"
        cat CHANGELOG.md
    } > "doc/src/zh_TW/envechangelog.7.md"

    for d in $(cd doc/src; find . -depth 2); do
        base=$(basename "$d")
        if [ -n "${base##.*}" ] && [ -z "${base##*.md}" ]; then
            dir=$(dirname "$d")
            echo "$d"
            if [ "$base" = "envecommand.7.md" ]; then
                _build_command "doc/src/$d"
                for e in $(ls /tmp/enve-cmd-man-build); do
                    if [ "$e" = "index.txt" ]; then
                        continue
                    fi
                    echo "$e"
                    mkdir -p "doc/man/$dir/man1"
                    ronn --pipe --manual "enve manual" --roff "/tmp/enve-cmd-man-build/$e" >"doc/man/$dir/man1/${e%.*}"
                    mkdir -p "$webouts/man/$dir"
                    ronn --pipe --manual "enve manual" --html "/tmp/enve-cmd-man-build/$e" >"$webouts/man/$dir/${e%.*}.html"
                    _build_webpage "$webouts/man/$dir/${e%.*}.html"
                done
                continue
            elif [ "$base" != "index.md" ]; then
                num=${base%.*}
                num=${num##*.}
                mkdir -p "doc/man/$dir/man$num"
                ronn --pipe --manual "enve manual" --roff "doc/src/$d" >"doc/man/$dir/man$num/${base%.*}"
            fi
            mkdir -p "$webouts/man/$dir"
            ronn --pipe --manual "enve manual" --html "doc/src/$d" >"$webouts/man/$dir/${base%.*}.html"
            _build_webpage "$webouts/man/$dir/${base%.*}.html"
        fi
    done
}

upload_ghpage() {
    echo "$GHPAGE_CNAME" > "$webouts/CNAME"
    cat > "$webouts/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="refresh" content="0; url=man/zh_TW/index.html" />
</head>
<body>
</body>
</html>

EOF
    repo=$(git remote get-url origin)
    cd "$(dirname "$webouts")"
    NODE_DEBUG=gh-pages gh-pages --dist "$(basename "$webouts")" --repo "$repo" --cache "/tmp/cache"
}

build_bin() {
    (
    ENVE_HOME="$(dirname $0)/libexec"

    . "$ENVE_HOME/enve/baselib"
    . "$ENVE_HOME/enve/pathutils"

    for sc in enve/enve; do
        name=$(basename $sc)
        target="$ENVE_HOME/../bin/$name"
        cat > "$target" <<EOF
#!/bin/sh


# $(type readlink_posix)
# $(type ensure_readlink_command)
# $(type split_path)
# $(type _cd_target)
# $(type resolve_symlinks)

ENVE_HOME=\$(resolve_symlinks "\$0")
ENVE_HOME="\${ENVE_HOME%/bin/$name}/libexec"
export ENVE_HOME
exec "/bin/sh" "\$ENVE_HOME/$sc" "\$@"
EOF
        chmod 755 "$target"
    done
    )
}

build_installer() {
    (
    ENVE_HOME="$(dirname $0)/libexec"

    . "$ENVE_HOME/enve/baselib"
    . "$ENVE_HOME/enve/pathutils"
    . "$ENVE_HOME/enve/gitlib"

    . "$ENVE_HOME/enve/core/base/enve.setup" noop

    cat > "$(dirname $0)/installer.sh" <<EOF
#!/bin/sh

# $(type clone_to)
# $(type install_enve_tar)

EOF
    cat "$(dirname $0)/installer" >> "$(dirname $0)/installer.sh"
    )
}

# build_bin
build_installer
# build_manpage
# upload_ghpage

