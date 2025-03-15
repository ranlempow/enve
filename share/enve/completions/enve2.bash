
newl="$(printf '\nx')"
newl="${newl%x}"

_enve() {
    # echo "${newl}$@$newl${COMP_WORDS[@]}$newl$COMP_CWORD$newl" >&2
    
    # printf \\n
    # for arg in "$@"; do
    #     printf %s "$arg,"
    # done
    # printf \\n
    # for arg in "${COMP_WORDS[@]}"; do
    #     printf %s "$arg,"
    # done
    # printf \\n
    # printf %s\\n "$COMP_CWORD"
    # return

    local action=
    local action_index=
    local i=0
    for arg in "${COMP_WORDS[@]}"; do
        if [ "$i" -gt 0 ]; then
            if [ -z "$action" ] && [ -n "${arg##-*}" ]; then
                action=$arg
                action_index=$i
            fi
        fi
        i=$((i+1))
    done

    if [ -z "${2}" ] || [ -n "${2##-*}" ]; then
        if [ -z "$action_index" ] || [ "$COMP_CWORD" -eq "$action_index" ]; then
            # enve argument
            COMPREPLY=($(compgen -W "$(enve commands --word)" \
                         "${COMP_WORDS[$COMP_CWORD]}"))
            return
        else
            # action argument
            :
        fi
    else
        # startswith '-'
        if [ -z "$action_index" ]; then
            # enve options
            :
        else
            # action options
            :
        fi
    fi

}
complete -F _enve enve
