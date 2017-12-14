#!/usr/bin/env bash
#
# mcansh/dot ellipsis package

# The following hooks can be defined to customize behavior of your package:
# pkg.install() {
#     fs.link_files $PKG_PATH
# }

pkg.link() {
  files=(zshrc aliases hyper.js vscode install.sh)
  # link files into $HOME
  for file in ${files[@]}; do
    fs.link_file $file
  done
}

# pkg.push() {
#     git.push
# }

# pkg.pull() {
#     git.pull
# }

# pkg.installed() {
#     git.status
# }
#
# pkg.status() {
#     git.diffstat
# }
