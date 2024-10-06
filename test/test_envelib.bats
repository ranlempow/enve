#!/usr/bin/env bats


load common

setup() {
    mkstab ../libexec/enve/envelib \
        module_sort_after get_module_info \
        fire_chain

    mkstab ../libexec/enve/envelib \
        enve_parse_config <<"EOF"
printf %s\\n "$TABLE"
EOF

    mkstab ../libexec/enve/pathutils \
        canonicalize_symlinks



    tab="$(printf '\tx')"
    tab="${tab%x}"
    feed="$(printf '\fx')"
    feed="${feed%x}"
    vtab="$(printf '\vx')"
    vtab="${vtab%x}"
    newl="$(printf '\nx')"
    newl="${newl%x}"

}

# @test "builtin_loader" {
#     (
#         . ./enve.loader "$EVNE_EXEC" load
#         TABLE=$(
#             out_var "module" "not-exist"
#         )
#         output="$(builtin_loader)" || { code=$?; }
#         [ ${code:-0} -eq 44 ]
#         [ -z "${output}" ]
#         TABLE=$(
#             out_var "module" "test"
#         )
#         output="$(builtin_loader)" || {
#             echo "code $?" >&2
#         }
#         [ "$output" = "test=$(dirname $EVNE_EXEC)/core/test" ]
#     )
# }

# @test "path_loader" {
#     (
#         . ./enve.loader "$EVNE_EXEC" load
#         TABLE=$(
#             out_var "module.notExist.path" "not-exist"
#         )
#         output="$(path_loader)" || { code=$?; }
#         [ ${code:-0} -eq 44 ]
#         [ -z "${output}" ]
#         TABLE=$(
#             out_var "module.xxx.path" "$(dirname $EVNE_EXEC)/core/test"
#         )
#         output="$(path_loader)"
#         [ "$output" = "xxx=$(dirname $EVNE_EXEC)/core/test" ]
#     )
# }


# @test "enve.loader" {
#     (
#         . ./enve.loader "$EVNE_EXEC" load
#         TABLE=$(
#             out_var "module.notExist.path" "not-exist"
#         )
#         output="$(printf %s\\n "$TABLE" | ./enve.loader "$EVNE_EXEC")" || { code=$?; }
#         [ ${code:-0} -eq 44 ]
#         [ -z "${output}" ]
#         TABLE=$(
#             out_var "module.xxx.path" "$(dirname $EVNE_EXEC)/core/test"
#         )
#         output="$(printf %s\\n "$TABLE" | ./enve.loader "$EVNE_EXEC")"
#         [ "$output" = "xxx=$(dirname $EVNE_EXEC)/core/test" ]
#     )
# }



# @test "fire_chain" {
#     (
#     cat <<'EOF'
#     fire() {
#         target=$1
#         case $target in
#             run)    exec bash -c "echo '$ENVE_PROFILE@$ENVE_ROLES'" ;;
#             build)  exec bash -c "echo '$(dirname ${ENVE_PROFILE})_DEF'" ;;
#         esac
#     }
#     locate_project() {
#         echo "${1}_LOC"
#     }
# EOF
#     cat $BATS_TMPDIR/cmds/fire_chain
#     ) > $BATS_TMPDIR/cmds/fire_chain1
#     chmod 755 $BATS_TMPDIR/cmds/fire_chain1

#     echo "OK" >&2
#     rm -rf /tmp/fire_chain
#     mkdir -p /tmp/fire_chain/{ABC_LOC,ABC_LOC_DEF_LOC}
#     cd /tmp/fire_chain
#     touch {ABC_LOC,ABC_LOC_DEF_LOC}/enve.ini
#     [ "$(fire_chain1 "ABC!build!run@R1" fire locate_project)" = "ABC_LOC_DEF_LOC/enve.ini@R1" ]
# }

@test "enve_parse_config" {
    # input
    #   [parse_inherit]
    #   [parse_profile_optional]
    #   [roles]
    #   [loaded]
    #   [stage1_is_text]
    #   $1 - STAGE1_FILE or STAGE1_TEXT
    #

    echo "BATS_TEST_TMPDIR:$BATS_TEST_TMPDIR" >&2
    echo x > $BATS_TEST_TMPDIR/y
    [ $(cat "$BATS_TEST_TMPDIR/y") = x ]
    # TABLE=$(
    #     parse_inherit=1 \
    #     parse_profile_optional="" \
    #     roles="module-info" loaded="" \
    #     enve_parse_config "$module_root/enve.ini")

}

@test "exec_loaders_with_info" {
    :
}

@test "fire_eval" {
    :
}

@test "resolve_with_info" {
    :
}

@test "execute_envdef" {
    RC_CONTENT=$(execute_envdef "$TABLE" shell)

    # if ! execute_envdef "$TABLE" "$target" > "$RCFILE_PATH"; then
    #     return 1
    # fi
}

@test "get_rcfile_from_profiles_nocache" {
    :
}



@test "get_module_info" {
    base=$(canonicalize_symlinks "$BATS_TEST_TMPDIR")
    cat > "$BATS_TEST_TMPDIR/enve.ini" <<EOF
[define.module.mymod.x]
procedure=x
EOF

    get_module_info "$BATS_TEST_TMPDIR" >&2
    [ "$(get_module_info "$BATS_TEST_TMPDIR")" = \
        "mymod,x,:,:,$base/mymod.x,,$base/enve.ini,$base" \
    ]


    cat > "$BATS_TEST_TMPDIR/enve.ini" <<EOF
[define.module.mymod2.y]
after=a
before=b
native_exec=true
source_exec=true
exec=/bin/sh
enve=./xxx.enve
EOF
    get_module_info "$BATS_TEST_TMPDIR" >&2
    [ $(get_module_info "$BATS_TEST_TMPDIR") = \
        "mymod2,y,:a:,:b:,$(canonicalize_symlinks "/bin/sh"),native_exec=1;source_exec=1;,$base/xxx.enve,$base" \
    ]

    cat > "$BATS_TEST_TMPDIR/enve.ini" <<EOF
[define.module.mymod3.z]
after=a
after=b
after=c
before=1,2:3
EOF
    get_module_info "$BATS_TEST_TMPDIR" >&2
    [ $(get_module_info "$BATS_TEST_TMPDIR") = \
        "mymod3,z,:a:b:c:,:1:2:3:,$base/mymod3.z,,$base/enve.ini,$base" \
    ]

    cat > "$BATS_TEST_TMPDIR/enve.ini" <<EOF
[define.module.mymod.x]
procedure=x
[define.module.mymod.y]
procedure=y
EOF

    get_module_info "$BATS_TEST_TMPDIR" >&2
    [ "$(get_module_info "$BATS_TEST_TMPDIR")" = \
        "mymod,x,:,:,$base/mymod.x,,$base/enve.ini,$base
mymod,y,:,:,$base/mymod.y,,$base/enve.ini,$base" \
    ]
}

@test "module_sort_after" {
    merge() {
        cut -d "," -f 1 | paste -sd ","
    }
    mline() {
        echo "$1,$2,$3,$4,,"
    }

    [ "$(nonfast=1 p_modules="" module_sort_after "$(mline a - : :)" | merge)" = "a" ]

    modules="$(mline a - : :)
$(mline c - : :)"

    [ "$(nonfast=1 p_modules=$modules module_sort_after "$(mline b - :a: :c:)" | merge)" = "a,b,c" ]
    [ "$(nonfast=1 p_modules=$modules module_sort_after $(mline b - :a: :) | merge)" = "a,c,b" ]
    [ "$(nonfast=1 p_modules=$modules module_sort_after $(mline b - : :a:) | merge)" = "b,a,c" ]
    [ "$(nonfast=1 p_modules=$modules module_sort_after $(mline b - : :c:) | merge)" = "a,b,c" ]
    [ "$(nonfast=1 p_modules=$modules module_sort_after $(mline b - :c: :) | merge)" = "a,c,b" ]
    [ "$(nonfast=1 p_modules=$modules module_sort_after "$(mline a - : :)" | merge)" = "a,c" ]
    [ "$(nonfast=1 p_modules=$modules module_sort_after "$(mline c - : :)" | merge)" = "a,c" ]
    nonfast=1 p_modules=$modules run module_sort_after $(mline b - :c: :a:)
    [ "$status" -eq 2 ]

    modules="$(mline b - :a: :c:)"
    [ "$(nonfast=1 p_modules=$modules module_sort_after $(mline a - : :) | merge)" = "a,b" ]
    [ "$(nonfast=1 p_modules=$modules module_sort_after $(mline c - : :) | merge)" = "b,c" ]
    [ "$(nonfast=1 p_modules=$modules module_sort_after $(mline d - : :) | merge)" = "b,d" ]
    nonfast=1 p_modules=$modules run module_sort_after $(mline a - :b: -)
    [ "$status" -eq 2 ]
    nonfast=1 p_modules=$modules run module_sort_after $(mline c - : :b:)
    [ "$status" -eq 2 ]

    # echo "$modules" >&2
    # false
}


