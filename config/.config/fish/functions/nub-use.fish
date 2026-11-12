function nub-use -d "Switch the home-level Nub Node version"
    if test (count $argv) -eq 1; and test "$argv[1]" = purge
        command node "$HOME/.dotfiles/nub-node-cleanup.mjs"
        return $status
    end

    if test (count $argv) -ne 1; or test -z "$argv[1]"; or string match -q -- '-*' "$argv[1]"
        echo 'Usage: nub-use <version|lts|latest|purge>' >&2
        return 1
    end

    command nub node install "$argv[1]"; or return $status
    printf '%s\n' "$argv[1]" > "$HOME/.node-version"; or return $status
    printf 'Default Node set to %s. Project pins still apply.\n' "$argv[1]"
end
