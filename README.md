# Dotfiles

my macbooks dotfiles

install script based on my man nullbrx's [dotfiles](https://github.com/nullbrx/dotfiles)

## Installation

I use [Homesick](https://github.com/technicalpickles/homesick) to manage and install my dotfiles.

```
$ homesick clone mcansh/dotfiles
$ homesick symlink dotfiles
$ homesick rc dotfiles
```

In order to sync vs code settings run:
```bash
$ ln -s ./settings.json ~/Library/Application\ Support/Code\ -\ Insiders/User
```
