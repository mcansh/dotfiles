function brewup
    set -l failed 0
    echo '🍺 Updating Homebrew 📦'
    brew update; or return $status
    echo '🍺 Checking Homebrew for issues ⛔️'
    brew doctor; or set failed 1
    echo '🍺 Getting a list of oudated packages 📜'
    brew outdated; or set failed 1
    echo '🍺 Upgrading packages 🚚'
    brew upgrade; or set failed 1
    echo '🍺 Updating Brew Casks'
    brew upgrade --cask; or set failed 1
    echo '🍺 Cleaning up 🚮'
    brew cleanup; or set failed 1
    if test $failed -eq 0
        echo '🍺 Done. 🎉'
    end
    return $failed
end
