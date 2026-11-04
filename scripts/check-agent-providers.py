#!/usr/bin/env python3
"""Probe native skill discovery without sending a prompt or making model calls."""

import argparse
import json
import os
from pathlib import Path
import select
import shutil
import subprocess
import sys
import tempfile
import time


SOURCE = Path(__file__).resolve().parents[1] / 'prompts'
EXPECTED = {p.name for p in (SOURCE / 'skills').iterdir() if (p / 'SKILL.md').is_file()}


def messages(process, timeout=35):
    deadline = time.monotonic() + timeout
    buffer = b''
    while time.monotonic() < deadline:
        remaining = max(0, deadline - time.monotonic())
        if not select.select([process.stdout], [], [], min(1, remaining))[0]:
            continue
        chunk = os.read(process.stdout.fileno(), 65536)
        if not chunk:
            raise RuntimeError('provider exited before returning discovery data')
        buffer += chunk
        while b'\n' in buffer:
            line, buffer = buffer.split(b'\n', 1)
            if line.strip():
                yield json.loads(line)
    raise TimeoutError('no discovery response before timeout')


def send(process, payload):
    process.stdin.write(json.dumps(payload).encode() + b'\n')
    process.stdin.flush()


def response_for(incoming, key, value):
    for message in incoming:
        if message.get(key) != value:
            continue
        if 'error' in message:
            raise RuntimeError(message['error'])
        return message
    raise RuntimeError('provider returned no matching response')


def check_names(names):
    if names != EXPECTED:
        raise ValueError(f"missing personal skills: {', '.join(sorted(EXPECTED - names))}")


def check_paths(skills, key):
    for skill in skills:
        expected = SOURCE / 'skills' / skill['name'] / 'SKILL.md'
        if Path(skill[key]).resolve() != expected:
            raise ValueError(f"{skill['name']}: discovered a different source at {skill[key]}")


def check_codex(process, incoming, directory):
    send(process, {'id': 1, 'method': 'initialize', 'params': {
        'clientInfo': {'name': 'dotfiles_probe', 'version': '1.0'},
    }})
    response_for(incoming, 'id', 1)
    send(process, {'method': 'initialized', 'params': {}})
    send(process, {'id': 2, 'method': 'skills/list', 'params': {
        'cwds': [str(directory)], 'forceReload': True,
    }})
    entries = response_for(incoming, 'id', 2)['result']['data']
    if any(entry.get('errors') for entry in entries):
        raise ValueError('Codex reported skill discovery errors')
    skills = [s for entry in entries for s in entry['skills'] if s['name'] in EXPECTED]
    check_names({s['name'] for s in skills})
    check_paths(skills, 'path')


def check_claude(process, incoming):
    send(process, {'type': 'control_request', 'request_id': 'probe', 'request': {
        'subtype': 'initialize', 'hooks': None,
    }})
    response = response_for(incoming, 'type', 'control_response')['response']
    if response.get('subtype') == 'error':
        raise RuntimeError(response.get('error'))
    commands = response.get('response', {}).get('commands', [])
    check_names({c['name'] for c in commands if c.get('name') in EXPECTED})


def probe(provider):
    with tempfile.TemporaryDirectory(prefix=provider + '-probe-') as temporary:
        directory = Path(temporary)
        environment = dict(os.environ)
        if provider == 'codex':
            environment['CODEX_HOME'] = temporary
            (directory / 'AGENTS.md').symlink_to(SOURCE / 'knowledge/AGENTS.md')
            command = ['codex', 'app-server', '--listen', 'stdio://']
        else:
            environment['CLAUDE_CONFIG_DIR'] = temporary
            environment['DISABLE_AUTOUPDATER'] = '1'
            (directory / 'CLAUDE.md').symlink_to(SOURCE / 'knowledge/AGENTS.md')
            (directory / 'skills').mkdir()
            for name in EXPECTED:
                (directory / 'skills' / name).symlink_to(SOURCE / 'skills' / name)
            command = [
                'claude', '-p', '--input-format', 'stream-json',
                '--output-format', 'stream-json', '--verbose',
                '--strict-mcp-config', '--mcp-config', '{"mcpServers":{}}',
                '--setting-sources', 'user', '--no-session-persistence',
            ]
        with tempfile.TemporaryFile() as errors:
            process = subprocess.Popen(
                command, cwd=temporary, env=environment, stdin=subprocess.PIPE,
                stdout=subprocess.PIPE, stderr=errors,
            )
            try:
                incoming = messages(process)
                if provider == 'codex':
                    check_codex(process, incoming, directory)
                else:
                    check_claude(process, incoming)
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                process.stdin.close()
                process.stdout.close()


def check_opencode():
    result = subprocess.run(
        ['opencode', '--pure', 'debug', 'skill'],
        capture_output=True, text=True, timeout=35,
    )
    if result.returncode:
        raise ValueError('OpenCode discovery failed; inspect opencode --pure debug skill')
    skills = [s for s in json.loads(result.stdout) if s.get('name') in EXPECTED]
    check_names({s['name'] for s in skills})
    check_paths(skills, 'location')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('providers', nargs='*', metavar='PROVIDER',
                        help='codex, claude-code, opencode (default: all three)')
    args = parser.parse_args()
    providers = list(dict.fromkeys(args.providers or ['codex', 'claude-code', 'opencode']))
    if any(name not in ('codex', 'claude-code', 'opencode') for name in providers):
        parser.error('choose codex, claude-code, or opencode')
    failed = False
    for provider in providers:
        binary = 'claude' if provider == 'claude-code' else provider
        try:
            if not shutil.which(binary):
                raise ValueError(f'{binary} is not installed')
            version = subprocess.run(
                [binary, '--version'], capture_output=True, text=True, check=True, timeout=5,
            ).stdout.strip()
            if provider == 'opencode':
                check_opencode()
            else:
                probe(binary)
            print(f'{provider} ({version}): discovered all {len(EXPECTED)} personal skills')
        except (OSError, ValueError, RuntimeError, TimeoutError, subprocess.SubprocessError, KeyError) as error:
            print(f'{provider}: {error}', file=sys.stderr)
            failed = True
    return int(failed)


if __name__ == '__main__':
    sys.exit(main())
