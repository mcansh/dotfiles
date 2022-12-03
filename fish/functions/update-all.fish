# update everything
function update-all
    echo '▲ [1/6] Running Homebrew update script 🍺'
    brewup
    echo "▲ [2/6] Updating Node ⬢"
    n latest
    echo '▲ [2/6] Updating Rubygems 💎'
    gem update
    gem update --system
    echo '▲ [3/6] Running Yarn Global Upgrade 🧶'
    yarn global upgrade
    echo '▲ [4/6] Updating Apps from MAS 🍎'
    mas outdated
    mas upgrade
    echo '▲ [5/6] Running macOS Upgrade 🍏'
    if test (count $argv) -eq 1 -a "$argv[1]" = "--restart"
        update --restart
    else
        update
    end
end
