#!/usr/bin/env bats


# EVNE_EXEC="$(readlink -f "./enve")"

setup() {
    mkdir -p $BATS_TMPDIR/cmds

    for func in table_tail table_subset table_exclude \
                as_postfix as_rootkey as_value as_uniquekey as_concat \
                out_var \
                fire_chain \
                parse_config; do
        cat > "$BATS_TMPDIR/cmds/$func" <<EOF
set -euo pipefail
ENVE_HOME="$BATS_TEST_DIRNAME/../libexec"
. "\$ENVE_HOME/enve/envelib"
$func "\$@"
EOF
    done
    chmod 755 $BATS_TMPDIR/cmds/*
    export PATH="$BATS_TMPDIR/cmds:$PATH"

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

# @test "undefined command" {
#     ! (
#         . "$EVNE_EXEC" UNDEFINED_COMMAND
#     )
# }

@test "fire_chain" {
    (
    cat <<'EOF'
    fire() {
        target=$1
        case $target in
            run)    exec bash -c "echo '$ENVE_PROFILE@$ENVE_ROLES'" ;;
            build)  exec bash -c "echo '$(dirname ${ENVE_PROFILE})_DEF'" ;;
        esac
    }
    locate_project() {
        echo "${1}_LOC"
    }
EOF
    cat $BATS_TMPDIR/cmds/fire_chain
    ) > $BATS_TMPDIR/cmds/fire_chain1
    chmod 755 $BATS_TMPDIR/cmds/fire_chain1

    echo "OK" >&2
    rm -rf /tmp/fire_chain
    mkdir -p /tmp/fire_chain/{ABC_LOC,ABC_LOC_DEF_LOC}
    cd /tmp/fire_chain
    touch {ABC_LOC,ABC_LOC_DEF_LOC}/enve.ini
    [ "$(fire_chain1 "ABC!build!run@R1" fire locate_project)" = "ABC_LOC_DEF_LOC/enve.ini@R1" ]
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
are=family

[list]
a
b

# not me
EOF
    TABLE="$(parse_config "/tmp/test_prj1/enve.ini")"
    echo "$TABLE" >&2
    [ "$TABLE" = "$(printf %s%s%s%s%s%s%s \
        "VAR${tab}this.is${tab}not true${newl}" \
        "VAR${tab}my.name.is${tab}adam${newl}" \
        "VAR${tab}my.name.are${tab}family${newl}" \
        "VAR${tab}list${tab}a${newl}" \
        "VAR${tab}list${tab}b${newl}" \
        "VAR${tab}enve.bound${tab}/private/tmp/test_prj1/enve.ini${newl}" \
        "VAR${tab}layout.root${tab}/private/tmp/test_prj1"
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
    TABLE="$(parse_config "/tmp/test_prj1/enve.ini")"
    echo "$TABLE" >&2
    [ "$TABLE" = "$(printf %s%s%s%s \
        "VAR${tab}long.a${tab} 1 2${newl}" \
        "VAR${tab}long.b${tab} \\${newl}" \
        "VAR${tab}enve.bound${tab}/private/tmp/test_prj1/enve.ini${newl}" \
        "VAR${tab}layout.root${tab}/private/tmp/test_prj1"
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


