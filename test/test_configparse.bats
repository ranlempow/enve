#!/usr/bin/env bats


load common



@test "parse_config_non_recursive_text" {
    . "$ENVE_HOME/enve/envelib"

    # set > "$BATS_TMPDIR/sv1"
    config_text="a=1$newl" parse_config_non_recursive_text
    # echo "$OUT_TABLE" >&2
    # set > "$BATS_TMPDIR/sv2"
    # diff "$BATS_TMPDIR/sv1" "$BATS_TMPDIR/sv2"
    # false

    OUT_TABLE=
    parse_config_non_recursive_text "a=1"
    [ "$OUT_TABLE" = "VAR${tab}a${tab}1${newl}" ]
    OUT_TABLE=
    parse_config_non_recursive_text "[a]${newl}1"
    [ "$OUT_TABLE" = "VAR${tab}a${tab}1${newl}" ]
    OUT_TABLE=
    parse_config_non_recursive_text "[b]${newl}a=1"
    [ "$OUT_TABLE" = "VAR${tab}b.a${tab}1${newl}" ]
    OUT_TABLE=
    roles="x" parse_config_non_recursive_text "a@x=1${newl}a@y=2"
    [ "$OUT_TABLE" = "VAR${tab}a${tab}1${newl}" ]
    OUT_TABLE=
    roles="y" parse_config_non_recursive_text "[b@y]${newl}a@x=1${newl}a@y=2"
    [ "$OUT_TABLE" = "VAR${tab}b.a${tab}2${newl}" ]
    OUT_TABLE=
    roles="y" parse_config_non_recursive_text "[include]${newl}/path/xxx"
    [ "$OUT_TABLE" = "VAR${tab}__include${tab}/path/xxx,y${newl}" ]

}

write_config1() {
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
}

# @test "parse_config_non_recursive" {
#     . "$ENVE_HOME/enve/envelib"

#     write_config1

#     # set > "$BATS_TMPDIR/sv1"
#     roles=select1,select2 parse_config_non_recursive "$BATS_TMPDIR/test_parse_config/enve.ini"
#     # echo "$OUT_TABLE" >&2
#     # set > "$BATS_TMPDIR/sv2"
#     # diff "$BATS_TMPDIR/sv1" "$BATS_TMPDIR/sv2"
#     # false

#     # echo "$OUT_TABLE" >&2

#     TABLE=$OUT_TABLE
#     printf %s\\n "$TABLE" | grep -E "VAR${tab}layout.root${tab}" >/dev/null
#     printf %s\\n "$TABLE" | grep -E "VAR${tab}bound${tab}" >/dev/null

#     TABLE=$(printf %s\\n "$TABLE" | grep -E -v \
#             -e "^VAR${tab}enve\.roles${tab}"
#         )

#     printf %s\\n "$TABLE" >&2
#     [ "${TABLE}" = "$(printf %s%s%s%s%s%s%s%s \
#         "VAR${tab}layout.root${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config")${newl}" \
#         "VAR${tab}this.is${tab}not true${newl}" \
#         "VAR${tab}my.name.is${tab}adam${newl}" \
#         "VAR${tab}my.name.are${tab}family2${newl}" \
#         "VAR${tab}list${tab}a${newl}" \
#         "VAR${tab}list${tab}b${newl}" \
#         "VAR${tab}bound${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config/enve.ini")${newl}" \
#         "VAR${tab}enve.configs${tab}$(canonicalize_symlinks "$BATS_TMPDIR/test_parse_config/enve.ini")${newl}" \
#     )" ]

# }



@test "enve_parse_config2" {
    . "$ENVE_HOME/enve/envelib"

    stage1_is_text=1 enve_parse_config2 "a=1"
    [ "$TABLE" = "VAR${tab}a${tab}1${newl}" ]

    write_config1
    # roles=select1,select2 enve_parse_config2 "$BATS_TMPDIR/test_parse_config/enve.ini"
    # printf %s\\n "$TABLE" >&2

    loaded=
    TABLE=
    stage1_is_text=1 enve_parse_config2 "\
a=1${newl}\
__include=$BATS_TMPDIR/test_parse_config/enve.ini,select1,select2${newl}\
b=2"
    # printf %s\\n "$TABLE" >&2
    # false


    TABLE=
    set > "$BATS_TMPDIR/sv1"
    stage1_is_text=1 loaded="" enve_parse_config2 "\
a=1${newl}\
__include=$BATS_TMPDIR/test_parse_config/enve.ini,select1,select2${newl}\
__include=$BATS_TMPDIR/test_parse_config/enve.ini,select1,select2${newl}\
b=2"
    # printf %s\\n "$TABLE" >&2
    echo "$OUT_TABLE" >&2
    set > "$BATS_TMPDIR/sv2"
    diff "$BATS_TMPDIR/sv1" "$BATS_TMPDIR/sv2"
    false
}

