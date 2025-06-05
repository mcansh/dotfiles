if status is-interactive
  # Commands to run in interactive sessions can go here
end

# Set my editor
export EDITOR="/usr/local/bin/code-insiders"

# load env from ./env.ignored
if test -f "$HOME/.dotfiles/env.ignored"
  export (grep "^[^#]" $HOME/.dotfiles/env.ignored | xargs -L 1)
end

alias gc="git commit -s"
alias gl="git ld"
alias gdd='git diff --staged'
alias gcp='git cherry-pick -x'
alias gitnvm="git reset --soft HEAD~1"

alias ls='ls -1a'

alias makethisgohere='ln -s'

alias youtube-dl='yt-dlp'

# Don't change npm version when using n
export N_PRESERVE_NPM=1
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
export NODE_PATH="$N_PREFIX/lib/node_modules"

export PATH="$HOME/.dotfiles/.my_bin:$PATH"

# tell GPG the current terminal.
export GPG_TTY=(tty)

# make local npm binarys available without npx <name>
export PATH="./node_modules/.bin:$PATH"

# sublime text cli
export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"

# composer / laravel
export PATH="$HOME/.composer/vendor/bin:$PATH"

export PATH="$HOME/.deno/bin:$PATH"

# Bun completions
# [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Deno
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Herd injected PHP binary.
export PATH="$HOME/Library/Application Support/Herd/bin:$PATH"
export PHP_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php:$PHP_INI_SCAN_DIR"

set -g __fish_git_prompt_show_informative_status 1
set -g __fish_git_prompt_hide_untrackedfiles 1

set -g __fish_git_prompt_color_branch magenta --bold
set -g __fish_git_prompt_showupstream informative
set -g __fish_git_prompt_char_upstream_ahead "↑"
set -g __fish_git_prompt_char_upstream_behind "↓"
set -g __fish_git_prompt_char_upstream_prefix ""

set -g __fish_git_prompt_char_stagedstate "●"
set -g __fish_git_prompt_char_dirtystate "✚"
set -g __fish_git_prompt_char_untrackedfiles "…"
set -g __fish_git_prompt_char_conflictedstate "✖"
set -g __fish_git_prompt_char_cleanstate "✔"

set -g __fish_git_prompt_color_dirtystate blue
set -g __fish_git_prompt_color_stagedstate yellow
set -g __fish_git_prompt_color_invalidstate red
set -g __fish_git_prompt_color_untrackedfiles $fish_color_normal
set -g __fish_git_prompt_color_cleanstate green --bold

# add brew to path and configure autocomplete
fish_add_path /opt/homebrew/sbin

if test -d (brew --prefix)"/share/fish/completions"
    set -p fish_complete_path (brew --prefix)/share/fish/completions
end

if test -d (brew --prefix)"/share/fish/vendor_completions.d"
    set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
end


# pnpm
set -gx PNPM_HOME "$HOME/Library/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
# pnpm end

# Cargo / Rust
export PATH="$HOME/.cargo/bin:$PATH"
# source $HOME/.cargo/env

if which rbenv > /dev/null
  eval "$(rbenv init -)"
end


# 1Password CLI
# op completion fish | source

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/fish/__tabtab.fish ]; and . ~/.config/tabtab/fish/__tabtab.fish; or true

set --global hydro_symbol_prompt ▲

[ -f ~/.inshellisense/key-bindings.fish ] && source ~/.inshellisense/key-bindings.fish

set --global SSH_AUTH_SOCK "~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock"

pay-respects fish --alias | source
atuin init fish | source

set UWM_CERT "$HOME/uwm-certs/uwm-ca-bundle.crt"
set UWM_CERT_PEM "$HOME/uwm-certs/uwm-ca-bundle.pem"

if test -f $UWM_CERT
  export NODE_EXTRA_CA_CERTS=$UWM_CERT
end

if test -f $UWM_CERT_PEM
    export NODE_EXTRA_CA_CERTS=$UWM_CERT_PEM
end
