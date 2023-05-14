# TODO: this is only a template

_sub() {
    COMPREPLY=()
    local word="${COMP_WORDS[COMP_CWORD]}"

    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$(sub commands)" -- "$word") )
    else
        local command="${COMP_WORDS[1]}"
        local completions="$(sub completions "$command")"
        COMPREPLY=( $(compgen -W "$completions" -- "$word") )
    fi
}

newl="$(printf '\nx')"
newl="${newl%x}"

join_by() {
    local IFS="$1"
    shift
    eval "${1}_STRING=\"\${${1}[*]}\""
}

split_to() {
    local IFS="$1"
    shift
    # ARRAY=($ARRAY_STRING)
    eval "${1}=(\$${1}_STRING)"
}

_comp_option() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local LIST_STRING="$1"
    local DUP_STRING="$2"
    local LIST
    local DUP
    local word

    split_to " $newl" DUP
    join_by "$newl" DUP

    split_to " $newl" LIST
    join_by "$newl" LIST
    LIST_STRING="$newl$LIST_STRING$newl"
    for word in "${COMP_WORDS[@]}"; do
        if [ "$word" != "$cur" ] && \
           [ -z "${word%%-*}" ] && \
           [ -n "${DUP_STRING%%*${newl}${word}${newl}*}" ] && \
           [ -z "${LIST_STRING%%*${newl}${word}${newl}*}" ]; then
            LIST_STRING="\
${LIST_STRING%${newl}${word}${newl}*}\
$newl\
${LIST_STRING#*${newl}${word}${newl}}"
        fi
    done

    COMPREPLY=($(compgen -W "$LIST_STRING" -- "$cur"))
}

true '

anchors__opt_a2="a1 a2"
anchors__opt_b0=""
archors__args="arg1 [arg2]..."

cmd --opt-a2 a1 a2 --opt-b0 arg1 [arg2]...

anchors_eq__opt_a1="a1"
cmd --opt-a1=a1


'
# anchors__$opt="SP1 [SP2]..."
# anchors_eq__$opt="SP1 [SP2]..."
# archors__args="SP1 [SP2]..."

_count_arg_fixed() {
    local arg
    cnt=0
    for arg in ${args[@]}; do
        if [ -n "${arg##\[*}" ]; then
            cnt=$((cnt + 1))
        fi
    done
}

_find_state_by_args_2() {
    local kopt=$1
    local pos=$2
    local args

    PASSIBLE_REST=
    OPTARG=
    # OPTOPTION=
    if args=${!kopt} && [ -n "${args}" ]; then
        args=($args)
        local args_last=${args[${#args[@]}-1]}
        local fixed_consume=0
        while [ -n "${args[$i]}" ]; do
            if [ -z "${args[$i]##\[*}" ]; then
                break
            fi
            fixed_consume=$((fixed_consume+1))
        done

        if [ -n "${args[$pos]}" ]; then
            OPTARG=${args[$pos]}
            local i=0
            while [ $i -lt $pos ]; do
                if [ -z "${args[$i]##\[*}" ]; then
                    PASSIBLE_REST="${PASSIBLE_REST:+$PASSIBLE_REST }$((i - fixed_consume))"
                fi
                i=$((i+1))
            done
        elif [ -z "${args_last%%*.}" ] || [ -z "${args_last%%*.\]}" ]; then
            OPTARG=${args_last%%\]}
            OPTARG=${args_last%%.}
        else
            PASSIBLE_REST=$((pos - fixed_consume))
        fi
        if [ -n "${OPTARG}" ] && [ -z "${OPTARG##\[*}" ]; then
            OPTARG=${OPTARG%%\]}
            OPTARG=${OPTARG##\[}
            # OPTOPTION=1
        fi
        return
    else
        return 1
    fi
}

# _find_state_by_args() {
#     local kopt=$1
#     local optpos=$2
#     local args
#     if args=${!kopt} && [ -n "${args}" ]; then
#         local diff=$((COMP_CWORD - optpos))
#         args=($args)
#         local args_last=${args[${#args[@]}-1]}
#         if [ -n "${args[$diff]}" ]; then
#             OPTARG=${args[$diff]}
#             CMDARG=
#         elif [ -z "${args_last%%*.}" ] || [ -z "${args_last%%*.\]}" ]; then
#             OPTARG=${args_last%%\]}
#             OPTARG=${args_last%%.}
#             CMDARG=
#         else
#             _count_arg_fixed
#             OPTARG=
#             CMDARG=$((COMP_CWORD - cnt - optpos))
#         fi
#         if [ -n "${OPTARG}" ] && [ -z "${OPTARG##\[*}" ]; then
#             OPTARG=${OPTARG%%\]}
#             OPTARG=${OPTARG##\[}
#             CMDARG=1
#         fi
#         return
#     else
#         return 1
#     fi
# }

_find_state_by_prev_anchor() {
    local anchor="${COMP_WORDS[COMP_CWORD]}"
    if [ -z "${anchor##-*}" ]
        if  [ -z "${anchor%*=}" ]; then
            opt=${anchor/-/_}
            opt=${opt%=}
            if ! _find_state_by_args "anchors_eq__${opt}" $COMP_CWORD; then
                return 1
            else
                return 0
            fi
        else
            return 0
        fi
    fi


    local i=$((COMP_CWORD - 1))
    while [ $i -ge 0 ]; do
        anchor="${COMP_WORDS[$i]}"
        if [ -z "${anchor##-*}" ]; then
            if [ -z "${anchor%*=*}" ] || \
               ! _find_state_by_args "anchors__${anchor/-/_}" $((COMP_CWORD - i)); then
                PASSIBLE_REST=
                OPTARG=
                OPTOPTION=1
            fi
            break
        fi
        i=$((i - 1))
    done

    OPTARG_LIST=$OPTARG
    # OPTARG2=
    for rest in $PASSIBLE_REST; do
        if _find_state_by_args "anchors__args" $((COMP_CWORD - $rest)); then
            OPTARG_LIST="${OPTARG_LIST:+$OPTARG_LIST }$OPTARG"
        fi
    done

    # if [ "$OPTOPTION" = "1" ]; then
    #     OPTARG1=$OPTARG
    #     if _find_state_by_args "anchors__args" $((COMP_CWORD - i)); then
    #         OPTARG2=$OPTARG
    #     fi
    # fi

    return 1
}


_bash_arguments() {
    # example: _bash_arguments \
    #            "--x,--xargs:"
    for opt in "$@"; do

    done
    if _find_state_by_prev_anchor; then
        if [ -n "$ARG" ] && command -v _comp_arg_$ARG >/dev/null; then
            COMPREPLY=($(_comp_arg_$ARG))
        fi
        if [ -z "${NO_OPT}" ]; then
            COMPREPLY+=($(_comp_option "$list" "$dups"))
        fi
    else
        COMPREPLY=($(_comp_option "$list" "$dups"))
    fi
}


# _comp_regex() {
#     # if [[ "$TEST" =~ [^a-zA-Z0-9\ ] ]]; then BLAH; fi
# }

_enve() {
    # echo "${newl}X$@$newl${COMP_WORDS[@]}$newl$COMP_CWORD$newl" >&2
    local IFS=,
    local last
    echo "$COMP_CWORD,${COMP_WORDS[*]}," >&2
    if [ $COMP_CWORD -gt 0 ]; then
        last="$COMP_WORDS[$((COMP_CWORD - 1))]"
    else
        last=
    fi

    # list=$(seq 500 | sed -e 's/^/--/')
    # _comp_option "$list"

    # COMPREPLY=($(compgen -o filenames -X "*.enve.ini" -- "$cur"))
    # COMPREPLY=($(compgen -d -G "*.enve.ini" -- "$cur"))
    # COMPREPLY=($(compgen -P "$PWD$PWD-" -W "a b c" -- "$cur"))
    # COMPREPLY=(aaa)

}
complete -F _enve enve

# aa=(a b c "d e")
# x=$(join_by ":" "${aa[@]}")
# split_to_array "$x"
# join_by ":" "${a[@]}"
