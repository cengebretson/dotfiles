#!/usr/bin/env python3
"""Command doubles used only by cleanup_test.py in a temporary PATH."""
import hashlib
import json
import os
from pathlib import Path
import sys

tool = Path(sys.argv[0]).name
args = sys.argv[1:]
state_path = Path(os.environ['FISH_CLEANUP_TEST_STATE'])
state = json.loads(state_path.read_text())
with open(state_path.with_suffix('.calls'), 'a') as calls:
    calls.write(json.dumps({'tool': tool, 'args': args}) + '\n')


def save():
    state_path.write_text(json.dumps(state))


if tool == 'ssh-add':
    socket = os.environ.get('SSH_AUTH_SOCK', '')
    sys.exit(state.get('agent_ready_status', 0) if socket.startswith('ready-') else 2)
elif tool == 'ssh-agent':
    if state.get('agent_start_status', 0):
        sys.exit(state['agent_start_status'])
    print('setenv SSH_AUTH_SOCK ready-started;')
    print('setenv SSH_AGENT_PID 4242;')
    print('echo Agent pid 4242;')
elif tool == 'pgrep':
    sys.exit(state.get('pgrep_status', 0))
elif tool == 'moshi-hook':
    if state.get('moshi_status', 0):
        sys.exit(state['moshi_status'])
    print('status: paired\ndisplay name: Test phone\n  codex ok')
elif tool in ('claude', 'codex'):
    print(json.dumps({'args': args, 'owner': os.environ.get('TMUX_ATTENTION_OWNER')}))
    sys.exit(23)
elif tool == 'brew':
    if args[0] == 'info':
        print(json.dumps({'formulae': [{'versions': {'stable': '2'},
              'installed': [{'version': '2' if state.get('upgraded') else '1'}],
              'urls': {'stable': {'url': 'https://example.invalid/archive.tar.gz',
                      'checksum': hashlib.sha256(b'archive').hexdigest()}}}]}))
    elif args[0] == '--cache':
        print(state['cache'])
    elif args[0] == 'upgrade':
        state['upgraded'] = True
        save()
    elif args[:2] == ['services', 'list']:
        if state.get('brew_services_status', 0):
            sys.exit(state['brew_services_status'])
        if '--json' in args:
            print('[{"name":"moshi-hook","status":"started"}]')
        else:
            print('Name Status\nmoshi-hook started')
    elif args[:2] != ['services', 'restart']:
        raise SystemExit('Unexpected brew command: ' + repr(args))
elif tool == 'tmux':
    sessions = state.setdefault('sessions', {})
    if args[0] == 'show-window-options':
        print(state.get('automatic_rename', 'on'))
    elif args[0] in ('rename-window', 'set-window-option', 'set', 'refresh-client'):
        pass
    elif args[0] == 'list-sessions':
        print('\n'.join(sessions))
    elif args[0] == 'has-session':
        name = args[args.index('-t') + 1].removeprefix('=')
        sys.exit(0 if name in sessions else 1)
    elif args[0] == 'display-message':
        if '-t' not in args:
            print('work')
        else:
            name = args[args.index('-t') + 1].removeprefix('=').removesuffix(':')
            if name not in sessions:
                sys.exit(1)
            field = 'group' if args[-1] == '#{session_group}' else 'id'
            print(sessions[name][field])
    elif args[0] == 'new-session':
        if state.get('create_status', 0):
            sys.exit(state['create_status'])
        name = args[args.index('-s') + 1]
        target = args[args.index('-t') + 1]
        source = next(s for s in sessions.values() if s['id'] == target)
        source['group'] = source['group'] or 'test-group'
        sessions[name] = {'id': f'${len(sessions) + 1}', 'group': source['group']}
        save()
    elif args[0] == 'kill-session':
        if state.get('kill_status', 0):
            sys.exit(state['kill_status'])
        name = args[args.index('-t') + 1].removeprefix('=')
        sessions.pop(name)
        save()
    else:
        raise SystemExit('Unexpected tmux command: ' + repr(args))
else:
    raise SystemExit('Unknown mock command: ' + tool)
