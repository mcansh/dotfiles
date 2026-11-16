#!/usr/bin/env python3

from pathlib import Path
import os
import sys

repo = Path(__file__).resolve().parent.parent
package = repo / "agents"
central = package / "skills"
target = Path(os.environ.get("TARGET_DIR", str(Path.home()))).expanduser()
excluded = {
    line.removeprefix("skills/")
    for line in (package / ".stow-local-ignore").read_text().splitlines()
    if line.startswith("skills/")
}
errors = []
checked = 0
unavailable = 0
roots = sorted(root for root in package.rglob("skills") if root != central and not root.is_symlink())

for root in roots:
    installed_root = target / root.relative_to(package)
    for entry in root.iterdir():
        if entry.name.startswith("."):
            continue
        if not entry.is_symlink():
            errors.append(f"Skill source outside agents/skills: {entry.relative_to(repo)}")
            continue
        if not entry.resolve().is_relative_to(central):
            errors.append(f"Skill alias outside agents/skills: {entry.relative_to(repo)}")
        installed = installed_root / entry.name
        if not installed.is_symlink() or installed.resolve() != entry.resolve():
            errors.append(f"Installed alias does not match: {installed}")
        checked += 1
        unavailable += not entry.exists()
    if installed_root.is_dir():
        for installed in installed_root.iterdir():
            if installed.name.startswith(".") or installed.name in excluded or "uwm" in installed.name.lower():
                continue
            source = root / installed.name
            if not source.is_symlink():
                errors.append(f"Installed skill missing from package: {installed}")

for skill in central.iterdir():
    if not skill.is_dir() or skill.is_symlink():
        errors.append(f"Expected a central skill directory: {skill}")
        continue
    if skill.name in excluded or "uwm" in skill.name.lower():
        errors.append(f"Excluded skill in central storage: {skill.name}")
    for directory, dirs, files in os.walk(skill):
        for name in files:
            source = Path(directory) / name
            if source.is_file() and b"uwm" in source.read_bytes().lower():
                errors.append(f"UWM content in managed skill: {source.relative_to(repo)}")

for error in errors:
    print(error, file=sys.stderr)
print(f"Skill aliases checked: {checked}; unavailable aliases: {unavailable}; errors: {len(errors)}")
sys.exit(bool(errors))
