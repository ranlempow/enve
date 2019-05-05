gitrepourl() {
    repo_branch="$1"
    repo="${1%\#*}"
    if [ "$repo" != "$repo_branch" ]; then
        branch="${1##*\#}"
    else
        branch=
    fi

    if [ -e "${repo}/.git" ]; then
        repo="git+file://$repo"
    else
        # Sourced from antigen url resolution logic.
        # https://github.com/zsh-users/antigen/blob/master/antigen.zsh
        # Expand short github url syntax: `username/reponame`.
        case $repo in
            git+ssh://*|git+file://*|git+http://*|git+https://*|git+git@*:*)
                    :
                ;;
            ssh://*|file://*|http://*|https://*|git@*:*)
                    repo="git+$repo"
                ;;
            *)
                    repo="git+https://github.com/${repo%.git}.git"
                ;;
        esac
    fi
    if [ -n "$branch" ]; then
        echo "${repo}#${branch}"
    else
        echo "${repo}"
    fi
}
