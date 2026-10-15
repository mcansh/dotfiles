#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
fish_bin=$(command -v fish)
"$fish_bin" --no-config -n "$repo_dir/config/.config/fish/functions/update-all.fish" \
    "$repo_dir/config/.config/fish/functions/brewup.fish"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/home/.dotfiles"
touch "$test_dir/home/.dotfiles/nub-node-cleanup.mjs"
export UPDATE_ALL_TEST_LOG="$test_dir/commands"
export UPDATE_ALL_TEST_FAIL=''

# Every updater is a stub; the isolated PATH cannot reach real update commands.
cat > "$test_dir/stub" <<'STUB'
#!/bin/sh
step="${0##*/} $*"
printf '%s\n' "$step" >> "$UPDATE_ALL_TEST_LOG"
if [ "$step" = "$UPDATE_ALL_TEST_FAIL" ]; then
    exit 7
fi
STUB
chmod +x "$test_dir/stub"
clis=(sudo brew nub node rustup gem mas corepack pnpm npm ncu yarn softwareupdate)

install_stubs() {
    rm -f "$test_dir/bin/"*
    for cli in "${clis[@]}"; do
        ln -s "$test_dir/stub" "$test_dir/bin/$cli"
    done
}

run_update() {
    : > "$UPDATE_ALL_TEST_LOG"
    result=0
    PATH="$test_dir/bin${UPDATE_ALL_TEST_EXTRA_PATH:+:$UPDATE_ALL_TEST_EXTRA_PATH}" HOME="$test_dir/home" "$fish_bin" --no-config -c '
        source "$argv[1]/config/.config/fish/functions/brewup.fish"
        source "$argv[1]/config/.config/fish/functions/update-all.fish"
        update-all
    ' -- "$repo_dir" > "$test_dir/output" 2>&1 || result=$?
    if [[ $result -ne $1 ]]; then
        cat "$test_dir/output" >&2
        echo "Expected status $1, got $result" >&2
        exit 1
    fi
    if grep -q 'Unknown command' "$test_dir/output"; then
        cat "$test_dir/output" >&2
        exit 1
    fi
    if grep -q '^corepack ' "$UPDATE_ALL_TEST_LOG"; then
        echo 'Corepack must not be invoked' >&2
        exit 1
    fi
}

has_run() { grep -Fxq "$1" "$UPDATE_ALL_TEST_LOG"; }
has_not_run() {
    if has_run "$1"; then
        echo "Unexpected command: $1" >&2
        exit 1
    fi
}

run_update 0
[[ ! -s "$UPDATE_ALL_TEST_LOG" ]]

install_stubs
run_update 0
has_run 'rustup update'
has_run "node $test_dir/home/.dotfiles/nub-node-cleanup.mjs"
has_run 'softwareupdate --install --all --verbose --restart'

# Each missing CLI is skipped without making unrelated updates fail.
for cli in "${clis[@]}"; do
    install_stubs
    rm "$test_dir/bin/$cli"
    run_update 0
    if grep -q "^$cli " "$UPDATE_ALL_TEST_LOG"; then
        echo "Missing CLI was invoked: $cli" >&2
        exit 1
    fi
done

# Failures remain visible even when later updaters succeed.
install_stubs
for step in 'brew update' 'brew doctor' 'brew outdated' 'brew upgrade' \
    'brew upgrade --cask' 'brew cleanup' 'nub node install latest' \
    "node $test_dir/home/.dotfiles/nub-node-cleanup.mjs" 'rustup update' \
    'gem update' 'gem update --system' 'mas outdated' 'mas upgrade' \
    'pnpm update --interactive --latest --global' 'ncu -g' 'yarn global upgrade' \
    'softwareupdate --install --all --verbose --restart'; do
    export UPDATE_ALL_TEST_FAIL="$step"
    run_update 1
    has_run 'softwareupdate --install --all --verbose --restart'
    if [[ "$step" = 'nub node install latest' ]]; then
        has_not_run "node $test_dir/home/.dotfiles/nub-node-cleanup.mjs"
    fi
done

# A broken standalone CLI is skipped rather than treated as installed.
for manager in pnpm npm yarn; do
    export UPDATE_ALL_TEST_FAIL="$manager --version"
    run_update 0
    case $manager in
        pnpm) has_not_run 'pnpm update --interactive --latest --global' ;;
        npm) has_not_run 'ncu -g' ;;
        yarn) has_not_run 'yarn global upgrade' ;;
    esac
done

# Corepack symlinks and Nub shims must never be executed, even for --version.
export UPDATE_ALL_TEST_FAIL=''
mkdir -p "$test_dir/corepack/dist" "$test_dir/nub/shims" "$test_dir/standalone CLIs"
for manager in pnpm npm yarn; do
    cp "$test_dir/stub" "$test_dir/corepack/dist/$manager.js"
    cp "$test_dir/stub" "$test_dir/nub/shims/$manager"
done
for shim_dir in "$test_dir/corepack/dist" "$test_dir/nub/shims"; do
    for manager in pnpm npm yarn; do
        rm "$test_dir/bin/$manager"
        target="$shim_dir/$manager"
        [[ $shim_dir != */corepack/dist ]] || target="$target.js"
        ln -s "$target" "$test_dir/bin/$manager"
    done
    run_update 0
    if grep -Eq '^(pnpm|npm|yarn)(\.js)? ' "$UPDATE_ALL_TEST_LOG"; then
        echo 'A package-manager shim was executed' >&2
        exit 1
    fi
    has_not_run 'ncu -g'

    # A real CLI later on PATH is invoked directly, bypassing the shim.
    for manager in pnpm npm yarn; do
        cp "$test_dir/stub" "$test_dir/standalone CLIs/$manager"
    done
    export UPDATE_ALL_TEST_EXTRA_PATH="$test_dir/standalone CLIs"
    run_update 0
    has_run 'pnpm update --interactive --latest --global'
    has_run 'ncu -g'
    has_run 'yarn global upgrade'
    unset UPDATE_ALL_TEST_EXTRA_PATH
done
install_stubs

export UPDATE_ALL_TEST_FAIL='sudo -v'
run_update 7
[[ $(wc -l < "$UPDATE_ALL_TEST_LOG") -eq 1 ]]

export UPDATE_ALL_TEST_FAIL=''
rm "$test_dir/home/.dotfiles/nub-node-cleanup.mjs"
run_update 0
has_not_run "node $test_dir/home/.dotfiles/nub-node-cleanup.mjs"
echo 'update-all checks passed'
