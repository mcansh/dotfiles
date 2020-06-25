# update everything
function updateall
    echo '▲ [1/5] Running Homebrew update script 🍺'
    brewup
    echo '▲ [2/5] Updating Rubygems 💎'
    gem update
    gem update --system
    echo '▲ [3/5] Running Yarn Global Upgrade 🧶'
    yarn global upgrade
    echo '▲ [4/5] Updating Apps from MAS 🍎'
    mas outdated
    mas upgrade
    echo '▲ [5/5] Running macOS Upgrade 🍏'
    if test (count $argv) -eq 1 -a "$argv[1]" = "--restart"
        update --restart
    else
        update
    end
end
