#!/usr/bin/env bats

load common


setup() {
    mkstab ../libexec/enve/findutils \
        fnmatch fnmatch_pathname_transform \
        make_gitignore_filter gitignore_filter \
        files_stats files_stats_contents
    mkstab ../libexec/enve/enve.module \
        resolve_first resolve_basic resolve_command resolve_terminal \
        resolve_prompt resolve_nix resolve_macos \
        filter_kv_in_table

    mkstab ../libexec/enve/envelib \
        table_subset out_var table_tail
}



@test "core module - test mktemp" {
    [ -f "$(mktemp)" ]
    [ -d "$(mktemp -d)" ]
}

@test "core module - basic load" {
    [ -n "$(echo "" | resolve_first)" ]
}

@test "core module - resolve_first" {
    export TABLE="$(echo "" | resolve_first)"
    [ -n "$(table_subset HOME)" ]
    [ -n "$(table_subset USER)" ]
    [ -n "$(table_subset TERM)" ]
    [ -n "$(table_subset TMPDIR)" ]
}

@test "core module - resolve_basic" {
    export TABLE="$(echo "" | resolve_basic)"
}

@test "core module - resolve_command" {
    export TABLE="$(echo "$(out_var cmd.mycmd 'echo x')" | resolve_command)"
    cmddir="$(table_tail PATH LIST)"
    [ -x "$cmddir/mycmd" ]
    [ "$(cat $cmddir/mycmd)" = "echo x" ]
}

@test "core module - resolve_terminal" {
    export TABLE="$(echo "$(
        out_var core.target shell
        out_var terminal.size 200x300
        out_var terminal.theme xyz
    )" | resolve_terminal)"
    [ -n "$(table_subset TERMSIZE)" ]
    [ -n "$(table_subset TERMTHEME)" ]
}

@test "core module - resolve_prompt" {
    # TODO: rename ENV_ROOT
    export TABLE="$(echo "$(
        out_var core.target shell
        out_var ENV_ROOT $ENV_ROOT
    )" | resolve_prompt)"
    
    [ -n "$(table_subset git-completion SRC)" ]
    [ -n "$(table_subset git-prompt SRC)" ]
    [ -n "$(table_subset bash_completion SRC)" ]

    [ -n "$(table_subset ENVE_BASHOPTS JOIN)" ]
    [ -n "$(table_subset ENVE_SHELLOPTS JOIN)" ]

}

@test "core module - resolve_nix" {
    TABLE="$(echo "$(
        out_var enve.no_nix true
    )" | resolve_nix)"

    # TODO: need a effect test suit
    # TABLE="$(echo "$(
    #     out_var nix.channel.url xxxx
    # )" | resolve_nix)"
    # TABLE="$(echo "$(
    #     out_var nix.channel.version xxxx
    #     out_var nix.config.abc xyz
    # )" | resolve_nix)"
}


@test "core module - resolve_macos" {
    export TABLE="$(echo "" | resolve_macos)"

    [ -n "$(table_subset PATH LIST)" ]
}


@test "core module - filter_kv_in_table" {
    export TABLE="$(echo "$(
        out_var showthis     abc
        out_var not.showthis bcd
    )" | filter_kv_in_table)"

    [ "$(table_tail showthis)" = "abc" ]
    [ "$(table_tail not\.showthis || true)" = "" ]

}

@test "nodejs module" {
    :
}

