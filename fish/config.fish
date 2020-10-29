# Load aliases
. ~/.config/fish/aliases.fish

# Set my editor
export EDITOR="/usr/local/bin/code-insiders"

thefuck --alias | source

export PATH="$PATH:$HOME/.my_bin"

#rvm default

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[ -f /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/serverless.fish ]
and . /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/serverless.fish
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[ -f /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/sls.fish ]
and . /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/sls.fish
# tabtab source for slss package
# uninstall by removing these lines or running `tabtab uninstall slss`
[ -f /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/slss.fish ]
and . /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/slss.fish

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
export PATH="(yarn global bin):$PATH"

export ANDROID_HOME=/Users/$USER/Library/Android/sdk
export ANDROID_SDK_HOME=/Users/$USER/Library/Android/sdk
export ANDROID_AVD_HOME=/Users/$USER/.android/avd

alias ld='lazydocker'

#eval (starship init fish)
set -g fish_user_paths "/usr/local/sbin" $fish_user_paths
export PATH="$HOME/.cargo/bin:$PATH"
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/fish/__tabtab.fish ]; and . ~/.config/tabtab/fish/__tabtab.fish; or true

# load env from env.ignored
export (grep "^[^#]" $HOME/.dotfiles/env.ignored |xargs -L 1)
