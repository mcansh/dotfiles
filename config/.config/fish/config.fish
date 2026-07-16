# Environment
set -gx EDITOR /usr/local/bin/code-insiders
set -gx HOMEBREW_BUNDLE_DUMP_NO_VSCODE 1
set -gx N_PRESERVE_NPM 1
set -gx N_PREFIX "$HOME/.n"
set -gx NODE_PATH "$N_PREFIX/lib/node_modules"
set -gx BUN_INSTALL "$HOME/.bun"
set -gx DENO_INSTALL "$HOME/.deno"
set -gx PNPM_HOME "$HOME/Library/pnpm"
set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
set -gx PHP_INI_SCAN_DIR "$HOME/Library/Application Support/Herd/config/php:$PHP_INI_SCAN_DIR"

# Load private environment variables without spawning grep and xargs.
if test -f "$HOME/.dotfiles/env.ignored"
    export (string match -rv '^\s*(#|$)' < "$HOME/.dotfiles/env.ignored")
end

# Remove duplicate and malformed entries inherited from older shell sessions.
set -l clean_path
for path_entry in $PATH
    string match -qr '^(`gem|gemdir`/bin)$' -- "$path_entry"; and continue
    contains -- "$path_entry" $clean_path; or set -a clean_path "$path_entry"
end
set -gx PATH $clean_path

set -l managed_paths \
    "$HOME/.nub/bin" \
    "$HOME/.termcast/compiled/tuitube/bin"

# Homebrew Ruby stores gem executables in versioned directories. Globbing keeps
# this current across upgrades without invoking Ruby during shell startup.
set -l ruby_gem_bins /opt/homebrew/lib/ruby/gems/*/bin
set -a managed_paths $ruby_gem_bins[-1..1]

set -a managed_paths \
    /opt/homebrew/opt/ruby/bin \
    "$HOME/.cargo/bin" \
    "$PNPM_HOME/bin" \
    /opt/homebrew/bin \
    "$HOME/Library/Application Support/Herd/bin" \
    "$DENO_INSTALL/bin" \
    "$BUN_INSTALL/bin" \
    "$HOME/.composer/vendor/bin" \
    "/Applications/Sublime Text.app/Contents/SharedSupport/bin" \
    "$HOME/.dotfiles/.my_bin" \
    "$N_PREFIX/bin"

fish_add_path --path --move $managed_paths
contains -- ./node_modules/.bin $PATH; or set -p PATH ./node_modules/.bin

# Prefer the PEM certificate when both local UWM bundles are available.
set -l uwm_cert "$HOME/uwm-certs/uwm-ca-bundle.crt"
set -l uwm_cert_pem "$HOME/uwm-certs/uwm-ca-bundle.pem"

if test -f "$uwm_cert_pem"
    set -gx NODE_EXTRA_CA_CERTS "$uwm_cert_pem"
else if test -f "$uwm_cert"
    set -gx NODE_EXTRA_CA_CERTS "$uwm_cert"
end

# Fish 4.8 can wait 10 seconds for terminal capability replies that some
# terminals do not implement. Persist Fish's documented compatibility flag;
# the guard keeps established shells and the universal-variable file untouched.
contains -- no-query-term $fish_features; or set -Ua fish_features no-query-term

status is-interactive; or return

# Interactive integrations
# Atuin's generated hook is stable between binary upgrades. Cache it so a cold
# shell does not have to launch Atuin just to print the first prompt.
if command -q atuin
    set -l atuin_path (command -s atuin)
    set -l atuin_resolved_path (path resolve "$atuin_path")
    set -l atuin_cache "$HOME/.cache/fish/atuin-init.fish"
    set -l atuin_cache_path "$atuin_cache.path"
    set -l cached_atuin_path

    test -r "$atuin_cache_path"; and set cached_atuin_path (string collect <"$atuin_cache_path")

    if not test -s "$atuin_cache"; or test "$cached_atuin_path" != "$atuin_resolved_path"; or test "$atuin_path" -nt "$atuin_cache"
        command mkdir -p (path dirname "$atuin_cache")
        set -l atuin_temp "$atuin_cache.$fish_pid"
        set -l atuin_path_temp "$atuin_cache_path.$fish_pid"

        if atuin init fish >"$atuin_temp"
            printf '%s\n' "$atuin_resolved_path" >"$atuin_path_temp"
            command mv "$atuin_temp" "$atuin_cache"
            command mv "$atuin_path_temp" "$atuin_cache_path"
        else
            command rm -f "$atuin_temp" "$atuin_path_temp"
        end
    end

    # The generated hook otherwise launches `atuin uuid` on every new shell.
    # A standards-shaped UUID made from Fish builtins is sufficient as Atuin's
    # per-shell session identifier and avoids paging in the Atuin binary.
    if not set -q ATUIN_SESSION; or test "$ATUIN_SHLVL" != "$SHLVL"
        set -gx ATUIN_SESSION (printf '%04x%04x-%04x-4%03x-%x%03x-%04x%04x%04x' \
            (random 0 65535) (random 0 65535) (random 0 65535) \
            (random 0 4095) (random 8 11) (random 0 4095) \
            (random 0 65535) (random 0 65535) (random 0 65535))
        set -gx ATUIN_SHLVL $SHLVL
    end

    test -s "$atuin_cache"; and source "$atuin_cache"
end

set -gx GPG_TTY (tty)

alias gc='git commit --signoff'
alias gl='git ld'
alias gdd='git diff --staged'
alias gcp='git cherry-pick -x'
alias gitnvm='git reset --soft HEAD~1'
alias ls='ls -1a'
alias makethisgohere='ln -s'
alias youtube-dl='yt-dlp'

set -g hydro_symbol_prompt ▲

# Cache generated Pay Respects integration until its executable changes.
if command -q pay-respects
    set -l pay_respects_path (command -s pay-respects)
    set -l pay_respects_cache "$HOME/.cache/fish/pay-respects.fish"

    if not test -f "$pay_respects_cache"; or test "$pay_respects_path" -nt "$pay_respects_cache"
        command mkdir -p (path dirname "$pay_respects_cache")
        set -l pay_respects_temp "$pay_respects_cache.$fish_pid"

        if pay-respects fish --alias >"$pay_respects_temp"
            command mv "$pay_respects_temp" "$pay_respects_cache"
        else
            command rm -f "$pay_respects_temp"
        end
    end

    test -f "$pay_respects_cache"; and source "$pay_respects_cache"
end

# Fish autoloads this cache only when Codex completions are requested.
if command -q codex
    set -l codex_path (command -s codex)
    set -l codex_completions "$HOME/.cache/fish/generated_completions/codex.fish"

    if not test -f "$codex_completions"; or test "$codex_path" -nt "$codex_completions"
        command mkdir -p (path dirname "$codex_completions")
        set -l codex_temp "$codex_completions.$fish_pid"

        if codex completion fish >"$codex_temp"
            command mv "$codex_temp" "$codex_completions"
        else
            command rm -f "$codex_temp"
        end
    end
end
