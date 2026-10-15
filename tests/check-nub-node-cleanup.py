#!/usr/bin/env python3
"""Exercise Node cache cleanup using an isolated, fake Nub executable."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
node = shutil.which('node')
assert node, 'Node is required'
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    nub = root / 'nub'
    nub.write_text('''#!/bin/sh
printf '%s\\n' "$*" >> "$TEST_LOG"
case "$*" in
  'node ls')
    printf '  22.1.0\\n  22.2.0\\n→ 24.0.0\\n  24.1.0\\n'
    if [ -f "$TEST_UPDATED" ]; then
      printf '  22.3.0\\n  24.2.0\\n'
    fi ;;
  'node install 22')
    [ "$TEST_FAIL" != 1 ] || exit 7
    touch "$TEST_UPDATED" ;;
esac
''')
    nub.chmod(0o755)
    log = root / 'log'
    env = {**os.environ, 'PATH': f'{root}:/usr/bin:/bin',
           'TEST_LOG': str(log), 'TEST_UPDATED': str(root / 'updated')}
    for fail in ['0', '1']:
        log.write_text('')
        (root / 'updated').unlink(missing_ok=True)
        result = subprocess.run([node, str(repo / 'nub-node-cleanup.mjs')],
                                env={**env, 'TEST_FAIL': fail}, capture_output=True, text=True)
        commands = log.read_text().splitlines()
        assert 'node install 22' in commands and 'node install 24' in commands
        if fail == '1':
            assert result.returncode != 0
            assert not any('uninstall' in command for command in commands)
        else:
            assert result.returncode == 0, result.stderr
            removed = {line for line in commands if 'uninstall' in line}
            assert removed == {'node uninstall 22.1.0', 'node uninstall 22.2.0',
                               'node uninstall 24.1.0'}, removed
print('Nub cleanup checks passed: upgrades, active version protection, failed downloads.')
