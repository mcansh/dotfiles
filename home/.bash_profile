if [ -f ~/.bashrc ]; then
  source ~/.bashrc
  source ~/.aliases
  eval "$(hub alias -s)"
fi
