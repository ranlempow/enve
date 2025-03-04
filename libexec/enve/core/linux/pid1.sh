#!/bin/sh

reaped_zombies_or_exec() {
    while read -r t_pid t_ppid t_state; do
        if [ "$t_ppid" == "$$" ]; then
            if [ -n "$t_state" ] && [ -z "${t_state##*Z*}" ]; then
                wait $t_pid
            elif [ $@ -gt 0 ]; then
                "$@" $t_pid
            fi
        fi
    done <<EOF
$(ps -eo pid,ppid,state)
EOF
}


forward_signal() {
    kill -$CHILD_PID $1
}

shutdown() {
    trap - $1
    reaped_zombies_or_exec kill -$1
    sleep 2
    reaped_zombies_or_exec kill -KILL
    exit $((128 + $(kill -l 1)))
}

if [ $# -gt 0 ]; then
    # 守護模式

    # Suspending self due to TTY signal
    trap 'kill -STOP $$' TSTP TTOU TTIN
    trap reaped_zombies_or_exec CHLD
    trap 'forward_signal TERM' TERM
    trap 'forward_signal HUP' HUP
    trap 'forward_signal INT' INT
    "$@" &
    CHILD_PID=$!
    while true; do
        wait "$CHILD_PID"
        if ! kill -0 $pid; then
            # 信號中斷並且處理結束之後，wait(1)會返回
            # 只有SIGCHLD才代表子行程結束。回傳真正的終止碼。
            # 其他的情形，回傳讓父行程中斷的信號種類
            wait $pid
            retcode=$?
            exit $retcode
        fi
    done
else
    # 虛擬機模式
    trap reaped_zombies_or_exec CHLD
    trap 'shutdown TERM' TERM
    while read; do
        :
    done
fi

