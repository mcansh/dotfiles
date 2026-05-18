#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
TARGET_DIR="${TARGET_DIR:-$HOME}"

DEFAULT_PACKAGES=(
  config
  .my_bin
)

usage() {
  cat <<'EOF'
Usage: scripts/verify-stow.sh [package...]

Verify that package targets resolve back to files in the dotfiles repo.

Examples:
  ./scripts/verify-stow.sh
  ./scripts/verify-stow.sh config
  DOTFILES_DIR=$HOME/.dotfiles TARGET_DIR=$HOME ./scripts/verify-stow.sh .my_bin
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ ! -d "${DOTFILES_DIR}" ]; then
  echo "error: dotfiles dir not found: ${DOTFILES_DIR}" >&2
  exit 1
fi

if [ "$#" -gt 0 ]; then
  PACKAGES=("$@")
else
  PACKAGES=("${DEFAULT_PACKAGES[@]}")
fi

python3 - <<'PY' "$DOTFILES_DIR" "$TARGET_DIR" "${PACKAGES[@]}"
from pathlib import Path
import sys

dotfiles_dir = Path(sys.argv[1]).expanduser().resolve()
target_dir = Path(sys.argv[2]).expanduser().resolve()
packages = sys.argv[3:]

skip_names = {".DS_Store", "fish_variables"}
skip_contains = {"node_modules"}

def file_count(path: Path) -> int:
    return sum(
        1
        for p in path.rglob("*")
        if p.is_file()
        and p.name not in skip_names
        and not any(part in skip_contains for part in p.parts)
    )

def check_file(src: Path, tgt: Path, report):
    report["checked"] += 1

    if not (tgt.exists() or tgt.is_symlink()):
        report["missing"] += 1
        if len(report["missing_examples"]) < 8:
            report["missing_examples"].append((tgt, src))
        return

    try:
        src_resolved = src.resolve()
        tgt_resolved = tgt.resolve()
    except FileNotFoundError:
        report["wrong"] += 1
        if len(report["wrong_examples"]) < 8:
            report["wrong_examples"].append((tgt, "[broken]", src))
        return

    if tgt_resolved == src_resolved:
        report["ok"] += 1
    else:
        report["wrong"] += 1
        if len(report["wrong_examples"]) < 8:
            report["wrong_examples"].append((tgt, tgt_resolved, src))

def walk(src: Path, tgt: Path, report):
    if src.name in skip_names:
        return

    if any(part in skip_contains for part in src.parts):
        return

    if src.is_file():
        check_file(src, tgt, report)
        return

    if not src.is_dir():
        return

    if tgt.is_symlink():
        subtree_files = file_count(src)
        report["checked"] += subtree_files

        try:
            if tgt.resolve() == src.resolve():
                report["ok"] += subtree_files
            else:
                report["wrong"] += subtree_files
                if len(report["wrong_examples"]) < 8:
                    report["wrong_examples"].append((tgt, tgt.resolve(), src))
        except FileNotFoundError:
            report["wrong"] += subtree_files
            if len(report["wrong_examples"]) < 8:
                report["wrong_examples"].append((tgt, "[broken]", src))
        return

    if not tgt.exists():
        subtree_files = file_count(src)
        report["checked"] += subtree_files
        report["missing"] += subtree_files
        if len(report["missing_examples"]) < 8:
            report["missing_examples"].append((tgt, src))
        return

    if not tgt.is_dir():
        subtree_files = file_count(src)
        report["checked"] += subtree_files
        report["wrong"] += subtree_files
        if len(report["wrong_examples"]) < 8:
            report["wrong_examples"].append((tgt, tgt.resolve(), src))
        return

    for child in src.iterdir():
        walk(child, tgt / child.name, report)

overall = {
    "checked": 0,
    "ok": 0,
    "missing": 0,
    "wrong": 0,
}

print(f"dotfiles: {dotfiles_dir}")
print(f"target:   {target_dir}")
print(f"packages: {' '.join(packages)}")

for package in packages:
    src_root = dotfiles_dir / package
    report = {
        "checked": 0,
        "ok": 0,
        "missing": 0,
        "wrong": 0,
        "missing_examples": [],
        "wrong_examples": [],
    }

    if not src_root.exists():
        print(f"[{package}] package not found: {src_root}")
        continue

    walk(src_root, target_dir, report)

    overall["checked"] += report["checked"]
    overall["ok"] += report["ok"]
    overall["missing"] += report["missing"]
    overall["wrong"] += report["wrong"]

    print(
        f"[{package}] checked={report['checked']} ok={report['ok']} "
        f"missing={report['missing']} wrong_target={report['wrong']}"
    )

    for tgt, src in report["missing_examples"]:
        print(f"  MISSING     {tgt} (expected -> {src})")

    for tgt, got, src in report["wrong_examples"]:
        print(f"  WRONG_LINK  {tgt} -> {got} (expected {src})")

print(
    f"\n[overall] checked={overall['checked']} ok={overall['ok']} "
    f"missing={overall['missing']} wrong_target={overall['wrong']}"
)

if overall["checked"] == 0:
    print("[overall] warning: nothing checked")
    sys.exit(1)

if overall["missing"] > 0 or overall["wrong"] > 0:
    sys.exit(1)

sys.exit(0)
PY
