# update everything
function update-all
    # ask for the administrator password upfront
    sudo -v || return $status

    echo '▲ Running Homebrew update script 🍺'
    brewup

    echo "▲ Updating Node ⬢"
    n latest

    # clean up old node version of the same major
    node "~/.dotfiles/n-cleanup.mjs"

    if type -q rustup
        echo "▲ Updating Rust 🦀"
        rustup
    else
        echo "▲ Rust not installed, skipping"
    end

    echo '▲ Updating Rubygems 💎'
    gem update
    gem update --system

    if type -q mas
        echo '▲ Updating Apps from MAS 🍎'
        mas outdated
        mas upgrade
    end

    echo "▲ Checking for pnpm, npm, and yarn updates"

    echo "▲ Checking for pnpm global updates"
    corepack prepare pnpm@latest --activate
    pnpm update --interactive --latest --global

    echo "▲ Checking for npm global updates"
    corepack prepare npm@latest --activate
    ncu -g

    if type -q yarn
        echo '▲ Running Yarn Global Upgrade 🧶'
        corepack prepare yarn@1 --activate
        yarn global upgrade
    end

    echo '▲ Running macOS Upgrade 🍏'
    softwareupdate --install --all --verbose --restart
end
