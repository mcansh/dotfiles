. ~/.config/fish/aliases.fish

# Set my editor
export EDITOR="/usr/local/bin/code-insiders"

thefuck --alias | source


export PATH="$PATH:$HOME/.my_bin";
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
rvm default

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[ -f /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/serverless.fish ]; and . /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/serverless.fish
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[ -f /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/sls.fish ]; and . /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/sls.fish
# tabtab source for slss package
# uninstall by removing these lines or running `tabtab uninstall slss`
[ -f /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/slss.fish ]; and . /Users/loganmcansh/.config/yarn/global/node_modules/tabtab/.completions/slss.fish