
parse_fire_chain() {
    # this function is posix compatiable
    #
    # $url@X!target1@Y!target2@Z
    #

    input="$1"
    input="$(echo "$input" |    sed -e 's/\([^\\]\)!/\1'"$vtab"'/g' \
                                    -e 's/\([^\\]\)@/\1'"$feed"'/g' \
                                    -e 's/\\\\/\\/g')"

    stage=0
    url=
    while [ -n "$input" ]; do
        spec="${input%%$vtab*}"
        input="${input#*$vtab}"
        if [ "$input" = "$spec" ]; then input=; fi

        stage=$((stage + 1))
        target=
        roles=
        while [ -n "$spec" ]; do

            word="${spec%%${feed}*}"
            spec="${spec#*${feed}}"
            if [ "$spec" = "$word" ]; then spec=; fi

            if [ -z "$url" ]; then
                url="$word"
                out_var "url" "$url"
                if [ -z "$url" ]; then
                    _error "url cannot empty"
                    return 1
                fi
            elif [ -z "$target" ]; then
                target="$word"
                out_var "stage$stage.target" "$target"
                if [ -z "$target" ]; then
                    _error "target cannot empty"
                    return 1
                fi
            elif [ "${word%=*}" != "$word" ]; then
                _parse_keyvalue "$word"
                if [ -n "$target" ]; then
                    out_var "stage$stage.$key" "$value"
                else
                    out_var "global.$key" "$value"
                fi
            else
                out_var "stage$stage.roles" "$word"
            fi
        done

        # project_root="$($locate_function "$url")" || {
        #     error "$url can not resolved"
        #     return 1
        # }
        # if [ -f "$project_root/enve.ini" ]; then
        #     case $target in
        #         shell|run|loader|module)
        #                 # restore stdin
        #                 exec 0<&6 6<&-
        #                 ENVE_PROFILE="$project_root/enve.ini" \
        #                 ENVE_ROLES="$roles" \
        #                 ENVE_CONFIG="$configs" $fire_function "$target" "$@"
        #             ;;
        #         build|install|deploy)
        #                 url="$(
        #                     ENVE_PROFILE="$project_root/enve.ini" \
        #                     ENVE_ROLES="$roles" \
        #                     ENVE_CONFIG="$configs" $fire_function "$target"
        #                 )"
        #             ;;
        #     esac
        # else
        #     error "'$project_root/enve.ini' not found"
        #     return 1
        # fi
    done
}

exec_fire_chain_table() {
    (

    fire_function="${1:-fire2}"
    locate_function="${2:-locate_project}"

    # save stdin
    exec 6<&0 0<&-

    url=
    stage=0
    global_config=
    finally=
    while [ -n "$target" ] || [ $stage -eq 0 ]; do
        if [ -z "$target" ]; then
            url="$(table_tail url)"
        fi
        if [ -n "$finally" ]; then
            _error "extra target $target at stage $stage"
            return 1
        fi
        project_dir="$($locate_function "$url")" || {
            _error "$url can not resolved at stage $stage"
            return 1
        }
        if [ $stage -gt 0 ]; then
            # TODO: table_subset must really subset
            ENVE_ROLES="$(table_subset "stage$stage\\.roles" | as_concat ",")"
            ENVE_CONFIG="$global_config$newl"
            ENVE_CONFIG="$ENVE_CONFIG$(table_subset "stage$stage\\..*" | as_postfix "stage$stage\\.")"
            if [ -f "$project_dir/enve.ini" ]; then
                case $target in
                    shell|run|loader|module)
                            # restore stdin
                            exec 0<&6 6<&-
                            ENVE_PROFILE="$project_dir/enve.ini" \
                            ENVE_ROLES="$ENVE_ROLES" \
                            ENVE_CONFIG="$ENVE_CONFIG" \
                            # $fire_function "$target" "$@"
                            # if [ $? -ne 0 ]; then
                            if $fire_function "$target" "$@"; then
                                _error "fire failed at stage $stage"
                                return 1
                            fi
                            finally=true
                        ;;
                    build|install|deploy)
                            # url="$(
                            #     ENVE_PROFILE="$project_dir/enve.ini" \
                            #     ENVE_ROLES="$ENVE_ROLES" \
                            #     ENVE_CONFIG="$ENVE_CONFIG" \
                            #     $fire_function "$target"
                            # )"
                            # if [ $? -ne 0 ]; then
                            if url="$(
                                        ENVE_PROFILE="$project_dir/enve.ini" \
                                        ENVE_ROLES="$ENVE_ROLES" \
                                        ENVE_CONFIG="$ENVE_CONFIG" \
                                        $fire_function "$target"
                                    )"; then
                                _error "fire failed at stage $stage"
                                return 1
                            fi
                        ;;
                    *)
                            _error "target '$target' unavailable at stage $stage"
                            return 1
                        ;;
                esac
            else
                _error "'$project_dir/enve.ini' not found at stage $stage"
                return 1
            fi
        else
            global_config="$(table_subset 'global\..*' | as_postfix 'global\.')"
        fi
        stage=$((stage + 1))
        target="$(table_tail stage$stage.target || true)"
    done
    )
}

