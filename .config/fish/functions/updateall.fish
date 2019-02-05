# update everything
function updateall
  echo '▲ [1/5] Running Homebrew update script'
  brewup
  echo '▲ [2/5] Updating Rubygems'
  gem update
  gem update --system
  echo '▲ [3/5] Running Yarn Global Upgrade'
  yarn global upgrade
  echo '▲ [4/5] Updating Apps from MAS'
  mas outdated
  mas upgrade
  if test "$argv" = 'update'
    echo '▲ [5/5] Running macOS Upgrade with "--restart"'
    update --restart
  else
    echo '▲ [5/5] Running macOS Upgrade'
    update
  end
end
