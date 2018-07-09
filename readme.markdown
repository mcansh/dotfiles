# Dotfiles

my macbooks dotfiles

install script based on nullbrx's
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

In order to sync VS Code settings run: (after installing my dotfile config, with VS Code closed)

```bash
$ rm ~/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
$ makethisgohere $HOME/.code/settings.json ~/Library/Application\ Support/Code\ -\ Insiders/User
```

For my snippets

```bash
$ makethisgohere $HOME/.code/javascript.json ~/Library/Application\ Support/Code\ -\ Insiders/User/snippets
```

For my keybindings

```bash
$ makethisgohere ~/dev/dot-dotfiles/code/keybindings.json ~/Library/Application\ Support/Code\ -\ Insiders/User
```
