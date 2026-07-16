# Dotfiles

my macbooks dotfiles

install script based on nullbrx's
[dotfiles](https://github.com/nullbrx/dotfiles)

## Clone

```bash
git clone https://github.com/mcansh/dotfiles.git $HOME/.dotfiles
```

## Install Script

```bash
$ sh $HOME/.dotfiles/.macos
```

## GNU Stow Workflow

Prerequisite:

```bash
brew install stow
```

From the repo root:

```bash
# preview changes only
./scripts/stow.sh dry-run

# create/update symlinks
./scripts/stow.sh install

# recreate links after moving files around
./scripts/stow.sh restow

# first-time migration: pull existing files into repo + link
./scripts/stow.sh adopt

# remove managed symlinks
./scripts/stow.sh unstow

# verify managed files resolve back to dotfiles
./scripts/verify-stow.sh
```
