#!/usr/bin/env bash

# Set up logging environment
LOG_FILE='/Users/'$(logname)'/Desktop/install-log.log'

exec &> >(tee -a "$LOG_FILE")
echo "Logging to" $LOG_FILE

# Set HostName/ComputerName/LocalHostName
sudo -u $USER scutil --set ComputerName "🚀😺"
sudo -u $USER scutil --set LocalHostName "mcansh"
sudo -u $USER scutil --set HostName "mcansh"
echo "> 1/4 Host name is set to $(hostname)"

# Mac configuration
echo "> 2/4 Setting up computer configuration"
sudo -u $USER systemsetup -setcomputersleep 2 # Computer sleeps after 2 minutes
defaults write com.apple.screensaver askForPassword 1 # Force password entry after sleep
defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "This computer belongs to Logan McAnsh" # add a message to the login screen
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false # stop safari from opening downloaded files automatically
defaults write com.apple.dock autohide -bool true && defaults write com.apple.dock autohide-delay -float 0 && defaults write com.apple.dock autohide-time-modifier -float 0 # autohide dock and remove delay
defaults write com.apple.Dock orientation -string left # position the dock on the left side
defaults write com.apple.PowerChime ChimeOnAllHardware -bool true; open /System/Library/CoreServices/PowerChime.app & # enable the PowerChime
defaults write NSGlobalDomain _HIHideMenuBar -bool true # autohide the menubar
defaults write NSGlobalDomain AppleInterfaceStyle Dark # dark dock/menubar
defaults write com.apple.screencapture disable-shadow -bool true # remove shadow from screenshots
killall Dock # restart dock
killall -KILL SystemUIServer # restart menubar


# Check if FileValut is on
echo '> 3/4 Checking FileValue Status'
if [ "$(fdesetup status)" == "FileVault is On." ]; then
  echo "> Disk encryption is already enabled. 🔥"
elif [ "$(fdesetup status)" == "FileVault is Off." ]; then
  echo "> Disk encryption not enabled. Enabling now..."
  fdesetup enable
fi

# Install Brew
sudo -u $USER /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install ZSH
sudo -u $USER brew install zsh zsh-completions

# Install oh my ZSH
sudo -u $USER /usr/bin/ruby -e "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install Zeit's theme (usage is in .zshrc)
sudo -u $USER curl https://raw.githubusercontent.com/zeit/zeit.zsh-theme/master/zeit.zsh-theme -Lo ~/.oh-my-zsh/themes/zeit.zsh-theme

# Setup Software
sudo -u $USER brew install mas # We will need this in a bit for installing MAS
sudo -u $USER brew tap caskroom/cask
sudo -u $USER brew tap caskroom/versions
sudo -u $USER brew tap homebrew/bundle
sudo -u $USER brew tap homebrew/core
sudo -u $USER brew tap homebrew/dupes
sudo -u $USER brew bundle --file=~/dot-dotfiles/Brewfile # Install brew formalue from brewfile

# Mac Software Update Check and install updates
softwareupdate -ia --verbose --restart

# WE OUT
echo "> Welcome to your newly configured MacBook"
