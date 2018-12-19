#!/usr/bin/env bats

BATS_TEST_SKIPPED=
EVNE_EXEC="$(readlink -f "./enve")"


@test "core module - test mktemp" {
    [ -f "$(mktemp)" ]
    [ -d "$(mktemp -d)" ]
}

@test "core module - basic load" {
    . ./enve.module "$EVNE_EXEC" test
    [ -n "$(echo "" | resolve_first)" ]
}

@test "core module - resolve_first" {
    . ./enve.module "$EVNE_EXEC" test
    TABLE="$(echo "" | resolve_first)"
    table_subset HOME >/dev/null
    table_subset USER >/dev/null
    table_subset TERM >/dev/null
    table_subset TMPDIR >/dev/null
}

@test "core module - resolve_basic" {
    . ./enve.module "$EVNE_EXEC" test
    TABLE="$(echo "" | resolve_basic)"
}

@test "core module - resolve_command" {
    . ./enve.module "$EVNE_EXEC" test
    TABLE="$(echo "$(out_var cmd.mycmd 'echo x')" | resolve_command)"
    cmddir="$(table_tail PATH LIST)"
    [ -x "$cmddir/mycmd" ]
    [ "$(cat $cmddir/mycmd)" = "echo x" ]
}

@test "core module - resolve_terminal" {
    . ./enve.module "$EVNE_EXEC" test
    TABLE="$(echo "$(
        out_var core.target shell
        out_var terminal.size 200x300
        out_var terminal.theme xyz
    )" | resolve_terminal)"
    table_subset TERMSIZE >/dev/null
    table_subset TERMTHEME >/dev/null
}

@test "core module - resolve_prompt" {
    # TODO: rename ENV_ROOT
    . ./enve.module "$EVNE_EXEC" test
    TABLE="$(echo "$(
        out_var core.target shell
        out_var ENV_ROOT $ENV_ROOT
    )" | resolve_prompt)"
    
    table_subset git-completion SRC >/dev/null
    table_subset git-prompt SRC >/dev/null
    table_subset bash_completion SRC >/dev/null
    
    table_subset ENVE_BASHOPTS JOIN >/dev/null
    table_subset ENVE_SHELLOPTS JOIN >/dev/null
}

@test "core module - resolve_nix" {
    . ./enve.module "$EVNE_EXEC" test
    # TABLE="$(echo "$(
    #     out_var enve.no_nix true
    # )" | resolve_nix)"

    # TABLE="$(echo "$(
    #     out_var nix.channel.url xxxx
    # )" | resolve_nix)"
    
    # TABLE="$(echo "$(
    #     out_var nix.channel.version xxxx
    #     out_var nix.config.abc xyz
    # )" | resolve_nix)"
    
}

@test "core module - resolve_macos" {
    . ./enve.module "$EVNE_EXEC" test
    TABLE="$(echo "" | resolve_macos)"

    table_subset PATH LIST >/dev/null
}


@test "core module - filter_kv_in_table" {
    . ./enve.module "$EVNE_EXEC" test
    TABLE="$(echo "$(
        out_var showthis     abc
        out_var not.showthis bcd
    )" | filter_kv_in_table)"

    [ "$(table_tail showthis)" = "abc" ]
    [ "$(table_tail not\.showthis || true)" = "" ]

}

@test "nodejs module" {
    :
}

