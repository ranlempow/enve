
replace() {
    if [ -z "$1" ]; then
        return 0
    fi

    count=${3:-}
    i=0
    v=
    while [ "$s" != "${s%%"$1"*}" ]; do
        v="$v${s%%"$1"*}$2"
        s="${s#*"$1"}"
        i=$((i+1))
        if [ -n "$count" ] && [ "$count" -eq "$i" ]; then
            break
        fi
    done
    s="$v$s"
    unset count i v
}

fast_append_argument_quote2() {
    s=$1
    replace "'" "'\\''"
    ARGSTR="${ARGSTR:-}${ARGSTR:+ }'$s'"
    unset s
}


check_writable() {
    [ -n "$1" ] && [ ! -e "$1" ] || { [ -w "$1" ] && [ -f "$1" ]; }
}

simply_timestamp() {
    read -r mm ss <<EOF
$(date +"%M %S")
EOF
    tm=$((mm*60 + ss))
}


run() {
    # 需要這個才可以讓pid運作正確
    set +o posix
    if [ -z "${first_run:-}" ]; then
        first_run=1
    else
        printf "restarting...  $*\n"
    fi
    if [ -n "${PIDFILE:-}" ] && check_writable "$PIDFILE"; then
        (subshell_pid=${BASHPID:-$(exec sh -c 'echo "$PPID"')}
         echo $subshell_pid > "$PIDFILE"
         exec "$@") &
        pid=$!
    else
        (exec "$@") &
        pid=$!
    fi
    retcode=
    while true; do
        if [ -n "${kill_timeout:-}" ] && kill -0 $pid; then
            simply_timestamp
            if [ "$kill_timeout" -gt 1800 ] &&
                [ $tm -gt 1800 ] && [ $tm -gt $kill_timeout ]; then
                kill -KILL $pid
                kill_timeout=
            elif [ "$kill_timeout" -lt 1800 ] &&
                 [ $tm -lt 1800 ] && [ $tm -gt $kill_timeout ]; then
                kill -KILL $pid
                kill_timeout=
            else
                sleep 1
            fi
        else
            wait $pid
        fi
        if ! kill -0 $pid 2>/dev/null; then
            # 信號中斷並且處理結束之後，wait(1)會返回
            # 只有SIGCHLD才代表子行程結束。回傳真正的終止碼。
            # 其他的情形，回傳讓父行程中斷的信號種類
            wait $pid
            retcode=$?
            break
        fi
    done
    if check_writable "${EXITFILE:-}"; then
        echo $retcode > "$EXITFILE"
    fi
    on_run_exit "$retcode"
}


_shield() {
    running=1
    while true; do
        # rundone=
        restart=
        run "$@"
        if [ -n "${NOASK:-}" ]; then
            exitsig=$(kill -l $retcode)
            if [ -n "${wait_INT:-}" ] && [ "$exitsig" = INT ]; then
                trap - SIGINT
                kill -INT $$
            elif [ -n "${wait_TERM:-}" ] && [ "$exitsig" = TERM ]; then
                trap - SIGTERM
                kill -TERM $$
            elif [ -n "${wait_HUP:-}" ] && [ "$exitsig" = HUP ]; then
                trap - SIGHUP
                kill -HUP $$
            elif [ -n "${wait_QUIT:-}" ] && [ "$exitsig" = QUIT ]; then
                trap - SIGQUIT
                kill -QUIT $$
            fi
            unset wait_INT wait_TERM wait_HUP wait_QUIT
        else
            if [ "$retcode" -ne 0 ]; then
                printf "\nShielded command exit code is $retcode\n"
                printf "Press Ctrl+D to exit, or press Ctrl+R to restart\n"
                while read -n1 press; do
                    if [ "$press" == "$ctrlR" ]; then
                        restart=1
                        break
                    elif [ "$press" == "$ctrlD" ]; then
                        break
                    fi
                    printf "Press Ctrl+D to exit, or press Ctrl+R to restart\n"
                done
            fi
        fi
        if [ -n "$restart" ]; then
            continue
        else
            break
        fi
    done
    running=
    if [ -n "$EXIT" ]; then
        exit $retcode
    fi
}

trap_signal() {
    if [ -n "${pid:-}" ]; then
        kill -$1 $pid
        kill -CONT $pid
        eval wait_$1=1
    fi
}

restart() {
    # if [ -z "${running:-}" ]; then
    #     restart
    # fi
    eval _shield $RC_CMD
}

setup_shield() {
    ctrl_chars=$(printf '\022x\004')
    ctrlR=${ctrl_chars%%x*}
    ctrlD=${ctrl_chars##*x}

    trap "trap_signal INT" INT
    trap "trap_signal TERM" TERM
    trap "trap_signal HUP" HUP
    trap "trap_signal QUIT" QUIT
    trap "kill -TERM \$pid; kill -CONT \$pid; restart=1" USR1

    # trap "rundone=1" SIGCHLD
}

# TODO: hook

on_run_exit() {
    : # [[RUN_EXIT_TEMPLATE]]
}

on_shell_exit() {
    : # [[SHELL_EXIT_TEMPLATE]]
}


# TODO:
#   (O)pidfile and exitcode
#   (O)等待確認
#   (O)返回命令列
#   (O)命令列重啟
#   (O)信號傳遞
#   (O)信號重啟
#   監視重啟
#   重啟過程符合PM_HOME規範
#   (O)超時強制結束

get_current_pid() {
    subshell_pid=${BASHPID:-$(exec sh -c 'echo "$PPID"')}
}

if [ -z ${RC_CMD:-} ]; then
    trap on_shell_exit INT TERM HUP QUIT EXIT
    if [ -n "${ENVE_WELCOME:-}" ]; then
        printf %s\\n "$ENVE_WELCOME"
    fi
elif [ -n "${EXEC_ARG1_AS_SCRIPT:-}" ]; then
    set -- $RC_CMD
    $1
elif [ -z "${EXEC_SHIELD:-}" ]; then
    if [ -n "${PIDFILE:-}" ] && check_writable "$PIDFILE"; then
        get_current_pid
        echo $subshell_pid > "$PIDFILE"
    fi
    # eval set -- $CMD
    # exec "$@"
    [ -n "${EXEC_STDIN:-}" ] && RC_CMD="$RC_CMD <'\$EXEC_STDIN'"
    [ -n "${EXEC_STDERR:-}" ] && RC_CMD="$RC_CMD 2>'\$EXEC_STDERR'"
    [ -n "${EXEC_STDOUT:-}" ] && RC_CMD="$RC_CMD >'\$EXEC_STDOUT'"
    cmd=$RC_CMD
    unset RC_CMD
    eval exec $cmd
else
    if [ -n "${SHIELD_PIDFILE:-}" ] && check_writable "$SHIELD_PIDFILE"; then
        get_current_pid
        echo $subshell_pid > "$SHIELD_PIDFILE"
    fi

    trap on_shell_exit EXIT
    # shopt -s expand_aliases
    setup_shield
    # alias restart="_shield $RC_CMD"
    # eval _shield $RC_CMD
    restart
fi
