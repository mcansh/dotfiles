# Dotfiles

my macbooks dotfiles

install script based on my man nullbrx's
[dotfiles](https://github.com/nullbrx/dotfiles)

## Installation

I use [ellipsis](http://ellipsis.sh) to manage and install my dotfiles.

```
$ ellipsis install mcansh/dotfiles
```

## Install Script

```bash
$ sh $HOME/.install.sh
```

## VS Code

In order to sync vs code settings run: (after installing my dotfile config)

```bash
$ rm ~/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
$ makethisgohere $HOME/.code/.settings.json ~/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
```

For my snippets

```bash
$ makethisgohere $HOME/.code/.javascript.json ~/Library/Application Support/Code - Insiders/User/snippets/javascript.json
```
