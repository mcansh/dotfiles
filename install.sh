#!/usr/bin/env bash

# Set up logging environment
LOG_FILE='/Users/'$(logname)'/Desktop/install-log.log'

exec &> >(tee -a "$LOG_FILE")
echo "Logging to" $LOG_FILE

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set HostName/ComputerName/LocalHostName
sudo -u $SUDO_USER scutil --set ComputerName "🚀😺"
sudo -u $SUDO_USER scutil --set LocalHostName "mcansh"
sudo -u $SUDO_USER scutil --set HostName "mcansh"
echo "Host name is set to $(hostname)"

# Mac configuration
echo "Setting up computer configuration"
sudo -u $SUDO_USER systemsetup -setcomputersleep 2 # Computer sleeps after 2 minutes
defaults write com.apple.screensaver askForPassword 1 # Force password entry after sleep
defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "This computer belongs to Logan McAnsh" # add a message to the login screen
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false # stop safari from opening downloaded files automatically
defaults write com.apple.dock autohide -bool true && defaults write com.apple.dock autohide-delay -float 0 && defaults write com.apple.dock autohide-time-modifier -float 0 && killall Dock # autohide dock and remove delay
defaults write com.apple.Dock orientation -string left # position the dock on the left side
defaults write com.apple.PowerChime ChimeOnAllHardware -bool true; open /System/Library/CoreServices/PowerChime.app & # enable the PowerChime
defaults write NSGlobalDomain _HIHideMenuBar -bool true # autohide the menubar
defaults write NSGlobalDomain AppleInterfaceStyle Dark # dark dock/menubar
killall Dock # restart dock
killall -KILL SystemUIServer # restart menubar


# Check if FileValut is on
if [ "$(fdesetup status)" == "FileVault is On." ]; then
  echo "Disk encryption is already enabled. 🔥"
fi

if [ "$(fdesetup status)" == "FileVault is Off." ]; then
  echo "Disk encryption not enabled. Enabling now..."
  fdesetup enable
  echo "Disk encryption is now enabled. 💯🔥"
fi

# Install Brew
sudo -u $SUDO_USER /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install ZSH
sudo -u $SUDO_USER brew install zsh zsh-completions

# Install oh my ZSH
sudo -u $SUDO_USER /usr/bin/ruby -e "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install Zeit's theme (usage is in .zshrc)
sudo -u $SUDO_USER curl https://raw.githubusercontent.com/zeit/zeit.zsh-theme/master/zeit.zsh-theme -Lo ~/.oh-my-zsh/themes/zeit.zsh-theme

# Setup Software
echo "Installing software from cask... (may take a bit if your internet is shit)"
cask_apps=('atom-beta' 'codekit' 'cyberduck' 'handbrake' 'hyper' 'transmission-nightly' 'google-chrome' 'google-chrome-canary' 'zoomus' 'whiskey' 'slack')
for i in "${cask_apps[@]}"
do
  brew cask install "${cask_apps[@]}"
done

sudo -u $SUDO_USER brew install mas # We will need this in a bit for installing MAS
sudo -u $SUDO_USER brew install gnupg21 android-platform-tools gifify hub pinentry-mac thefuck
sudo -u $SUDO_USER brew tap caskroom/cask
sudo -u $SUDO_USER brew tap caskroom/versions
sudo -u $SUDO_USER brew tap homebrew/bundle
sudo -u $SUDO_USER brew tap homebrew/core
sudo -u $SUDO_USER brew tap homebrew/dupes
sudo -u $SUDO_USER brew cask install Caskroom/cask/$cask_apps
sudo -u $SUDO_USER brew bundle

# Install Atom Packages
echo "Installing Atom Packages... This will take a few..."

if [ apm ]; then
  apm install --packages-file ~/.homesick/repos/dotfiles/atom-list.txt
else if [ apm-beta ]; then
  apm-beta install --packages-file ~/.homesick/repos/dotfiles/atom-list.txt
else
  echo "Couldn't find apm or apm-beta... You'll need to manually install your atom packages 😭"
fi


# Mac Software Update Check and install updates
softwareupdate -ia --verbose

# WE OUT
echo "Welcome to your newly configured MacBook"
