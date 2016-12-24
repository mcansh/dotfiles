if [ -f ~/.bashrc ]; then
  source ~/.bashrc
  source ~/.aliases
  source ~/.bash_prompt
  source ~/.profile
  eval "$(hub alias -s)"
fi
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
function gi() { curl -L -s https://www.gitignore.io/api/$@ ;}
