#!/usr/bin/env bats

load common

ENVE_HOME="$BATS_TEST_DIRNAME/../libexec"

@test "test_read_project_json" {
    . "$ENVE_HOME/enve/prjlib"

    # package.json
    read_project_json <( echo '
{
  "type": "module",
  "name": "Mods",
  "version": "4.5.6"
}
')

    [ "$PRJNAME" = "Mods" ]
    [ "$PRJVER" = "4.5.6" ]
}

@test "test_read_project_toml" {
    . "$ENVE_HOME/enve/prjlib"

    # pyproject.toml
    read_project_toml <( echo '
[project]
name = "Thing"
version = "1.2.3"
')

    [ "$PRJNAME" = "Thing" ]
    [ "$PRJVER" = "1.2.3" ]
}

@test "test_read_markdown_section" {
    . "$ENVE_HOME/enve/prjlib"

    read_markdown_section <( echo '
## Helps

foo
bar

## Other
what
') Helps

    [ "$content" = '
foo
bar

' ]
    [ "$breaker" = "Other" ]
}

@test "get_project_groups" {
    . "$ENVE_HOME/enve/prjlib"
    . "$ENVE_HOME/enve/pathutils"

    get_project_groups "$ENVE_HOME/../share"
    groups=${groups%"$newl"}
    [ "$groups" = "$(normalize "$ENVE_HOME/../share/enve/example")" ]

    for g in $groups; do
        get_projects_from_group "$g"
        echo "$projects"
        [ "$projects" = \
          "$(normalize "$ENVE_HOME/../share/enve/example/sierra")
$(normalize "$ENVE_HOME/../share/enve/example/romeo")
" ]
    done
}
