function brewup
    echo '🍺 1/6 Updating Homebrew 📦'
    brew update
    echo '🍺 2/6 Checking Homebrew for issues ⛔️'
    brew doctor
    echo '🍺 3/6 Getting a list of oudated packages 📜'
    brew outdated
    echo '🍺 4/6 Upgrading packages 🚚'
    brew upgrade
    echo '🍺 5/6 Cleaning up 🚮'
    brew cleanup
    echo '🍺 6/6 Updating Brew Casks'
    brew cask upgrade
    echo '🍺 Done. 🎉'
end
