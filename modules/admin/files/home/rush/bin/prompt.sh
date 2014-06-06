function parse_git_branch {
    gs=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD 2> /dev/null)
    if [ -z "$gs" ]; then
      return
    fi
    if [ "$gs" == "master" ]
    then
        echo "[m]"
    else
        echo "[$gs]"
    fi
}
parse_git_branch
