#!/usr/bin/env bash

# Set up logging environment
LOG_FILE='/Users/'$(logname)'/Desktop/install-log.log'

exec &> >(tee -a "$LOG_FILE")
echo "Logging to" $LOG_FILE

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set Hostname
sudo -u $SUDO_USER scutil --set ComputerName "🚀😺"
sudo -u $SUDO_USER scutil --set LocalHostName "mcansh"
sudo -u $SUDO_USER scutil --set HostName "mcansh"
echo "Host name is set to $(hostname)" # TODO Make sure this actually sticks after restart

# Mac configuration
echo "Setting up computer configuration"
systemsetup -setcomputersleep 3 # Computer sleeps after 3 minutes
defaults write com.apple.screensaver askForPassword 1 # Force password entry after sleep
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false # stop safari from opening downloaded files automatically
defaults write com.apple.dock autohide -bool true && defaults write com.apple.dock autohide-delay -float 0 && defaults write com.apple.dock autohide-time-modifier -float 0 && killall Dock # autohide dock
defaults write com.apple.PowerChime ChimeOnAllHardware -bool true; open /System/Library/CoreServices/PowerChime.app & # enable the PowerChime
dotfiles=".aliases .bash_profile .bash_prompt .bashrc .gitconfig .hyper.js .open-on-github.sh .zshrc"
defaults write NSGlobalDomain _HIHideMenuBar -bool true # autohide the menubar
defaults write NSGlobalDomain AppleInterfaceStyle Dark # dark dock/menubar
killall Dock # restart dock
killall -KILL SystemUIServer # restart menubar

mv $DIR/$dotfiles ~/ # move dotfiles to user dir


# Check if FileValut is on
if [ "$(fdesetup status)" == "FileVault is On." ]; then
  echo "Disk encryption is already enabled. 🔥"
fi

if [ "$(fdesetup status)" == "FileVault is Off." ]; then
  echo "Disk encryption not enabled. Enabling now..."
  fdesetup enable
fi

# Setup Brew
sudo -u $SUDO_USER /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Setup oh my zsh
sudo -u $SUDO_USER /usr/bin/ruby -e "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Setup Software
echo "Installing software from cask... (may take a bit if the internet is shit)"
cask_apps="atom-beta codekit cyberduck handbrake hyper sonos transmission-nightly google-chrome"

sudo -u $SUDO_USER brew install mas # We will need this in a bit for installing MAS
sudo -u $SUDO_USER brew install gnupg21 android-platform-tools gifify hub pinentry-mac thefuck
sudo -u $SUDO_USER brew tap caskroom/cask
sudo -u $SUDO_USER brew tap caskroom/versions
sudo -u $SUDO_USER brew tap homebrew/bundle
sudo -u $SUDO_USER brew tap homebrew/core
sudo -u $SUDO_USER brew tap homebrew/dupes
sudo -u $SUDO_USER brew cask install Caskroom/cask/$cask_apps

# Install Atom Packages
atom_packages="Lucario atom-beautify atom-jade atom-material-ui atom-panda-syntax autoclose-html autocomplete-css-with-stylus-support autocomplete-emojis chester-atom-syntax civic-syntax double-tag dracula-theme emmet file-icons integrated-learn-environment itg-dark-syntax jade-snippets language-pug language-sass language-stylus linter linter-eslint minimap minimap-cursorline multi-cursor nord-atom-syntax open-in-browser package-sync pigments ramda-syntax snippets-jade sort-lines stylus-autocompile"

echo "Installing Atom Packages... This may take a sec"
if [ apm ]; then
  apm install $atom_packages
else if [apm-beta]; then
  apm-beta install $atom_packages
else
  echo "Could'nt find apm or apm-beta... You'll need to manually install your atom packages"
fi

# Install Mac Store Apps
if mas account; then
    echo "Installing Mac Store Apps..."
    mac_apps_ids="497799835 1053031090 443987910 1083965373 446107677 557168941 924726344 439697913 936243210 1152443474 1126100185 490192174 984968384 1081413713"
    sudo -u $SUDO_USER mas install $mac_apps_ids
else
    echo "Not signed in to MAS. You'll need to install them manually for now :("
fi


# TODO Mac Software Update Check and install updates
softwareupdate -ia --verbose

#WE OUT
echo "all done!:) 🙏🙏🙏🙏🙏🙏🙏🙏🙏🙏🙏🙏🙏"
