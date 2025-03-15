
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
    [ ! -e "$1" ] || { [ -w "$1" ] && [ -f "$1" ]; }
}

# simply_timestamp() {
#     read -r mm ss <<EOF
# $(date +"%M %S")
# EOF
#     tm=$((mm*60 + ss))
# }

exec_cmd() {
    # [ -n "${EXEC_STDIN:-}" ] && RC_CMD="$RC_CMD <'\$EXEC_STDIN'"
    # [ -n "${EXEC_STDERR:-}" ] && RC_CMD="$RC_CMD 2>'\$EXEC_STDERR'"
    # [ -n "${EXEC_STDOUT:-}" ] && RC_CMD="$RC_CMD >'\$EXEC_STDOUT'"
    eval exec "$RC_CMD 
        ${EXEC_STDIN:+"<'\$EXEC_STDIN'"}
        ${EXEC_STDOUT:+">'\$EXEC_STDOUT'"}
        ${EXEC_STDERR:+"2>'\$EXEC_STDERR'"}"
}

run() {
    # 需要這個才可以讓pid運作正確
    if [ -n "${BASH_VERSION:-}" ]; then
        set +o posix
    fi
    set -m

    if [ -z "${first_run:-}" ]; then
        first_run=1
    else
        # printf "restarting...  $*\n"
        printf "restarting...  $RC_CMD\n"
    fi
    if [ -n "${PIDFILE:-}" ] && check_writable "$PIDFILE"; then
        (subshell_pid=${BASHPID:-$(exec sh -c 'echo "$PPID"')}
         echo $subshell_pid > "$PIDFILE"
         exec_cmd
         # exec "$@"
         ) &
        pid=$!
    elif [ -n "${PIDFILE:-}" ]; then
        echo "error: '$PIDFILE' not writable" >&2
        retcode=99
        return
    else
        # (exec "$@") &
        (exec_cmd) &
        pid=$!
    fi
    if [ -n "${EXITFILE:-}" ] && check_writable "$EXITFILE"; then
        rm -f "${EXITFILE:-}"
    fi
    # start_tm=$(awk 'BEGIN{srand(); print srand()}')
    retcode=
    running=1
}

wait_run() {
    while true; do
        if [ -n "${kill_timeout:-}" ] && kill -0 $pid 2>/dev/null; then
            # simply_timestamp
            # if [ "$kill_timeout" -gt 1800 ] &&
            #     [ $tm -gt 1800 ] && [ $tm -gt $kill_timeout ]; then
            #     kill -KILL $pid
            #     kill_timeout=
            # elif [ "$kill_timeout" -lt 1800 ] &&
            #      [ $tm -lt 1800 ] && [ $tm -gt $kill_timeout ]; then
            #     kill -KILL $pid
            #     kill_timeout=
            # else
            #     sleep 1
            # fi
            if [ "$kill_timeout" -eq 0 ]; then
                kill -KILL $pid
            else
                kill_timeout=$((kill_timeout - 1))
                sleep 1
            fi
        else
            # 這個也會被中斷
            wait $pid
            retcode=$?
            if [ $retcode -lt 126 ]; then
                kill_timeout=
                break
            else
                # 中斷的情形
                retcode=
            fi
        fi
        read -r job_id job_status job_other <<EOF
$(jobs)
EOF
        if [ -n "$job_status" ] && [ -z "${job_status%%Stopped*}" ]; then
            return 0
        elif ! kill -0 $pid 2>/dev/null; then
            # 信號中斷並且處理結束之後，wait(1)會返回
            # 只有SIGCHLD才代表子行程結束。回傳真正的終止碼。
            # 其他的情形，回傳讓父行程中斷的信號種類
            wait $pid
            retcode=$?
            kill_timeout=
            break
        fi
    done
    if [ -n "${EXITFILE:-}" ] && check_writable "$EXITFILE"; then
        echo $retcode > "$EXITFILE"
    fi
    running=
    on_run_exit "$retcode"
}

read_char() {
    /bin/stty -icanon -echo
    eval "$1=\"\$(dd bs=1 count=1 2>/dev/null; printf x)\""
    eval "$1=\"\${$1%x}\""
    /bin/stty icanon echo
}

_shield() {
    # running=1
    while true; do
        # rundone=
        restart=
        # run "$@"
        if [ -n "${running:-}" ]; then
            kill -CONT $pid 2>/dev/null
            sleep 1
        else
            run
        fi
        wait_run
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
            if [ -n "${running:-}" ]; then
                printf "\n* Stop shielded command\n"
                printf "call 'restart' to continue, or call 'fg' to put foreground\n"
                break
            elif [ "$retcode" -ne 0 ]; then
                printf "\n* Shielded command exit code is $retcode\n"
                printf "Press Ctrl+D to exit, or press Ctrl+R to restart\n"
                printf "Press Enter to enter prompt shell, call 'restart' to restart process\n"
                # while read -n1 press; do
                # while press=$(dd bs=1 count=1 2>/dev/null); do
                while read_char press; do
                    if [ "$press" = "$ctrlR" ]; then
                        restart=1
                        break
                    elif [ "$press" = "$ctrlD" ]; then
                        EXIT=1
                        break
                    elif [ "$press" = "$newl" ]; then
                        EXIT=
                        break
                    fi
                    printf "Press Ctrl+D to exit, or press Ctrl+R to restart\n"
                    printf "Press Enter to enter prompt shell, call 'restart' to restart process\n"
                done
            fi
        fi
        if [ -n "$restart" ]; then
            continue
        else
            break
        fi
    done
    # running=
    if [ -n "${EXIT:-}" ] && [ -n "${retcode:-}" ]; then
        exit $retcode
    fi
}

trap_signal() {
    if [ -n "${pid:-}" ]; then
        if [ -n "${INT_AS_TSTP:-}" ]; then
            kill -TSTP $pid
        else
            kill -$1 $pid
            kill -CONT $pid
            eval wait_$1=1
            if [ -z "${kill_timeout:-}" ] && [ $1 = TERM ]; then
                kill_timeout=${KILL_TIMEOUT:-5}
                if [ -n "${EXITFILE:-}" ] && check_writable "$EXITFILE"; then
                    echo killing > "$EXITFILE"
                fi
            fi
            if [ "${2:-}" = restart ]; then
                restart=1
            fi
        fi
    fi
}


setup_shield() {
    ctrl_chars=$(printf '\022x\004')
    ctrlR=${ctrl_chars%%x*}
    ctrlD=${ctrl_chars##*x}
    ctrl_chars=$(printf '\nx')
    newl=${ctrl_chars%x}
    unset ctrl_chars

    trap "trap_signal INT" INT
    trap "trap_signal TERM" TERM
    trap "trap_signal HUP" HUP
    trap "trap_signal QUIT" QUIT
    # trap "echo SIGTSTP" TSTP
    trap "trap_signal TERM restart" USR1

    # trap "rundone=1" SIGCHLD
}

restart() {
    # if [ -z "${running:-}" ]; then
    #     restart
    # fi
    # eval _shield $RC_CMD
    setup_shield
    _shield
    trap - INT TERM HUP QUIT USR1
}

detach() {
    if [ -n "${TMUX:-}" ]; then
        tmux detach
    fi
    if [ -n "${running:-}" ]; then
        restart
    fi
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
    subshell_pid=${BASHPID:-"$(exec sh -c 'echo "$PPID"')"}
}

if [ -z "${RC_CMD:-}" ]; then
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
    # [ -n "${EXEC_STDIN:-}" ] && RC_CMD="$RC_CMD <'\$EXEC_STDIN'"
    # [ -n "${EXEC_STDERR:-}" ] && RC_CMD="$RC_CMD 2>'\$EXEC_STDERR'"
    # [ -n "${EXEC_STDOUT:-}" ] && RC_CMD="$RC_CMD >'\$EXEC_STDOUT'"
    # cmd=$RC_CMD
    # unset RC_CMD
    # eval exec $cmd
    exec_cmd
else
    # reported status of terminated background jobs immediately
    # set -b

    if [ -n "${SHIELD_PIDFILE:-}" ] && check_writable "$SHIELD_PIDFILE"; then
        get_current_pid
        echo $subshell_pid > "$SHIELD_PIDFILE"
    fi

    trap on_shell_exit EXIT
    # setup_shield
    restart
fi
