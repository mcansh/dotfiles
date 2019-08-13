# Dotfiles

my macbooks dotfiles

install script based on nullbrx's
[dotfiles](https://github.com/nullbrx/dotfiles)

## Install Script

```bash
$ sh $HOME/.install.sh
```

## VS Code

If for whatever reason, these aren't copied over, you can run the following

```bash
$ rm ~/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
$ makethisgohere $HOME/dotfiles/code/settings.json ~/Library/Application\ Support/Code\ -\ Insiders/User
```

keybindings

```bash
$ rm ~/Library/Application\ Support/Code\ -\ Insiders/User/keybindings.json
$ makethisgohere $HOME/dotfiles/code/keybindings.json ~/Library/Application\ Support/Code\ -\ Insiders/User
```

Snippets

```bash
$ makethisgohere $HOME/dotfiles/code/snippets/typescriptreact.json ~/Library/Application\ Support/Code\ -\ Insiders/User/snippets
```
