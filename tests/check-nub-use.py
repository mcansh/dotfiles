#!/usr/bin/env python3
"""Check Node switching without changing the real home pin or downloading Node."""
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[1]
function = repo / 'config/.config/fish/functions/nub-use.fish'
fish = shutil.which('fish')
assert fish, 'Fish is required'

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    pin = root / '.node-version'
    log = root / 'log'
    nub = root / 'nub'
    nub.write_text('''#!/bin/sh
printf '%s\\n' "$@" > "$HOME/log"
exit "${TEST_EXIT:-0}"
''')
    nub.chmod(0o755)
    node = root / 'node'
    node.write_text('''#!/bin/sh
printf '%s\\n' "$@" > "$HOME/node-log"
exit "${TEST_EXIT:-0}"
''')
    node.chmod(0o755)
    project = root / 'project'
    project.mkdir()
    (project / '.node-version').write_text('22\n')
    env = {**os.environ, 'HOME': str(root), 'PATH': f'{root}:/usr/bin:/bin'}

    def run(*args, exit_code='0'):
        return subprocess.run(
            [fish, '--no-config', '-c', 'source "$argv[1]"; nub-use $argv[2..-1]',
             str(function), *args], cwd=project,
            env={**env, 'TEST_EXIT': exit_code}, capture_output=True, text=True)

    for version in ['24', '22.23.3', 'lts', 'latest']:
        result = run(version)
        assert result.returncode == 0, result.stderr
        assert pin.read_text() == version + '\n'
        assert log.read_text().splitlines() == ['node', 'install', version]
        assert (project / '.node-version').read_text() == '22\n'

    result = run('invalid-version', exit_code='7')
    assert result.returncode == 7
    assert pin.read_text() == 'latest\n'

    log.unlink()
    result = run('purge')
    assert result.returncode == 0, result.stderr
    assert (root / 'node-log').read_text().splitlines() == [str(root / '.dotfiles/nub-node-cleanup.mjs')]
    assert not log.exists()
    assert pin.read_text() == 'latest\n'
    assert (project / '.node-version').read_text() == '22\n'

    result = run('purge', exit_code='7')
    assert result.returncode == 7
    assert pin.read_text() == 'latest\n'
    assert (project / '.node-version').read_text() == '22\n'

    for args in [[], [''], ['--help'], ['22', '24'], ['purge', '24']]:
        result = run(*args)
        assert result.returncode != 0
        assert 'Usage: nub-use' in result.stderr
        assert pin.read_text() == 'latest\n'
        assert not log.exists()

print('Nub switching and purge dispatch checks passed.')
