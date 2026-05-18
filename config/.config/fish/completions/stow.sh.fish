function __dotfiles_stow_commands
    printf '%s\t%s\n' \
        install 'Create or update symlinks' \
        restow 'Recreate symlinks after changes' \
        adopt 'Move existing files into dotfiles and link' \
        unstow 'Remove managed symlinks' \
        dry-run 'Preview changes without writing'
end

function __dotfiles_stow_packages
    set -l dotfiles_dir "$DOTFILES_DIR"
    if test -z "$dotfiles_dir"
        set dotfiles_dir "$HOME/.dotfiles"
    end

    if not test -d "$dotfiles_dir"
        return
    end

    for entry in (command ls -1A "$dotfiles_dir")
        switch "$entry"
            case '.git' '.agents' 'scripts' 'on-login' 'raycast-backups' 'raycast-extension-scripts'
                continue
            case 'Brewfile' 'RectangleConfig.json' 'readme.markdown' '.stowrc' '.stow-local-ignore' '.macos' 'env.ignored' 'n-cleanup.mjs'
                continue
        end

        printf '%s\n' "$entry"
    end
end

for cmd in stow.sh ./scripts/stow.sh scripts/stow.sh ~/.dotfiles/scripts/stow.sh $HOME/.dotfiles/scripts/stow.sh
    complete -c "$cmd" -f
    complete -c "$cmd" -n '__fish_use_subcommand' -a '(__dotfiles_stow_commands)'
    complete -c "$cmd" -n '__fish_seen_subcommand_from install restow adopt unstow dry-run' -a '(__dotfiles_stow_packages)'
end
