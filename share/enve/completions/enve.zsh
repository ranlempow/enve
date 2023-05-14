#compdef enve

autoload -U compinit
compinit

function _enve() {
    _arguments '-f[profile]:set profile:()' '*'{-c,--config}'[config]:set config:->setconfig' \
        - normal-install \
        '--cc=-[attempt to compile using compiler]:compiler:->cache' \
        ':command-x:((xxx\:x yyy\:y))' \
        ':command-y:(xxx zzz)' \
        - xx-group2 \
        '-d:xx:(aa a2)' \
        '-b:xx:(bb b2)'
    # _message -r "Completing..."
}


# completions remain in cache until any tap has new commits
__enve_completion_caching_policy() {
    local -a tmp

    # invalidate if cache file is missing or >=2 weeks old
    tmp=( $1(mw-2N) )
    (( $#tmp )) || return 0

    # otherwise, invalidate if latest tap index file is missing or newer than
    # cache file
    tmp=( ${HOMEBREW_REPOSITORY:-/usr/local/Homebrew}/Library/Taps/*/*/.git/index(om[1]N) )
    [[ -z $tmp || $tmp -nt $1 ]]
}

# _set_cache_policy() {
#     # set default cache policy
#     zstyle -s ":completion:${curcontext%:*}:*" cache-policy tmp
#     [[ -n $tmp ]] ||
#     zstyle ":completion:${curcontext%:*}:*" cache-policy \
#     __enve_completion_caching_policy
# }

# _enve_fire() {
#     :
# }

# enve [-D|-DD|-DDD] [-V|-VV|-VVV] [-Q|-QQ|-Q] [--debug=<options>]
#      [--verbose-level=<LOGLEVEL>]
#      [--logfile-level=<LOGLEVEL>]
#      [--progress[=auto|=always|=never]]
#      [--color[=auto|=always|=never]]
#      [--logfile=*] [-v|--version] [-h|--help] [-I|--instant] <subcommand>
function _enve() {
    local curcontext="$curcontext" state state_descr line expl
    local tmp ret=1

    _arguments -C \
        '(-V -VV -VVV -Q -QQ -QQQ --verbose-level)'{-D'[debug message]',-DD'[trace message]',-DDD'[output everything]'} \
        '(-D -DD -DDD -Q -QQ -QQQ --verbose-level)'{-V'[verbose]',-VV'[more verbose]',-VVV'[very verbose]'} \
        '(-D -DD -DDD -V -VV -VVV --verbose-level)'{-Q'[show warning and error]',-QQ'[show error only]',-QQQ'[output nothing]'} \
        '(-D -DD -DDD -V -VV -VVV -Q -QQ -QQQ)--verbose-level=-[assign verbose level at output]:verbose level:->LEVEL' \
        '--logfile-level=-[assign verbose level at logfile]:verbose level:->LEVEL' \
        '--debug=-[trun on debug options]:debug options:->DEBUG' \
        '--progress=-[display output at one line]:when to show progress:->WHEN' \
        '--color=-[colorize the output]:when to show color:->WHEN' \
        {-v,--version}'[display version information and exit]' \
        {-h,--help}'[display help and exit]' \
        '1:command:->command' \
        '*::options:->options'

    case "$state" in
        LEVEL)
            local -a levels
            levels=(TRACE DEBUG INFO NOTICE WARNING ERROR CRITICAL)
            _describe 'verbose levels' levels
        ;;
        DEBUG)
            local -a debugopts
            debugopts=(never timing cli)
            _describe 'debug options' debugopts
        ;;
        WHEN)
            local -a whens
            whens=(auto always never)
            _describe 'when to perform' whens
        ;;
        command)
            local -a commands
            eval "commands=($(enve commands --escape --split=":"))"
            _describe -t common-commands 'common commands' commands
            # __brew_commands && return 0
        ;;
        options)
            local command
            command="${line[1]}"
            # change context to e.g. enve-list
            curcontext="${curcontext%:*}-${command}:${curcontext##*:}"

            # zstyle -s ":completion:${curcontext%:*}:*" cache-policy tmp
            # [[ -n $tmp ]] ||
            # zstyle ":completion:${curcontext%:*}:*" cache-policy \
            # __enve_completion_caching_policy

            # call completion for named command e.g. _enve_list
            local completion_func="_enve_${command//-/_}"
            _call_function ret "${completion_func}" # && return ret
            [ "$ret" -eq 0 ] && return

            if eval [ -z "\$${completion_func}_imported" ]; then
                eval ${completion_func}_imported=1
                if eval "$(enve completions zsh "$command")"; then
                    _call_function ret "${completion_func}" # && return ret
                    [ "$ret" -eq 0 ] && return
                fi
            fi
            _message "a completion function is not defined for command: ${command}"
            return 1
        ;;
    esac
}



# _enve_fire() {
#     _arguments --
# }
# _enve() {
#     _call_function ret _enve_fire
# }

compdef _enve enve


# if [[ ! -o interactive ]]; then
#     return
# fi

# compctl -K _sub sub

# _sub() {
#     local word words completions
#     read -cA words
#     word="${words[2]}"

#     if [ "${#words}" -eq 2 ]; then
#         completions="$(sub commands)"
#     else
#         completions="$(sub completions "${word}")"
#     fi

#     reply=("${(ps:\n:)completions}")
# }
