#!/bin/sh

if [ ! -e /tmp/waitpipe ]; then
	mkfifo /tmp/waitpipe
fi

if [ "${1:-}" = ignoreterm ]; then
	trap '' SIGINT
	trap '' SIGTERM
fi

echo "start 'caib'"

while read SIGNAL; do
    case "$SIGNAL" in
        *EXIT*)break;;
        *)echo "signal  $SIGNAL  is unsupported" >/dev/stderr;;
    esac
done < /tmp/waitpipe

