#!/usr/bin/env python3
"""Generate Cursor metadata; skill directories remain the source of truth."""

import argparse
import json
from pathlib import Path
import re
import sys

import yaml


SKILLS = Path("agents/.agents/skills")
MARKETPLACE = Path(".cursor-plugin/marketplace.json")
IDENTIFIER = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")


def render(value):
    return json.dumps(value, indent=2, ensure_ascii=False) + "\n"


def sync(root, check=False):
    """Validate all skills before changing any generated files."""
    skills = root / SKILLS
    entries = []
    expected = {}
    names = set()
    for source in sorted(skills.glob("*/SKILL.md")):
        text = source.read_text(encoding="utf-8")
        lines = text.splitlines()
        if not lines or lines[0] != "---" or "---" not in lines[1:]:
            raise ValueError(f"{source}: missing YAML frontmatter")
        end = lines.index("---", 1)
        metadata = yaml.safe_load("\n".join(lines[1:end]))
        if not isinstance(metadata, dict):
            raise ValueError(f"{source}: frontmatter must be a mapping")
        name = metadata.get("name")
        description = metadata.get("description")
        if not isinstance(name, str) or not IDENTIFIER.fullmatch(name):
            raise ValueError(f"{source}: name must be lowercase kebab-case")
        if name in names:
            raise ValueError(f"{source}: duplicate skill name {name}")
        if not isinstance(description, str) or not description.strip():
            raise ValueError(f"{source}: description must be a nonempty string")
        names.add(name)
        # Cursor discovers a root SKILL.md as a single-skill plugin. Keeping
        # the plugin root here also preserves scripts and relative references.
        plugin = {"name": name, "description": description.strip()}
        path = source.parent.relative_to(root)
        expected[path / ".cursor-plugin/plugin.json"] = render(plugin)
        entries.append({**plugin, "source": path.as_posix()})

    if not entries:
        raise ValueError(f"{skills}: no skills found; refusing to empty the marketplace")
    expected[MARKETPLACE] = render({
        "name": "mcansh-dotfiles",
        "owner": {"name": "Logan McAnsh"},
        "metadata": {"description": "Agent skills from mcansh/dotfiles"},
        "plugins": entries,
    })
    existing = {p.relative_to(root) for p in skills.glob("*/.cursor-plugin/plugin.json")}
    stale = existing - expected.keys()
    changed = [path for path, content in expected.items()
               if not (root / path).is_file()
               or (root / path).read_text(encoding="utf-8") != content]
    if check:
        for path in sorted(set(changed) | stale):
            print(f"Out of sync: {path}", file=sys.stderr)
        return not (changed or stale)
    for path in changed:
        target = root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(expected[path], encoding="utf-8")
    for path in stale:
        (root / path).unlink()
        if not any((root / path).parent.iterdir()):
            (root / path).parent.rmdir()
    print(f"Synced {len(entries)} Cursor plugins ({len(changed)} updated, {len(stale)} removed).")
    return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Report drift without writing files")
    args = parser.parse_args()
    try:
        ok = sync(Path(__file__).resolve().parent.parent, check=args.check)
    except (ValueError, yaml.YAMLError, OSError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
    sys.exit(0 if ok else 1)
