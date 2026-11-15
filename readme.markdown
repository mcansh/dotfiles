# Dotfiles

my macbooks dotfiles

## Cursor skills marketplace

Each skill in `agents/.agents/skills/` is an individually installable Cursor
plugin. The root `.cursor-plugin/marketplace.json` indexes those directories;
each generated `.cursor-plugin/plugin.json` uses Cursor's root `SKILL.md`
discovery. Instructions, scripts, and references stay in their original folders.

Import `https://github.com/mcansh/dotfiles` from **Dashboard → Plugins & MCPs →
Team Marketplaces → Add Marketplace → Import from Repo**. Enable **Auto Refresh**
to pick up repository changes, then install skills from **Customize**. Team
marketplaces require a Cursor Teams or Enterprise plan and the Cursor GitHub App
for Auto Refresh. See [Cursor's plugin docs](https://cursor.com/docs/plugins).

For a local preview, copy a skill's whole directory (including its generated
`.cursor-plugin/` directory) into `~/.cursor/plugins/local/<skill-name>/`, reload
Cursor, and check **Customize**. Local plugin imports must be allowed by your
organization.

### Keeping the catalog in sync

Edit skills normally. The **Cursor marketplace** GitHub Action validates skill
frontmatter on pull requests and regenerates and commits metadata after changes
reach `main`. It also supports manual runs on `main`. Skill additions, metadata
edits, renames, and deletions are picked up automatically. The generated files
are owned by the sync script; edit `SKILL.md`, not the generated JSON.

To regenerate or check locally (Python 3.12+):

```bash
python3 -m pip install -r scripts/requirements-cursor-marketplace.txt
python3 scripts/sync-cursor-marketplace.py
python3 scripts/sync-cursor-marketplace.py --check
python3 -m unittest discover -s tests -p 'test_cursor_marketplace.py'
```

The sync job needs permission to push to `main`; branch rules must allow the
Actions bot to commit generated metadata. Cursor's Auto Refresh handles pulling
those commits into Cursor. This does not submit plugins to Cursor's public
marketplace or update skills from their upstream repositories.

install script based on nullbrx's
[dotfiles](https://github.com/nullbrx/dotfiles)

## Clone

```bash
git clone https://github.com/mcansh/dotfiles.git $HOME/.dotfiles
```

## Install Script

```bash
$ sh $HOME/.dotfiles/.macos
```

## GNU Stow Workflow

Prerequisite:

```bash
brew install stow
```

From the repo root:

```bash
# preview changes only
./scripts/stow.sh dry-run

# create/update symlinks
./scripts/stow.sh install

# recreate links after moving files around
./scripts/stow.sh restow

# first-time migration: pull existing files into repo + link
./scripts/stow.sh adopt

# remove managed symlinks
./scripts/stow.sh unstow

# verify managed files resolve back to dotfiles
./scripts/verify-stow.sh
```
