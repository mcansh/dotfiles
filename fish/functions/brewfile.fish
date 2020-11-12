function brewfile
    echo '> 1/2 Generating Brewfile'
    brew bundle dump --force
    echo '> 2/2 Moving Brewfile'
    mv brewfile ~/dotfiles/Brewfile
    echo '> Done 👌'
end
