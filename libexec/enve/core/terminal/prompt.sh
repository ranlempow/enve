
# POSIX prompt

prompt_enve_preexec() {
    if [ -n "${COMP_LINE:-}" ]; then
        # We're in the middle of a completer. This obviously can't be
        # an interactively issued command.
        return
    fi
    if [ -n "${_PREEXEC_READY:-}" ]; then
        unset _PREEXEC_READY
        fast_timestamp_ms && LAST_START_TIME=$tm

        LAST_COMMAND=$(LC_ALL=C HISTTIMEFORMAT='' builtin history 1)
        LAST_COMMAND=${LAST_COMMAND##" "*" "}
    fi
}

prompt_enve_precmd() {
    LAST_RET_VAULE=$?
    if [ -n "${LAST_START_TIME:-}" ]; then
        fast_timestamp_ms && \
            LAST_DURATION=$((tm - LAST_START_TIME))
        unset LAST_START_TIME
    else
        unset LAST_DURATION
    fi
}


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


send_through_tmux() {
    # tmux: passthrough escape sequence
    s=$1
    replace "\\033" "\\033\\033"
    escape_string="$1\\033Ptmux;$s\007\\033\\\\"
}

send_notifications() {
    # https://sw.kovidgoyal.net/kitty/desktop-notifications/
    send_through_tmux "\\007"
    send_through_tmux "\\033]99;;$1\\033\\"
}

prompt_command() {
    RED='\[\e[31m\]'
    # GREEN='\[\e[32m\]'
    YELLOW='\[\e[33m\]'
    BLUE='\[\e[34m\]'
    # CYAN='\[\e[36m\]'
    GRAY='\[\e[90m\]'
    PINK='\[\e[95m\]'
    NOCOLOR='\[\e[0m\]'

    # NOTE: `history -a` is bash only command
    if [ -n "${BASH_VERSION}" ]; then
        builtin history -a
    fi

    ps1=
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        if [ "$USER" = "root" ]; then
            ps1="$ps1$RED$USER$NOCOLOR"
        else
            ps1="$ps1$YELLOW$USER$NOCOLOR"
        fi
        # shellcheck disable=2039
        ps1="$ps1$GRAY@$YELLOW${HOSTNAME:-$HOST}$NOCOLOR"

        # TODO: 從特殊變數提取 remote name

    elif [ "$USER" = "root" ]; then
        # Only show username in non-ssh session if is root
        ps1="$ps1$RED$USER$NOCOLOR"
    else
        # TODO: 顯示作業系統名稱
        :
    fi


    ps1=
    case ${TERM:-} in
        xterm*|tmux*|screen*)
            if [ -n "$PRJ_NAME" ]; then
                ps1="$ps1\\[\\033]1;\\u@\\h: \\w\\007\\]"
                ps1="$ps1\\[\\033]2;$PRJ_NAME\\007\\]"
            else
                ps1="$ps1\\[\\033]1;\\u@\\h: \\w\\007\\]"
                ps1="$ps1\\[\\033]2;\\h\\007\\]"
            fi
            ;;
        *)
            # ps1=
            ;;
    esac

    # TODO: 在workspace中顯示studio的狀態

    # __git_ps1 will render git status to $PS1
    GIT_PS1_SHOWCOLORHINTS=true \
    GIT_PS1_SHOWDIRTYSTATE=true \
    GIT_PS1_SHOWUPSTREAM=true \
    GIT_PS1_SHOWCONFLICTSTATE=yes \
    __git_ps1 "" "" " $GRAY($NOCOLOR%s$GRAY)$NOCOLOR"
    # repo_info="$(cd "$PRJROOT"; git rev-parse --git-dir --is-inside-git-dir \
    #     --is-bare-repository --is-inside-work-tree \
    #     --short HEAD 2>/dev/null)"
    # .git
    # false
    # false
    # true
    # 0497dd2

    repo_info="$(cd "$PRJROOT"; git rev-parse --short HEAD 2>/dev/null)"
    current_version=$repo_info

    ps1="$ps1$BLUE\\w$NOCOLOR$PS1${ps1:+" $GRAY$ps1$NOCOLOR"}"
    if [ "${LAST_DURATION:-0}" -gt 2000 ]; then
        ps1="$ps1${LAST_DURATION:+ "$GRAY$((LAST_DURATION/1000))s$NOCOLOR"}"
        if [ "${LAST_DURATION:-0}" -gt 45000 ]; then
            send_notifications "task at $PRJ_NAME is done, spend $((LAST_DURATION/1000))s"
        fi
    fi
    ps1="$ps1\\n$GRAY$PRJ_NAME"

    # TODO: 比較現在資料夾中的enve config輸出，與本環境的enve config輸出
    if [ "${current_version:-}" != "${PRJ_VERSION:-}" ]; then
        ps1="$ps1${PRJ_VERSION:+ [$PRJ_VERSION]}"
    fi
    ps1="$ps1$NOCOLOR"
    if [ "${LAST_RET_VAULE:-0}" -eq 0 ]; then
        ps1="$ps1$PINK"
    else
        ps1="$ps1$RED"
    fi
    ps1="$ps1 ❯$NOCOLOR "
    PS1="\\n$ps1"
    unset ps1 retcode
    unset RED YELLOW BLUE GRAY PINK NOCOLOR
    unset LAST_DURATION LAST_RET_VAULE LAST_COMMAND

    _PREEXEC_READY=1
}

_PREEXEC_READY=1

# install prompt on posix shell
if [ -n "${ZSH_VERSION:-}" ]; then
    zmodload zsh/datetime
    zmodload zsh/mathfunc
    fast_timestamp_ms() {
        (( tm = int(rint(EPOCHREALTIME * 1000)) ))
    }

    autoload -Uz add-zsh-hook
    add-zsh-hook precmd prompt_enve_precmd
    add-zsh-hook preexec prompt_enve_preexec
    setopt promptsubst
    PROMPT='$(prompt_command; printf %s\n "$PS1")'
else

    fast_timestamp_ms() {
        if [ -n "${BASH_VERSION:-}" ] && [ "${BASH_VERSION%%.*}" = 4 ]; then
            printf -v tm '%(%s%3N)T' -1
        else
            tm=$(date +%s%3N)
        fi
        if [ "${tm#"${tm%??}"}" = "3N" ]; then
            tm=$(( ${tm%??} * 1000))
        fi
    }

    if [ -n "${BASH_VERSION:-}" ]; then
        trap prompt_enve_preexec DEBUG
        # else
        #     PS0='$(prompt_enve_preexec)'
        # fi
        PROMPT_COMMAND='prompt_enve_precmd; prompt_command'
    else
        PS1='$(prompt_enve_precmd; prompt_command; printf %s\n "$PS1")'
    fi
fi

# #. "$GIT_PROMPT_SH"
# # NOTE: `history -a` is bash only command
# if [ "$shell" = "bash" ]; then
#     PS0='$(preexec_command)'
#     PROMPT_COMMAND="history -a; prompt_command"
# else
#     PROMPT_COMMAND=prompt_command
# fi
