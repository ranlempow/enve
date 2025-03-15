
if [ -z "${1:-}" ]; then
	ENV=./libexec/enve/shielding.sh \
	EXIT=1 EXEC_SHIELD=1 RC_CMD='sleep 10' INT_AS_TSTP=1 /bin/sh -i
elif [ "$1" = normal ]; then
	ENV=./libexec/enve/shielding.sh \
	NOASK=1  EXEC_SHIELD=1 RC_CMD='./test/signal_waiter.sh'  /bin/sh -i
elif [ "$1" = deadlock ]; then
	ENV=./libexec/enve/shielding.sh \
	NOASK=1  EXEC_SHIELD=1 RC_CMD='./test/signal_waiter.sh ignoreterm'  /bin/sh -i
fi
