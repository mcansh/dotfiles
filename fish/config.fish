# Set my editor
export EDITOR="/usr/local/bin/code-insiders"

# load env from env.ignored
source $HOME/.dotfiles/env.ignored

if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source

thefuck --alias | source

export PATH="$PATH:$HOME/.my_bin"

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="(yarn global bin):$PATH"

export ANDROID_HOME=/Users/$USER/Library/Android/sdk
export ANDROID_SDK_HOME=/Users/$USER/Library/Android/sdk
export ANDROID_AVD_HOME=/Users/$USER/.android/avd

set -g fish_user_paths /usr/local/sbin $fish_user_paths
export PATH="$HOME/.cargo/bin:$PATH"
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"

# Don't change npm version when using n
export N_PRESERVE_NPM=1

# Set GPG TTY
set -gx GPG_TTY (tty)

export PATH="./node_modules/.bin:$PATH"
export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"
