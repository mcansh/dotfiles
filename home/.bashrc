export PATH=/usr/local/git/bin:/usr/local/bin:$PATH

# Open github repo from terminal
source ~/.open-on-github.sh
eval "$(hub alias -s)"

# I assume something for homebrew?
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  source $(brew --prefix)/etc/bash_completion
fi


eval "$(thefuck --alias)"
# You can use whatever you want as an alias, like for Mondays:
eval "$(thefuck --alias FUCK)"


# export GPG_TTY=$(tty)
if [[ -n "$SSH_CONNECTION" ]] ;then
    export PINENTRY_USER_DATA="USE_CURSES=1"
fi


# Set my editor to Atom
export EDITOR="/usr/local/bin/atom-beta"


# I assume something for homebrew?
if [ -f $(brew --prefix)/etc/brew-wrap ];then
  source $(brew --prefix)/etc/brew-wrap
fi

# Add RVM to PATH for scripting
export PATH="$PATH:$HOME/.rvm/bin"

# This loads nvm
export NVM_DIR="/Users/loganmcansh/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
