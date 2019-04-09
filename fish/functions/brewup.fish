function brewup
  echo '🍺 1/5 Updating Homebrew 📦'
  brew update
  echo '🍺 2/5 Checking Homebrew for issues ⛔️'
  brew doctor
  echo '🍺 3/5 Getting a list of oudated packages 📜'
  brew outdated
  echo '🍺 4/5 Upgrading packages 🚚'
  brew upgrade
  echo '🍺 5/5 Cleaning up 🚮'
  brew cleanup
  echo '🍺 Done. 🎉'
end
