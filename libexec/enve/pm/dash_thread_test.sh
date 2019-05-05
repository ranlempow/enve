##!/usr/bin/env dash

# shellcheck disable=2034
for i in 1 2 3 4 5; do
    {
        sleep 1
        pid=$(exec sh -c 'echo "$PPID"')
        echo main:$$,$pid,$BASHPID
        ( echo $$,$BASHPID );
    } &
    echo ch:$!
done
