#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
TARGET_DIR="${TARGET_DIR:-$HOME}"

DEFAULT_PACKAGES=(
  config
  .my_bin
)

PACKAGES=()

usage() {
  cat <<'EOF'
Usage: scripts/stow.sh <install|restow|adopt|unstow|dry-run> [package...]

Commands:
  install   Create symlinks for managed packages
  restow    Recreate symlinks (safe sync after repo changes)
  adopt     Move existing target files into repo, then link them
  unstow    Remove symlinks for managed packages
  dry-run   Show what would change

Examples:
  ./scripts/stow.sh install
  ./scripts/stow.sh dry-run config
EOF
}

require_stow() {
  if ! command -v stow >/dev/null 2>&1; then
    echo "error: stow is not installed. Install with: brew install stow" >&2
    exit 1
  fi
}

run_stow() {
  local mode="$1"
  shift

  echo "dotfiles dir: ${DOTFILES_DIR}"
  echo "target dir: ${TARGET_DIR}"
  echo "packages: ${PACKAGES[*]}"

  stow --dir "${DOTFILES_DIR}" --target "${TARGET_DIR}" "$mode" "$@" "${PACKAGES[@]}"
}

main() {
  local command="${1:-}"
  require_stow

  if [ ! -d "${DOTFILES_DIR}" ]; then
    echo "error: dotfiles dir not found: ${DOTFILES_DIR}" >&2
    exit 1
  fi

  shift || true
  if [ "$#" -gt 0 ]; then
    PACKAGES=("$@")
  else
    PACKAGES=("${DEFAULT_PACKAGES[@]}")
  fi

  case "${command}" in
    install)
      run_stow --restow
      ;;
    restow)
      run_stow --restow
      ;;
    adopt)
      run_stow --restow --adopt
      ;;
    unstow)
      run_stow --delete
      ;;
    dry-run)
      run_stow --restow --adopt --simulate
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
