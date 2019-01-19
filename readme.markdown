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
$ makethisgohere $HOME/.code/settings.json ~/Library/Application\ Support/Code\ -\ Insiders/User
```

For my keybindings

```bash
$ makethisgohere $HOME/.code/keybindings.json ~/Library/Application\ Support/Code\ -\ Insiders/User
```
