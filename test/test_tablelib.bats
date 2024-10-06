#!/usr/bin/env bats


load common

setup() {
    mkstab ../libexec/enve/tablelib \
        table_tail table_subset table_exclude table_substi \
        as_postfix as_rootkey as_value as_uniquekey as_concat \
        out_var out_var_fast \
        parse_config_non_recursive_text

    mkstab ../libexec/enve/tablelib value_substi <<"EOF"
printf %s "$_subsited_value"
EOF

    # mkstab ../libexec/enve/pathutils \
    #     canonicalize_symlinks

    tab="$(printf '\tx')"
    tab="${tab%x}"
    feed="$(printf '\fx')"
    feed="${feed%x}"
    vtab="$(printf '\vx')"
    vtab="${vtab%x}"
    newl="$(printf '\nx')"
    newl="${newl%x}"

}


@test "value_substi" {
    [ "$(a=1  _value='3${a}4' value_substi)" = "314" ]
    [ "$(a=1  _value='3\${a}4' value_substi)" = '3${a}4' ]
    [ "$(_a=1 _value='3${_a}4' value_substi)" = '3${_a}4' ]
    [ "$(a=1  _value='${a}' value_substi)" = "1" ]
    [ "$(a=1  _value='3${a}' value_substi)" = "31" ]
    [ "$(a=1  _value='${a}4' value_substi)" = "14" ]
    [ "$(a=1  _value='\${a}' value_substi)" = '${a}' ]

    [ "$(a=1      _value='3${a}${a}4' value_substi)" = '3114' ]
    [ "$(a=1 b=2  _value='3${a}${b}4' value_substi)" = '3124' ]

    [ "$(a=1  _value='$a' value_substi)" = '$a' ]
    [ "$(a=1  _value='${a' value_substi)" = '${a' ]
    [ "$(a=1  _value='$a}' value_substi)" = '$a}' ]
    [ "$(a=1  _value='\${a' value_substi)" = '\${a' ]
    ! a=1  _value='${notExist}' value_substi

    # [ "$(a=1  _value='3${c:-5"$a"6}4' value_substi)" = '35164' ]
    # ! a=1  _value='3${c:-5"$(echo x)"6}4' value_substi
    # ! a=1  _value='3${$(echo x)}4' value_substi
    # [ "$(PASSVARS="a$newl" a=1  _value='3${a}4' value_substi)" = '3'\''"${a}"'\''4' ]

    [ "$(PASSVARS="a$newl" a=1  _value='3${a}4' value_substi)" = '3${a}4' ]
    [ "$(STAY_UNDEFINED=1  _value='3${a}4' value_substi)" = '3${a}4' ]

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

    [ "$(TABLE="$TABLE" table_tail AA)" = "11" ]
    [ "$(TABLE="$TABLE" table_tail BB)" = "22" ]
    [ "$(TABLE="$TABLE" table_tail AA\\.a)" = "1111" ]
    [ "$(TABLE="$TABLE" table_tail CC)" = "" ]
    [ "$(TABLE="$TABLE" table_subset 'AA')" = "AA${tab}11" ]
    [ "$(TABLE="$TABLE" table_subset 'AA\..*')" = "AA.a${tab}1111${newl}AA.b${tab}1112" ]
    [ "$(TABLE="$TABLE" table_exclude 'AA.*')" = "BB${tab}22${newl}BB.b${tab}2222" ]
    # [ "$(TABLE="$TABLE" table_subset 'AA\..*' | as_postfix 'AA\.')" = "a${tab}1111${newl}b${tab}1112" ]
    [ "$(TABLE="$TABLE" table_subset 'AA\..*' | as_postfix 'AA.')" = "a${tab}1111${newl}b${tab}1112" ]
    [ "$(TABLE="$TABLE" table_subset 'AA.*' | as_rootkey)" = "AA${tab}11${newl}AA${tab}1111${newl}AA${tab}1112" ]
    [ "$(TABLE="$TABLE" table_subset 'AA.*' | as_value)" = "11${newl}1111${newl}1112" ]
    [ "$(TABLE="$TABLE" table_subset 'AA.*' | as_uniquekey)" = "AA${newl}AA.a${newl}AA.b" ]
    [ "$(TABLE="$TABLE$(out_var AA 33)" table_subset 'AA.*' | as_uniquekey)" = "AA${newl}AA.a${newl}AA.b" ]
    [ "$(TABLE="$TABLE" table_subset 'AA.*' | as_concat ',')" = "11,1111,1112" ]
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
    # TABLE=$(roles=select1,select2 parse_config "$BATS_TMPDIR/test_parse_config/enve.ini")
    TABLE=$(
        roles=select1,select2 \
        parse_config_non_recursive_text < "$BATS_TMPDIR/test_parse_config/enve.ini")

    # printf %s\\n "$TABLE" >&2
    # printf %s\\n "$TABLE" | grep -E "VAR${tab}layout.root${tab}" >/dev/null
    # printf %s\\n "$TABLE" | grep -E "VAR${tab}bound${tab}" >/dev/null
    # TABLE=$(printf %s\\n "$TABLE" | grep -E -v \
    #         -e "^VAR${tab}enve\.roles${tab}"
    #     )

    printf %s\\n "$TABLE" >&2
    [ "$TABLE" = "$(printf %s%s%s%s%s%s%s \
        "VAR${tab}this.is${tab}not true${newl}" \
        "VAR${tab}my.name.is${tab}adam${newl}" \
        "VAR${tab}my.name.are${tab}family2${newl}" \
        "VAR${tab}list${tab}a${newl}" \
        "VAR${tab}list${tab}b${newl}" \
    )" ]

    # [ "$TABLE" = "$(printf %s%s%s%s%s%s%s \
    #     "VAR${tab}layout.root${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config")${newl}" \
    #     "VAR${tab}this.is${tab}not true${newl}" \
    #     "VAR${tab}my.name.is${tab}adam${newl}" \
    #     "VAR${tab}my.name.are${tab}family2${newl}" \
    #     "VAR${tab}list${tab}a${newl}" \
    #     "VAR${tab}list${tab}b${newl}" \
    #     "VAR${tab}bound${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config/enve.ini")${newl}" \
    #     "VAR${tab}enve.configs${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config/enve.ini")${newl}" \
    # )" ]
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
    # TABLE=$(parse_config "$BATS_TMPDIR/test_parse_config_multiline/enve.ini")
    TABLE=$(
        roles=select1,select2 \
        parse_config_non_recursive_text < "$BATS_TMPDIR/test_parse_config_multiline/enve.ini")

    # TABLE=$(printf %s\\n "$TABLE" | grep -E -v \
    #         -e "^VAR${tab}enve\.roles${tab}"
    # )

    printf %s\\n "$TABLE" >&2
    [ "$TABLE" = "$(printf %s%s%s%s \
        "VAR${tab}long.a${tab} 1 2${newl}" \
        "VAR${tab}long.b${tab} \\${newl}" \
    )" ]
    # [ "$TABLE" = "$(printf %s%s%s%s \
    #     "VAR${tab}layout.root${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config_multiline")${newl}" \
    #     "VAR${tab}long.a${tab} 1 2${newl}" \
    #     "VAR${tab}long.b${tab} \\${newl}" \
    #     "VAR${tab}bound${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config_multiline/enve.ini")${newl}" \
    #     "VAR${tab}enve.configs${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config_multiline/enve.ini")${newl}" \
    # )" ]
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




