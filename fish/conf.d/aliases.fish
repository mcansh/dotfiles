# git shortcuts
alias g='git'
alias gb='git branch'
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
alias gt='git tag'
alias gri='git ls-files --ignored --exclude-standard | xargs -0 git rm -r'

alias yd='yarn dev'
alias yb='yarn build'
alias ys='yarn start'

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop='defaults write com.apple.finder CreateDesktop -bool false && killall Finder'
alias showdesktop='defaults write com.apple.finder CreateDesktop -bool true && killall Finder'

# re-run the last command as sudo
alias please='eval sudo $history[1]'

# Clean up LaunchServices to remove duplicates in the “Open With” menu
alias appflush='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder'

# maintenance scripts
alias maintenance='sudo periodic daily weekly monthly'

# Lock the screen (when going AFK)
alias afk='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'

# add space to dock
alias space='defaults write com.apple.dock persistent-apps -array-add "{'tile-type'='spacer-tile';}"; killall Dock'

# slack emoji magic
alias slackmoji='sips -Z 128 $1'

# gifify 60fps
alias gifify60='gifify -r 60 $1'

# VS Code
alias code='code-insiders'
alias c='code-insiders .'

# list all
alias ls='ls -1a'

# alias for making symlinks (alias)
alias makethisgohere='ln -s'
alias ...='cd ../../'

# maintenance scripts
alias maintenance='sudo periodic daily weekly monthly'

# slack emoji magic
alias slackmoji='sips -Z 128 $1'

alias yarn-upgrade='yarn upgrade-interactive --latest'
alias yarnup='yarn-upgrade'
alias yarn-global-upgrade='yarn global upgrade-interactive'
alias npm-list-global='npm list -g --depth=0'

# list and clear downloads table
alias list_downloads='sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* "select LSQuarantineDataURLString from LSQuarantineEvent"'
alias clear_downloads='sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* "delete from LSQuarantineEvent"'


alias docker_list='docker ps -aq'
alias docker_stop='docker stop (docker ps -aq)'
alias docker_remove_containers='docker rm (docker ps -aq)'
alias docker_remove_images='docker rmi (docker images -q)'

# undo the last git commit
alias gitnvm="git reset --soft HEAD~1"
