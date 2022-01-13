if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Set my editor
export EDITOR="/usr/local/bin/code-insiders"

# load env from ./env.ignored
if test -f "$HOME/.dotfiles/env.ignored"
    export (grep "^[^#]" $HOME/.dotfiles/env.ignored |xargs -L 1)
end

alias gc="git commit -s"

# Don't change npm version when using n
export N_PRESERVE_NPM=1
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"

# export SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"

# Set GPG TTY
set -gx GPG_TTY (tty)

# make local npm binarys available without npx <name>
export PATH="./node_modules/.bin:$PATH"
fish_add_path /opt/homebrew/opt/gnupg@2.2/bin

# composer / laravel
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Bun
export BUN_INSTALL="/Users/loganmcansh/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

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
