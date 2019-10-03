
# POSIX prompt


prompt_command() {
    RED='\[\e[31m\]'
    # GREEN='\[\e[32m\]'
    YELLOW='\[\e[33m\]'
    BLUE='\[\e[34m\]'
    # CYAN='\[\e[36m\]'
    GRAY='\[\e[90m\]'
    PINK='\[\e[95m\]'
    NOCOLOR='\[\e[0m\]'

    ps1_line=
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        if [ "$USER" = "root" ]; then
            ps1_line="$ps1_line$RED$USER$NOCOLOR"
        else
            ps1_line="$ps1_line$YELLOW$USER$NOCOLOR"
        fi
        # shellcheck disable=2039
        ps1_line="$ps1_line$GRAY@$YELLOW${HOSTNAME:-$HOST}$NOCOLOR"
    elif [ "$USER" = "root" ]; then
        # Only show username in non-ssh session if is root
        ps1_line="$ps1_line$RED$USER$NOCOLOR"
    fi

    ps1_line=
    case ${TERM:-} in
        xterm*)
            if [ -n "$PRJ_NAME" ]; then
                ps1_line="$ps1_line\\[\\033]1;\\u@\\h: \\w\\007\\]"
                ps1_line="$ps1_line\\[\\033]2;$PRJ_NAME\\007\\]"
            else
                ps1_line="$ps1_line\\[\\033]1;\\u@\\h: \\w\\007\\]"
                ps1_line="$ps1_line\\[\\033]2;\\h\\007\\]"
            fi
            ;;
        *)
            # ps1_line=
            ;;
    esac

    # __git_ps1 will render git status to $PS1
    GIT_PS1_SHOWCOLORHINTS=true \
    GIT_PS1_SHOWDIRTYSTATE=true \
    GIT_PS1_SHOWUPSTREAM=true \
    __git_ps1 "" "" " $GRAY($NOCOLOR%s$GRAY)$NOCOLOR"

    ps1_line="$ps1_line$BLUE\\w$NOCOLOR$PS1${ps1_line:+" $GRAY$ps1_line$NOCOLOR"}"
    ps1_line="$ps1_line\\n${GRAY}$PRJ_NAME$NOCOLOR"
    ps1_line="$ps1_line\$(if [ \$? = 0 ]; then printf '$PINK'; else printf '$RED'; fi)"
    ps1_line="$ps1_line ❯$NOCOLOR "
    PS1="\\n$ps1_line"
    unset ps1_line retcode
    unset RED YELLOW BLUE GRAY PINK NOCOLOR
}

#. "$GIT_PROMPT_SH"

# NOTE: `history -a` is bash only command
if [ "$shell" = "bash" ]; then
    PROMPT_COMMAND="history -a; prompt_command"
else
    PROMPT_COMMAND=prompt_command
fi
