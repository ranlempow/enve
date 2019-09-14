#!/usr/bin/env bats


load common

setup() {
    mkstab ../libexec/enve/envelib \
        table_tail table_subset table_exclude value_substi table_substi \
        as_postfix as_rootkey as_value as_uniquekey as_concat \
        module_sort_after get_module_info \
        out_var out_var_fast \
        fire_chain \
        parse_config

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
#         output="$(echo "$TABLE" | ./enve.loader "$EVNE_EXEC")" || { code=$?; }
#         [ ${code:-0} -eq 44 ]
#         [ -z "${output}" ]
#         TABLE=$(
#             out_var "module.xxx.path" "$(dirname $EVNE_EXEC)/core/test"
#         )
#         output="$(echo "$TABLE" | ./enve.loader "$EVNE_EXEC")"
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

@test "get_module_info" {
    rm -rf "$BATS_TMPDIR/get_module_info"
    mkdir -p "$BATS_TMPDIR/get_module_info"
    base=$(canonicalize_symlinks "$BATS_TMPDIR/get_module_info")
    cat > "$BATS_TMPDIR/get_module_info/enve.ini" <<EOF
[define.module.mymod.x]
procedure=x
EOF

    get_module_info "$BATS_TMPDIR/get_module_info" >&2
    [ "$(get_module_info "$BATS_TMPDIR/get_module_info")" = \
        "mymod,x,:,:,$base/x.enve.module,,$base/enve.ini,$base" \
    ]


    cat > "$BATS_TMPDIR/get_module_info/enve.ini" <<EOF
[define.module.mymod2.y]
after=a
before=b
native_exec=true
source_exec=true
exec=/bin/sh
enve=./xxx.enve
EOF
    get_module_info "$BATS_TMPDIR/get_module_info" >&2
    [ $(get_module_info "$BATS_TMPDIR/get_module_info") = \
        "mymod2,y,:a:,:b:,$(canonicalize_symlinks "/bin/sh"),native_exec=1;source_exec=1;,$base/xxx.enve,$base" \
    ]

    cat > "$BATS_TMPDIR/get_module_info/enve.ini" <<EOF
[define.module.mymod3.z]
after=a
after=b
after=c
before=1,2:3
EOF
    get_module_info "$BATS_TMPDIR/get_module_info" >&2
    [ $(get_module_info "$BATS_TMPDIR/get_module_info") = \
        "mymod3,z,:a:b:c:,:1:2:3:,$base/z.enve.module,,$base/enve.ini,$base" \
    ]

    cat > "$BATS_TMPDIR/get_module_info/enve.ini" <<EOF
[define.module.mymod.x]
procedure=x
[define.module.mymod.y]
procedure=y
EOF

    get_module_info "$BATS_TMPDIR/get_module_info" >&2
    [ "$(get_module_info "$BATS_TMPDIR/get_module_info")" = \
        "mymod,x,:,:,$base/x.enve.module,,$base/enve.ini,$base
mymod,y,:,:,$base/y.enve.module,,$base/enve.ini,$base" \
    ]
}

@test "module_sort_after" {
    merge() {
        cut -d "," -f 1 | paste -sd ","
    }
    mline() {
        echo "$1,$2,$3,$4,,"
    }

    [ "$(nonfast=1 modules="" module_sort_after "$(mline a - : :)" | merge)" = "a" ]

    modules="$(mline a - : :)
$(mline c - : :)"

    [ "$(nonfast=1 modules=$modules module_sort_after "$(mline b - :a: :c:)" | merge)" = "a,b,c" ]
    [ "$(nonfast=1 modules=$modules module_sort_after $(mline b - :a: :) | merge)" = "a,c,b" ]
    [ "$(nonfast=1 modules=$modules module_sort_after $(mline b - : :a:) | merge)" = "b,a,c" ]
    [ "$(nonfast=1 modules=$modules module_sort_after $(mline b - : :c:) | merge)" = "a,b,c" ]
    [ "$(nonfast=1 modules=$modules module_sort_after $(mline b - :c: :) | merge)" = "a,c,b" ]
    [ "$(nonfast=1 modules=$modules module_sort_after "$(mline a - : :)" | merge)" = "a,c" ]
    [ "$(nonfast=1 modules=$modules module_sort_after "$(mline c - : :)" | merge)" = "a,c" ]
    nonfast=1 modules=$modules run module_sort_after $(mline b - :c: :a:)
    [ "$status" -eq 2 ]

    modules="$(mline b - :a: :c:)"
    [ "$(nonfast=1 modules=$modules module_sort_after $(mline a - : :) | merge)" = "a,b" ]
    [ "$(nonfast=1 modules=$modules module_sort_after $(mline c - : :) | merge)" = "b,c" ]
    [ "$(nonfast=1 modules=$modules module_sort_after $(mline d - : :) | merge)" = "b,d" ]
    nonfast=1 modules=$modules run module_sort_after $(mline a - :b: -)
    [ "$status" -eq 2 ]
    nonfast=1 modules=$modules run module_sort_after $(mline c - : :b:)
    [ "$status" -eq 2 ]

    # echo "$modules" >&2
    # false
}

@test "value_substi" {
    [ "$(a=1  _value='3${a}4' value_substi nonfast)" = "314" ]
    [ "$(a=1  _value='3\${a}4' value_substi nonfast)" = '3${a}4' ]
    [ "$(_a=1 _value='3${_a}4' value_substi nonfast)" = '3${_a}4' ]
    [ "$(a=1  _value='${a}' value_substi nonfast)" = "1" ]
    [ "$(a=1  _value='3${a}' value_substi nonfast)" = "31" ]
    [ "$(a=1  _value='${a}4' value_substi nonfast)" = "14" ]
    [ "$(a=1  _value='\${a}' value_substi nonfast)" = '${a}' ]

    [ "$(a=1      _value='3${a}${a}4' value_substi nonfast)" = '3114' ]
    [ "$(a=1 b=2  _value='3${a}${b}4' value_substi nonfast)" = '3124' ]

    [ "$(a=1  _value='$a' value_substi nonfast)" = '$a' ]
    [ "$(a=1  _value='${a' value_substi nonfast)" = '${a' ]
    [ "$(a=1  _value='$a}' value_substi nonfast)" = '$a}' ]
    [ "$(a=1  _value='\${a' value_substi nonfast)" = '\${a' ]
    ! a=1  _value='${notExist}' value_substi

    [ "$(a=1  _value='3${c:-5"$a"6}4' value_substi nonfast)" = '35164' ]

    ! a=1  _value='3${c:-5"$(echo x)"6}4' value_substi nonfast
    ! a=1  _value='3${$(echo x)}4' value_substi nonfast

    [ "$(PASSVARS="a$newl" a=1  _value='3${a}4' value_substi nonfast)" = '3'\''"${a}"'\''4' ]


}

@test "table_substi" {
    TABLE="$(
    out_var AA '3${a}4'
    out_var BB '3${b}\${a}4'
    )"
    CONTEXT="$(
    out_var a 1
    out_var b '2${a}'
    )"

    [ "$(TABLE="$TABLE" table_substi "$CONTEXT")" = "$(
        out_var AA '314'
        out_var BB '321${a}4'
    )" ]
}


@test "tabels operations 1" {

    [ "$(out_var A 1)" = "$(printf VAR\\tA\\t1)" ]
    [ "$(out_var A "")" = "$(printf VAR\\tA\\t)" ]
    [ "$(out_var "" 1)" = "$(printf VAR\\t\\t1)" ]
    [ "$(out_var A 1;out_var B 2)" = "$(printf VAR\\tA\\t1\\nVAR\\tB\\t2)" ]

    [ "$(out_var_fast A 1)" = "$(printf VAR\\tA\\t1)" ]
    [ "$(out_var_fast A "")" = "$(printf VAR\\tA\\t)" ]
    [ "$(out_var_fast "" 1)" = "$(printf VAR\\t\\t1)" ]
    [ "$(out_var_fast A 1;out_var_fast B 2)" = "$(printf VAR\\tA\\t1\\nVAR\\tB\\t2)" ]


    TABLE="$(
    out_var AA 11
    out_var BB 22
    out_var AA.a 1111
    out_var AA.b 1112
    out_var BB.b 2222
    )"

    # k() {
        [ "$(TABLE="$TABLE" table_tail AA)" = "11" ]
        [ "$(TABLE="$TABLE" table_tail BB)" = "22" ]
        [ "$(TABLE="$TABLE" table_tail AA\\.a)" = "1111" ]
        [ "$(TABLE="$TABLE" table_tail CC)" = "" ]
        [ "$(TABLE="$TABLE" table_subset 'AA')" = "AA${tab}11" ]
        [ "$(TABLE="$TABLE" table_subset 'AA\..*')" = "AA.a${tab}1111${newl}AA.b${tab}1112" ]
        [ "$(TABLE="$TABLE" table_exclude 'AA.*')" = "BB${tab}22${newl}BB.b${tab}2222" ]
        [ "$(TABLE="$TABLE" table_subset 'AA\..*' | as_postfix 'AA\.')" = "a${tab}1111${newl}b${tab}1112" ]
        [ "$(TABLE="$TABLE" table_subset 'AA.*' | as_rootkey)" = "AA${tab}11${newl}AA${tab}1111${newl}AA${tab}1112" ]
        [ "$(TABLE="$TABLE" table_subset 'AA.*' | as_value)" = "11${newl}1111${newl}1112" ]
        [ "$(TABLE="$TABLE" table_subset 'AA.*' | as_uniquekey)" = "AA${newl}AA.a${newl}AA.b" ]
        [ "$(TABLE="$TABLE$(out_var AA 33)" table_subset 'AA.*' | as_uniquekey)" = "AA${newl}AA.a${newl}AA.b" ]
        [ "$(TABLE="$TABLE" table_subset 'AA.*' | as_concat ',')" = "11,1111,1112" ]
    # }
    # k
    # table_tail() {
    #     fast_table_tail "$@"
    #     printf %s\\n "$v" >&2
    # }
    # table_subset() {
    #     fast_table_subset "$@"
    #     printf %s\\n "$kv"
    # }
    # k
}


@test "tabels operations with unset" {
    TABLE="$(
    out_var AA 11
    out_var AA 22
    out_var BB ""
    out_var AA ""
    out_var AA 33

    out_var AA 34
    out_var CC 44
    out_var CC ""
    out_var DD 55
    out_var DD ""
    out_var DD 66

    )"

    [ "$(TABLE="$TABLE" table_tail AA)" = "34" ]
    [ "$(TABLE="$TABLE" table_tail BB)" = "" ]
    [ "$(TABLE="$TABLE" table_tail CC)" = "" ]
    [ "$(TABLE="$TABLE" table_tail DD)" = "66" ]
    [ "$(TABLE="$TABLE" table_subset 'AA' | as_concat ',')" = "33,34" ]
}

@test "tabels operations with default" {
    TABLE="$(
    out_var AA 11
    out_var AA 22
    out_var BB ""
    out_var AA ""
    out_var AA 33

    out_var AA 34
    out_var CC 44
    out_var CC ""
    out_var DD 55
    out_var DD ""
    out_var DD 66

    )"
    [ "$(TABLE_DEFAULT="1" TABLE="$TABLE" table_tail AA)" = "34" ]
    [ "$(TABLE_DEFAULT="1" TABLE="$TABLE" table_tail BB)" = "1" ]
    [ "$(TABLE_DEFAULT="1" TABLE="$TABLE" table_tail CC)" = "1" ]
    [ "$(TABLE_DEFAULT="1" TABLE="$TABLE" table_tail DD)" = "66" ]
}




@test "parse_config" {

    rm -rf "$BATS_TMPDIR/test_parse_config"
    mkdir -p "$BATS_TMPDIR/test_parse_config"
    cat > "$BATS_TMPDIR/test_parse_config/enve.ini" <<EOF
[this]
is=not true

[my.name]
is=adam
are@select1@@,,@=family1
are,select1,select2=family2

not@x=1
not@select1@x=1
not@x,y=1
not,x,y=1
not,x,y.are=1

[list]
a
b

[not@x]
not me

# not me
EOF
    TABLE=$(roles=select1,select2 parse_config "$BATS_TMPDIR/test_parse_config/enve.ini")

    echo "$TABLE" | grep -E "VAR${tab}layout.root${tab}" >/dev/null
    echo "$TABLE" | grep -E "VAR${tab}bound${tab}" >/dev/null

    TABLE=$(echo "$TABLE" | grep -E -v \
            -e "^VAR${tab}enve\.roles${tab}"
        )

    echo "$TABLE" >&2
    [ "$TABLE" = "$(printf %s%s%s%s%s%s%s \
        "VAR${tab}layout.root${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config")${newl}" \
        "VAR${tab}this.is${tab}not true${newl}" \
        "VAR${tab}my.name.is${tab}adam${newl}" \
        "VAR${tab}my.name.are${tab}family2${newl}" \
        "VAR${tab}list${tab}a${newl}" \
        "VAR${tab}list${tab}b${newl}" \
        "VAR${tab}bound${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config/enve.ini")${newl}" \
        "VAR${tab}enve.configs${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config/enve.ini")${newl}" \
    )" ]
}

@test "parse_config multiline" {

    rm -rf "$BATS_TMPDIR/test_parse_config_multiline"
    mkdir -p "$BATS_TMPDIR/test_parse_config_multiline"
    cat > "$BATS_TMPDIR/test_parse_config_multiline/enve.ini" <<'EOF'

[long]
a= \
1 \
2
b= \\

EOF
    TABLE=$(parse_config "$BATS_TMPDIR/test_parse_config_multiline/enve.ini")
    TABLE=$(echo "$TABLE" | grep -E -v \
            -e "^VAR${tab}enve\.roles${tab}"
    )

    echo "$TABLE" >&2
    [ "$TABLE" = "$(printf %s%s%s%s \
        "VAR${tab}layout.root${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config_multiline")${newl}" \
        "VAR${tab}long.a${tab} 1 2${newl}" \
        "VAR${tab}long.b${tab} \\${newl}" \
        "VAR${tab}bound${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config_multiline/enve.ini")${newl}" \
        "VAR${tab}enve.configs${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config_multiline/enve.ini")${newl}" \
    )" ]
}


# t=$'\t'
# execute_envdef \
# "VAR${t}CC${t}VV
# LIST${t}LS${t}a
# LIST${t}LS${t}b
# FUNC${t}FU${t}{ echo x; }
# "
# echo CC:$LS
# FU

# define_functions
# system_roles

# TABLE="$(ENVE_CONFIG="
# VAR${tab}CC${tab}'VV'
# VAR${tab}XX${tab}AA
# VAR${tab}YY.xx${tab}AA
# " parse_config)" resolve


# CONF_TABLE="$(ENVE_CONFIG="
# VAR${tab}CC${tab}'VV'
# VAR${tab}XX${tab}AA
# VAR${tab}YY.xx${tab}AA
# " parse_config)" make_rcfile run
# exec env - bash "$rcfile" bash -c 'echo $PATH'



# echo "" | resolve_macos
# echo "" | resolve_basic
# echo "VAR${tab}nix.root${tab}/nix/store/hwpp7kia2f0in5ns2hiw41q38k30jpj2-nix-1.11.16" | resolve_nix
# echo "" | resolve_nix

# parse_config "$(readlink -f "$(dirname "$0")/..")/devon.ini"


