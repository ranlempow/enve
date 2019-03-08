#!/usr/bin/env bats


load common

setup() {
    mkstab ../libexec/enve/envelib \
        table_tail table_subset table_exclude value_substi table_substi \
        as_postfix as_rootkey as_value as_uniquekey as_concat \
        out_var \
        fire_chain \
        parse_config

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

@test "tabels 1" {
    TABLE="$(
    out_var AA 11
    out_var BB 22
    out_var AA.a 1111
    out_var AA.b 1112
    out_var BB.b 2222
    )"
    [ "$(TABLE="$TABLE" table_tail AA)" = "11" ]
    [ "$(TABLE="$TABLE" table_tail BB)" = "22" ]
    [ "$(TABLE="$TABLE" table_tail AA.a)" = "1111" ]
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

}

@test "parse_config" {

    rm -rf /tmp/test_prj1
    mkdir -p /tmp/test_prj1
    cat > /tmp/test_prj1/enve.ini <<EOF
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
    TABLE=$(roles=select1,select2 parse_config "/tmp/test_prj1/enve.ini")
    TABLE=$(echo "$TABLE" | grep -E -v -e "^VAR${tab}enve\.configs${tab}" -e "^VAR${tab}enve\.roles${tab}")

    echo "$TABLE" >&2
    [ "$TABLE" = "$(printf %s%s%s%s%s%s%s \
        "VAR${tab}layout.root${tab}/private/tmp/test_prj1${newl}" \
        "VAR${tab}this.is${tab}not true${newl}" \
        "VAR${tab}my.name.is${tab}adam${newl}" \
        "VAR${tab}my.name.are${tab}family1${newl}" \
        "VAR${tab}my.name.are${tab}family2${newl}" \
        "VAR${tab}list${tab}a${newl}" \
        "VAR${tab}list${tab}b${newl}" \
        "VAR${tab}bound${tab}/private/tmp/test_prj1/enve.ini"
    )" ]
}

@test "parse_config multiline" {

    rm -rf /tmp/test_prj1
    mkdir -p /tmp/test_prj1
    cat > /tmp/test_prj1/enve.ini <<'EOF'

[long]
a= \
1 \
2
b= \\

EOF
    TABLE=$(parse_config "/tmp/test_prj1/enve.ini")
    TABLE=$(echo "$TABLE" | grep -E -v -e "^VAR${tab}enve\.configs${tab}" -e "^VAR${tab}enve\.roles${tab}")

    echo "$TABLE" >&2
    [ "$TABLE" = "$(printf %s%s%s%s \
        "VAR${tab}layout.root${tab}/private/tmp/test_prj1${newl}" \
        "VAR${tab}long.a${tab} 1 2${newl}" \
        "VAR${tab}long.b${tab} \\${newl}" \
        "VAR${tab}bound${tab}/private/tmp/test_prj1/enve.ini" \
        
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


