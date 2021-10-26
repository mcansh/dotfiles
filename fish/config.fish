if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Set my editor
export EDITOR="/usr/local/bin/code-insiders"

# load env from env.ignored
source $HOME/.dotfiles/env.ignored

# starship init fish | source

# thefuck --alias | source

export PATH="$PATH:$HOME/.my_bin"

# export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
# export PATH="(yarn global bin):$PATH"

# export ANDROID_HOME=/Users/$USER/Library/Android/sdk
# export ANDROID_SDK_HOME=/Users/$USER/Library/Android/sdk
# export ANDROID_AVD_HOME=/Users/$USER/.android/avd

# export PATH="$HOME/.cargo/bin:$PATH"
# export PATH="$HOME/.cargo/bin:$PATH"

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
