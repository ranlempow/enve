#!/bin/sh

set -e

# recommend PREFIX:
#   /usr/local      -> /var/lib/enve
#   /opt/enve       -> /var/opt/enve
#   /usr            -> /var/lib/enve


print_help() {
    printf '%s\n' \
        "usage: $0 [--libexecdir=libexec|lib] <prefix>" \
        "  e.g. $0 /usr/local" >&2
}


ENVE_ROOT="${0%/*}"

while [ $# -gt 0 ]; do
    case ${1:-} in
        # --libexecdir)
        #         LIBEXEC_DIR="$2"
        #         shift 2
        #     ;;
        --libexecdir=*)
                LIBEXEC_DIR=${1#--libexecdir=}
                shift
            ;;
        --symlinkbin)
                symlinkbin=/
                shift
            ;;
        --symlinkbin=*)
                symlinkbin=${1#--symlinkbin=}
                shift
            ;;
        -*)
                echo "unknown argument: $1" >&2
                print_help
                exit 1
            ;;
        *)
                PREFIX="$1"
            ;;
    esac
done

LIBEXEC_DIR=${LIBEXEC_DIR:-libexec}

if [ -z "$PREFIX" ]; then
    print_help
    exit 1
elif [ "$LIBEXEC_DIR" != "lib" ] || [ "$LIBEXEC_DIR" != "libexec" ]; then
    print_help
    exit 1
fi


install -d -m 755 "$PREFIX"/{bin,"$LIBEXEC_DIR"/enve,share/man/man{1,7}}
install -m 755 "$ENVE_ROOT"/bin/* "$PREFIX"/bin
# install -m 755 "$ENVE_ROOT"/libexec/enve/* "$PREFIX/$LIBEXEC_DIR"/enve
cp -R "$ENVE_ROOT"/libexec/enve "$PREFIX/$LIBEXEC_DIR"/enve
# install -m 644 "$ENVE_ROOT"/man/*.1 "$PREFIX"/share/man/man1
# install -m 644 "$ENVE_ROOT"/man/*.7 "$PREFIX"/share/man/man7
# install -Dm644 "$ENVE_ROOT"/LICENSE" "$PREFIX"/share/licenses/enve/LICENSE

echo "Installed Enve to $PREFIX/bin/enve"

if [ -n "${symlinkbin}" ]; then
    for path in "$ENVE_ROOT/bin"/*; do
        ln -s "$PREFIX/bin/${path##*/}" "${symlinkbin%%/}/bin/${path##*/}"
    done
    echo "Link ${symlinkbin%%/}/bin/enve to $PREFIX/bin/enve"
fi



