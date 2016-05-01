export PATH=/usr/local/git/bin:/usr/local/bin:$PATH
export PATH=${PATH}:/Users/loganmcansh/Downloads/Android/Mac/adb

# Open github repo from terminal
source ~/.open-on-github.sh
eval "$(hub alias -s)"


if [ -f $(brew --prefix)/etc/bash_completion ]; then
  source $(brew --prefix)/etc/bash_completion
fi


# Android SDK
export ANDROID_HOME=/usr/local/Cellar/android-sdk/24.4.1_1
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
export PATH=$ANDROID_HOME/tools:$PATH


eval "$(thefuck --alias)"
# You can use whatever you want as an alias, like for Mondays:
eval "$(thefuck --alias FUCK)"


export GPG_TTY=$(tty)
if [[ -n "$SSH_CONNECTION" ]] ;then
    export PINENTRY_USER_DATA="USE_CURSES=1"
fi

#Set my editor to Atom
export EDITOR="atom"
