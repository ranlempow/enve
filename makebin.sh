#!/bin/sh

ENVE_HOME="$(dirname $0)/libexec"

. "$ENVE_HOME/enve/base"
. "$ENVE_HOME/enve/pathutils"

for sc in enve/enve; do
    name=$(basename $sc)
    target="$ENVE_HOME/../bin/$name"
    cat > "$target" <<EOF
#!/bin/sh


# $(type readlink_posix)
# $(type ensure_readlink_command)
# $(type split_path)
# $(type resolve_symlinks)

ENVE_HOME=\$(resolve_symlinks "\$0")
ENVE_HOME="\${ENVE_HOME%/bin/$name}/libexec"
export ENVE_HOME
exec "\$ENVE_HOME/$sc" "\$@"
EOF
    chmod 755 "$target"
done
