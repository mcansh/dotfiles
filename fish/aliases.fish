# git shortcuts
alias git='hub'
alias g='git'
alias gb="git branch"
alias ga='git add'
alias gaa='git add -A'
alias gcl='git clone'
alias gcp='git cherry-pick -x'
alias gcc='git cherry-pick --continue'
alias gca='git cherry-pick --abort'
alias gcl-submodules='git clone --recursive' # clone a repo with submodules
alias gimme-submodules='git submodule update --init --recursive' # when you already cloned the repo and need the submodules
alias gs='git s'
alias gp='git push'
alias gpf='git push -f'
alias gc='git commit -sm'
alias gf='git commit -s --fixup'
alias gl='g ld'
alias gpu='git pull'
alias gd='git diff'
alias gdd='git diff --staged'
alias gco='git checkout'
alias gh='git browse'
alias gt='git tag'

alias o='open .'

# software updates
alias update='softwareupdate -ia --verbose'

# VS Code
alias code='code-insiders'
alias c='code-insiders .'

function brewup
  echo '> 1/5 Updating Homebrew 📦'
  brew update
  echo '> 2/5 Checking Homebrew for issues ⛔️'
  brew doctor
  echo '> 3/5 Getting a list of oudated packages 📜'
  brew outdated
  echo '> 4/5 Upgrading packages 🚚'
  brew upgrade
  echo '> 5/5 Cleaning up 🚮'
  brew cleanup
  echo '> Done. 🎉'
end

# update everything
function updateall
  echo '▲ [1/5] Running Homebrew update script'
  brewup
  echo '▲ [2/5] Updating Rubygems'
  gem update
  gem update --system
  echo '▲ [3/5] Running Yarn Global Upgrade'
  yarn global upgrade
  echo '▲ [4/5] Updating Apps from MAS'
  mas outdated
  mas upgrade
  echo '▲ [5/5] Running macOS Upgrade'
  update
end

# list all
alias ls='ls -1a'

# alias for making symlinks (alias)
alias makethisgohere='ln -s'

# maintenance scripts
alias maintenance='sudo periodic daily weekly monthly'

# slack emoji magic
alias slackmoji='sips -Z 128 $1'

alias yarn-upgrade='yarn upgrade-interactive --latest'
alias yarn-global-upgrade='yarn global upgrade-interactive'

# list and clear downloads table
alias list_downloads='sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* "select LSQuarantineDataURLString from LSQuarantineEvent"'
alias clear_downloads='sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* "delete from LSQuarantineEvent"'


# alias docker_list='docker ps -aq'
# alias docker_stop-'docker stop (docker ps -aq)'
# alias docker_remove_containers='docker rm (docker ps -aq)'
# alias docker_remove_images='docker rmi (docker images -q)'
