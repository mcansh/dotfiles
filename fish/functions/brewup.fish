function brewup
    echo '🍺 Updating Homebrew 📦'
    brew update
    echo '🍺 Checking Homebrew for issues ⛔️'
    brew doctor
    echo '🍺 Getting a list of oudated packages 📜'
    brew outdated
    echo '🍺 Upgrading packages 🚚'
    brew upgrade
    echo '🍺 Updating Brew Casks'
    brew upgrade --cask
    echo '🍺 Cleaning up 🚮'
    brew cleanup
    echo '🍺 Done. 🎉'
end
