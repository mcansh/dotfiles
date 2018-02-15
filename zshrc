export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="zeit"

plugins=(git git-open zsh-autosuggestions zsh-completions)

autoload -U compinit && compinit

source $ZSH/oh-my-zsh.sh

source ~/.aliases

# load hub
eval "$(hub alias -s)"

if [[ -n "$SSH_CONNECTION" ]] ;then
  export PINENTRY_USER_DATA="USE_CURSES=1"
fi

# Set my editor
export EDITOR="/usr/local/bin/code-insiders"

autoload -Uz compinit
if [ $(date +'%j') != $(stat -f '%Sm' -t '%j' ~/.zcompdump) ]; then
  compinit
else
  compinit -C
fi

eval $(thefuck --alias)

export GEM_HOME=$HOME/.gem
PATH=$PATH:$HOME/.gem/bin
eval "$(rbenv init -)"

SHELL_SCRIPTS_PATH="$HOME/.scripts"
export PATH="$PATH:$SHELL_SCRIPTS_PATH"

export PATH="$HOME/.ellipsis/bin:$PATH"
export PATH="$PATH:`yarn global bin`"
