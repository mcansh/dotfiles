export ZSH=$HOME/.oh-my-zsh

# Theme
ZSH_THEME="zeit"

plugins=(git zsh-autosuggestions zsh-completions zsh-syntax-highlighting)

# Command auto-correction
ENABLE_CORRECTION="true"

source $ZSH/oh-my-zsh.sh

# Load aliases
source ~/.aliases

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"

# load hub
eval "$(hub alias -s)"

if [[ -n "$SSH_CONNECTION" ]] ;then
  export PINENTRY_USER_DATA="USE_CURSES=1"
fi

# Homebrew options
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CASK_OPTS=--require-sha

# Set my editor
export EDITOR="/usr/local/bin/code-insiders"

# Install nvbn/thefuck
eval $(thefuck --alias)

# Add stuff to the path
eval "$(rbenv init -)"
export GEM_HOME=$HOME/.gem
export PATH=$PATH:$HOME/.gem/bin
export PATH="$HOME/.scripts"
export PATH="$HOME/.ellipsis/bin:$PATH"
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

