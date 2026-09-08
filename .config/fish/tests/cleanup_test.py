"""Run with python3 ~/.config/fish/tests/cleanup_test.py. No live services mutate."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

CONFIG = Path(__file__).resolve().parent.parent
FISH = shutil.which('fish')


class CleanupTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='fish-cleanup-test-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        mock = self.bin / 'mock'
        shutil.copyfile(CONFIG / 'tests/cleanup_mock.py', mock)
        mock.chmod(0o700)
        for name in ['ssh-add', 'ssh-agent', 'tmux', 'brew', 'moshi-hook',
                     'pgrep', 'claude', 'codex']:
            (self.bin / name).symlink_to(mock)
        self.state = self.root / 'state.json'
        self.calls = self.state.with_suffix('.calls')
        self.calls.touch()
        self.cache = self.root / 'cache.tar.gz'
        self.archive = self.root / 'archive.tar.gz'
        self.archive.write_bytes(b'archive')
        self.set_state(cache=str(self.cache), sessions={'work': {'id': '$1', 'group': ''}})
        self.env = dict(os.environ, PATH=str(self.bin) + ':' + os.environ['PATH'],
                        FISH_CLEANUP_TEST_STATE=str(self.state), FISH_TEST_CONFIG=str(CONFIG),
                        SSH_AUTH_SOCK='ready-inherited', SSH_ENV=str(self.root / 'agent-env'),
                        TMUX='test-server', TMUX_ATTENTION_OWNER='outer-owner',
                        TERM='xterm-256color')
        self.env.pop('SSH_AGENT_PID', None)
        self.env.pop('SSH_CONNECTION', None)

    def set_state(self, **values):
        state = json.loads(self.state.read_text()) if self.state.exists() else {}
        state.update(values)
        self.state.write_text(json.dumps(state))

    def run_fish(self, code, interactive=False):
        prefix = 'set -p fish_function_path "$FISH_TEST_CONFIG/functions"; '
        result = subprocess.run([FISH, '--no-config', *(['-i'] if interactive else []),
                                 '-c', prefix + code], env=self.env, text=True,
                                capture_output=True, timeout=15)
        return result

    def commands(self, tool):
        return [call['args'] for line in self.calls.read_text().splitlines()
                if (call := json.loads(line))['tool'] == tool]

    def test_inherited_agent_without_pid_and_empty_agent(self):
        for code in (0, 1):
            with self.subTest(ssh_add_status=code):
                self.set_state(agent_ready_status=code)
                result = self.run_fish('_local_ssh_agent')
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse(self.commands('ssh-agent'))
                self.assertFalse(Path(self.env['SSH_ENV']).exists())

    def test_noninteractive_startup_does_not_probe_or_start_agent(self):
        self.env['SSH_AUTH_SOCK'] = 'stale'
        result = self.run_fish('source "$FISH_TEST_CONFIG/conf.d/ssh-agent.fish"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.commands('ssh-add'))
        self.assertFalse(self.commands('ssh-agent'))

    def test_reuse_saved_agent(self):
        self.env['SSH_AUTH_SOCK'] = 'stale'
        Path(self.env['SSH_ENV']).write_text('set -gx SSH_AUTH_SOCK ready-saved\n')
        result = self.run_fish('_local_ssh_agent; and echo $SSH_AUTH_SOCK')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'ready-saved')
        self.assertFalse(self.commands('ssh-agent'))

    def test_new_agent_saved_privately_and_reused(self):
        self.env['SSH_AUTH_SOCK'] = 'stale'
        result = self.run_fish('_local_ssh_agent')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(Path(self.env['SSH_ENV']).stat().st_mode & 0o777, 0o600)
        result = self.run_fish('_local_ssh_agent')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.commands('ssh-agent')), 1)

    def test_failed_agent_start_propagates_and_removes_tempfile(self):
        self.env['SSH_AUTH_SOCK'] = 'stale'
        self.set_state(agent_start_status=7)
        result = self.run_fish('_local_ssh_agent')
        self.assertEqual(result.returncode, 7)
        self.assertFalse(list(self.root.glob('agent-env*')))

    def test_zoxide_single_hook_and_all_navigation_shortcuts(self):
        self.env['_ZO_DATA_DIR'] = str(self.root / 'zoxide')
        self.env['FISH_TEST_TARGET'] = str(self.root)
        result = self.run_fish('_local_zoxide_init; '
                               'functions --handlers; '
                               'functions -q cd cdi j ji z zi; or exit 5; '
                               'cd /private/tmp; and j "$FISH_TEST_TARGET"; and z /private/tmp; '
                               'and cd "$FISH_TEST_TARGET"; or exit 6; pwd', interactive=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        hooks = [line for line in result.stdout.splitlines() if line.startswith('PWD ')]
        self.assertEqual(hooks, ['PWD __zoxide_hook'])
        self.assertEqual(Path(result.stdout.splitlines()[-1]).resolve(), self.root.resolve())

    def test_cached_archive_skips_self_copy(self):
        self.cache.write_bytes(b'archive')
        result = self.run_fish('moshi-update --skip-update')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(['upgrade', 'rjyo/moshi/moshi-hook'], self.commands('brew'))
        self.assertIn('service is started', result.stdout)

    def test_downloaded_archive_seeds_cache(self):
        self.env['FISH_TEST_ARCHIVE'] = str(self.archive)
        result = self.run_fish('moshi-update --skip-update --archive "$FISH_TEST_ARCHIVE"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.cache.read_bytes(), b'archive')

    def test_invalid_archive_never_upgrades(self):
        self.archive.write_bytes(b'invalid')
        self.env['FISH_TEST_ARCHIVE'] = str(self.archive)
        result = self.run_fish('moshi-update --skip-update --archive "$FISH_TEST_ARCHIVE"')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(c[0] == 'upgrade' for c in self.commands('brew')))

    def test_phoneview_reuses_mirror(self):
        result = self.run_fish('phoneview work; and phoneview work')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(sum(c[0] == 'new-session' for c in self.commands('tmux')), 1)
        self.assertFalse(any(c[0] == 'kill-session' for c in self.commands('tmux')))

    def test_phoneview_preserves_unrelated_mirror(self):
        self.set_state(sessions={'work': {'id': '$1', 'group': 'work'},
                                 'phone-work': {'id': '$2', 'group': 'other'}})
        result = self.run_fish('phoneview work')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('different session group', result.stderr)
        self.assertFalse(any(c[0] in ('new-session', 'kill-session') for c in self.commands('tmux')))

    def test_phoneview_creation_failure_single_and_all(self):
        self.set_state(create_status=7)
        for arg in ('work', 'all'):
            result = self.run_fish('phoneview ' + arg)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn('mirrors session', result.stdout)
            self.assertNotIn(' -> ', result.stdout)

    def test_phoneview_clean_failure(self):
        self.set_state(kill_status=7, sessions={'phone-work': {'id': '$2', 'group': 'work'}})
        result = self.run_fish('phoneview clean')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('removed 0', result.stdout)

    def test_fast_moshi_status_and_stopped_state(self):
        for code, label in ((0, 'ON'), (1, 'OFF')):
            self.set_state(pgrep_status=code)
            result = self.run_fish('moshi-notify status')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(label, result.stdout)
            self.assertFalse(self.commands('brew'))

    def test_failed_daemon_inspection_is_unknown_and_toggle_does_nothing(self):
        self.set_state(pgrep_status=2)
        result = self.run_fish('moshi-notify status')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('UNKNOWN', result.stdout)
        result = self.run_fish('moshi-notify toggle')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.commands('brew'))

    def test_failed_pairing_inspection_preserves_cache(self):
        self.set_state(moshi_status=7)
        result = self.run_fish('moshi-notify status')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('unknown', result.stdout)
        self.assertFalse(any(c[:3] == ['set', '-g', '@moshi_paired'] for c in self.commands('tmux')))

    def test_moshi_doctor_invokes_service_registration(self):
        result = self.run_fish('moshi-notify doctor')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(['services', 'list'], self.commands('brew'))

    def test_agent_wrappers_preserve_arguments_owner_exit_and_manual_names(self):
        for agent in ('claude', 'codex'):
            for rename in ('on', 'off'):
                with self.subTest(agent=agent, automatic_rename=rename):
                    self.calls.write_text('')
                    self.set_state(automatic_rename=rename)
                    code = ('function tmux_attention_claim; echo fixture-owner; end; '
                            'function tmux_attention_disown; echo disowned; end; '
                            f'{agent} "two words" --flag; set -l result $status; '
                            'printf "result=%s owner=%s\\n" $result $TMUX_ATTENTION_OWNER')
                    result = self.run_fish(code)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    payload = json.loads(result.stdout.splitlines()[0])
                    self.assertEqual(payload, {'args': ['two words', '--flag'], 'owner': 'fixture-owner'})
                    self.assertIn('result=23 owner=outer-owner', result.stdout)
                    self.assertIn('disowned', result.stdout)
                    tmux = self.commands('tmux')
                    if rename == 'on':
                        self.assertIn(['set-window-option', 'automatic-rename', 'on'], tmux)
                    else:
                        self.assertFalse(any(c[0] in ('rename-window', 'set-window-option') for c in tmux))


if __name__ == '__main__':
    unittest.main()
