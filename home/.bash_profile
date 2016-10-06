if [ -f ~/.bashrc ]; then
  source ~/.bashrc
  source ~/.aliases
  source ~/.bash_prompt
  eval "$(hub alias -s)"
fi