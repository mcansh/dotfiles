function __dotfiles_verify_stow_packages
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

for cmd in verify-stow.sh ./scripts/verify-stow.sh scripts/verify-stow.sh ~/.dotfiles/scripts/verify-stow.sh $HOME/.dotfiles/scripts/verify-stow.sh
    complete -c "$cmd" -f
    complete -c "$cmd" -s h -l help -d 'Show help'
    complete -c "$cmd" -a '(__dotfiles_verify_stow_packages)'
end
