function docker_tag_name --description 'Generate a Docker tag from the current project and Git branch'
    test -f ./Dockerfile; or return 1

    set -l branch (command git branch --show-current 2>/dev/null)
    test -n "$branch"; or return 1

    command slugify (path basename "$PWD")-$branch
end
