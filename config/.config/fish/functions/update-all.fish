# update everything
function update-all
    set -l failed 0

    # ask for the administrator password upfront
    if command -q sudo
        sudo -v || return $status
    end

    if command -q brew; and type -q brewup
        echo '▲ Running Homebrew update script 🍺'
        brewup; or set failed 1
    else
        echo '▲ Homebrew or brewup not installed, skipping'
    end

    if command -q nub
        echo '▲ Updating Node ⬢'
        if nub node install latest
            # Only clean up versions after a successful update.
            if command -q node; and test -f "$HOME/.dotfiles/nub-node-cleanup.mjs"
                node "$HOME/.dotfiles/nub-node-cleanup.mjs"; or set failed 1
            else
                echo '▲ Node or cleanup script not found, skipping cleanup'
            end
        else
            set failed 1
        end
    else
        echo '▲ nub not installed, skipping Node update'
    end

    if command -q rustup
        echo "▲ Updating Rust 🦀"
        rustup update; or set failed 1
    else
        echo "▲ Rust not installed, skipping"
    end

    if command -q gem
        echo '▲ Updating Rubygems 💎'
        gem update; or set failed 1
        gem update --system; or set failed 1
    else
        echo '▲ gem not installed, skipping RubyGems update'
    end

    if command -q mas
        echo '▲ Updating Apps from MAS 🍎'
        mas outdated; or set failed 1
        mas upgrade; or set failed 1
    else
        echo '▲ mas not installed, skipping App Store updates'
    end

    echo "▲ Checking for pnpm, npm, and yarn updates"

    for manager in pnpm npm yarn
        set -l executable
        for candidate in (command -sa $manager)
            set -l resolved (path resolve -- "$candidate")
            # Global updates must not provision a project-pinned manager via a shim.
            string match -qr '/(corepack/|\.?nub/shims/)' -- "$candidate" "$resolved"; and continue
            if "$candidate" --version >/dev/null 2>&1
                set executable "$candidate"
                break
            end
        end

        if not set -q executable[1]
            echo "▲ No working standalone $manager CLI found, skipping global updates"
            continue
        end

        echo "▲ Checking for $manager global updates"
        switch $manager
            case pnpm
                "$executable" update --interactive --latest --global; or set failed 1
            case npm
                if command -q ncu
                    ncu -g; or set failed 1
                else
                    echo '▲ ncu not installed, skipping npm global update check'
                end
            case yarn
                "$executable" global upgrade; or set failed 1
        end
    end

    if command -q softwareupdate
        echo '▲ Running macOS Upgrade 🍏'
        softwareupdate --install --all --verbose --restart; or set failed 1
    else
        echo '▲ softwareupdate not installed, skipping macOS upgrade'
    end

    if test $failed -ne 0
        echo '▲ One or more updates failed' >&2
    end
    return $failed
end
