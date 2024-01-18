# update everything
function update-all
    # ask for the administrator password upfront
    sudo -v
    echo '▲ Running Homebrew update script 🍺'
    brewup

    echo "▲ Updating Node ⬢"
    n latest

    if type -q rustup
        echo "▲ Updating Rust 🦀"
        rustup update
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

    echo '▲ Running macOS Upgrade 🍏'
    softwareupdate --install --all --verbose --restart

    echo "▲ Checking for pnpm, npm, and yarn updates"
    corepack prepare pnpm@latest --activate
    corepack prepare npm@latest --activate
    corepack prepare yarn@1 --activate

    echo "▲ Checking for pnpm global updates"
    pnpm update --interactive --latest --global

    echo "▲ Checking for npm global updates"
    ncu -g

    echo '▲ Running Yarn Global Upgrade 🧶'
    yarn global upgrade
end
