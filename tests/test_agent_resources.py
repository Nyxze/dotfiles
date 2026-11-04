import contextlib
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
spec = importlib.util.spec_from_file_location('agent_resources', ROOT / 'scripts/agent-resources.py')
resources = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = resources
spec.loader.exec_module(resources)


def write_skill(root, name='sample', description='Run a sample workflow.', extra=''):
    directory = root / name
    directory.mkdir(parents=True, exist_ok=True)
    (directory / 'SKILL.md').write_text(
        f'---\nname: {name}\ndescription: {description}\n{extra}---\n\n# Workflow\n\nRun the task.\n')
    return directory


class AgentResourcesTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='agent-resources-')
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.repo = self.directory / 'repo with spaces'
        self.home = self.directory / 'user home'
        self.home.mkdir()
        knowledge = self.repo / 'prompts/knowledge'
        knowledge.mkdir(parents=True)
        (knowledge / 'AGENTS.md').write_text('# Instructions\n\nShared instructions.\n')
        self.skill = write_skill(self.repo / 'prompts/skills')
        for context in (
            patch.object(resources, 'ROOT', self.repo),
            patch.object(Path, 'home', return_value=self.home),
            patch.dict(os.environ, {name: '' for name in (
                'CODEX_HOME', 'CLAUDE_CONFIG_DIR', 'XDG_CONFIG_HOME', 'XDG_STATE_HOME')}),
        ):
            context.start()
            self.addCleanup(context.stop)

    def run_command(self, *args, expected=0):
        output = io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            try:
                result = resources.main(list(args))
            except SystemExit as error:
                result = error.code
        self.assertEqual(expected, result, output.getvalue())
        return output.getvalue()

    def test_install_is_idempotent_and_checks_all_providers(self):
        self.run_command('install')
        self.assertEqual((self.repo / 'prompts/knowledge/AGENTS.md'), (self.home / 'AGENTS.md').resolve())
        for _, directory in resources.destinations().values():
            if directory:
                self.assertEqual(self.skill, (directory / 'sample').resolve())
        self.assertIn('Installed 0 links', self.run_command('install'))
        self.run_command('check')

    def test_dry_run_writes_no_destinations_or_backups(self):
        self.run_command('install', '--dry-run', '--force')
        self.assertEqual([], list(self.home.iterdir()))

    def test_conflict_preflights_every_provider_before_writing(self):
        conflict = self.home / '.config/opencode/skills/sample'
        conflict.mkdir(parents=True)
        (conflict / 'work').write_text('keep this')
        os.utime(conflict, (1, 1))
        self.run_command('install', expected=1)
        self.assertFalse((self.home / 'AGENTS.md').exists())
        self.assertFalse((self.home / '.agents').exists())
        self.assertEqual('keep this', (conflict / 'work').read_text())

    def test_force_preserves_directory_file_and_broken_symlink(self):
        (self.home / 'AGENTS.md').write_text('old instructions')
        conflict = self.home / '.agents/skills/sample'
        conflict.mkdir(parents=True)
        (conflict / 'file').write_text('local content')
        broken = self.home / '.claude/CLAUDE.md'
        broken.parent.mkdir()
        broken.symlink_to('missing-target')
        self.run_command('install', '--force')
        backups = self.home / '.local/state/dotfiles/agent-backups'
        self.assertEqual(['old instructions'], [p.read_text() for p in backups.rglob('AGENTS.md')])
        self.assertEqual(['local content'], [p.read_text() for p in backups.rglob('file')])
        saved_link = next(backups.rglob('CLAUDE.md'))
        self.assertTrue(saved_link.is_symlink())
        self.assertEqual('missing-target', os.readlink(saved_link))
        self.run_command('check')

    def test_preserves_provider_owned_resources(self):
        owned = write_skill(self.home / '.claude/skills', 'vendor')
        native_agent = self.home / '.claude/agents/reviewer.md'
        native_agent.parent.mkdir()
        native_agent.write_text('native agent')
        extra = self.home / '.agents/skills/vendor-link'
        extra.parent.mkdir(parents=True)
        extra.symlink_to(self.directory / 'missing-vendor')
        self.run_command('install')
        self.assertTrue((owned / 'SKILL.md').is_file())
        self.assertTrue(extra.is_symlink())
        self.assertEqual('native agent', native_agent.read_text())

    def test_removes_only_owned_stale_links_including_relative_links(self):
        self.run_command('install')
        stale = self.home / '.agents/skills/retired'
        stale.symlink_to(os.path.relpath(self.repo / 'prompts/skills/retired', stale.parent))
        self.run_command('check', expected=1)
        self.run_command('install', '--dry-run')
        self.assertTrue(stale.is_symlink())
        self.run_command('install')
        self.assertFalse(stale.is_symlink())

    def test_honors_custom_provider_and_state_paths(self):
        overrides = {name: str(self.directory / name) for name in (
            'CODEX_HOME', 'CLAUDE_CONFIG_DIR', 'XDG_CONFIG_HOME', 'XDG_STATE_HOME')}
        with patch.dict(os.environ, overrides):
            self.run_command('install')
            self.assertTrue((Path(overrides['CODEX_HOME']) / 'AGENTS.md').is_symlink())
            self.assertTrue((Path(overrides['CLAUDE_CONFIG_DIR']) / 'skills/sample').is_symlink())
            self.assertTrue((Path(overrides['XDG_CONFIG_HOME']) / 'opencode/AGENTS.md').is_symlink())
            self.assertTrue((self.home / '.agents/skills/sample').is_symlink())
            self.assertFalse((self.home / '.codex').exists())
            (self.home / 'AGENTS.md').unlink()
            (self.home / 'AGENTS.md').write_text('preserve')
            self.run_command('install', '--force')
            self.assertEqual(['preserve'], [p.read_text() for p in Path(overrides['XDG_STATE_HOME']).rglob('AGENTS.md')])
            self.run_command('check')

    def test_instruction_only_and_skill_only_do_not_cross_scope(self):
        self.run_command('install', 'codex', '--only', 'skills')
        self.assertFalse((self.home / 'AGENTS.md').exists())
        self.assertFalse((self.home / '.claude').exists())
        self.run_command('install', 'claude-code', '--only', 'instructions')
        self.assertTrue((self.home / '.claude/CLAUDE.md').is_symlink())
        self.assertFalse((self.home / '.claude/skills').exists())

    def test_nonempty_codex_override_is_reported_without_deleting_it(self):
        override = self.home / '.codex/AGENTS.override.md'
        override.parent.mkdir()
        override.write_text('override')
        self.run_command('install', '--force', expected=1)
        self.assertFalse((self.home / 'AGENTS.md').exists())
        self.assertEqual('override', override.read_text())
        override.write_text('   \n')
        self.run_command('install')
        override.write_text('new override')
        self.assertIn('shadows', self.run_command('check', expected=1))

    def test_invalid_source_is_rejected_before_destination_changes(self):
        (self.skill / 'SKILL.md').write_text('---\nname: sample\n---\nBody\n')
        self.run_command('install', expected=1)
        self.assertEqual([], list(self.home.iterdir()))

    def test_parent_file_is_rejected_before_destination_changes(self):
        (self.home / '.claude').write_text('local file')
        self.run_command('install', '--force', expected=1)
        self.assertFalse((self.home / 'AGENTS.md').exists())

    def test_source_checkout_cannot_be_a_destination(self):
        with patch.dict(os.environ, {'CODEX_HOME': str(self.repo / 'prompts/knowledge')}):
            self.run_command('install', '--force', expected=1)
        self.assertTrue((self.repo / 'prompts/knowledge/AGENTS.md').is_file())
        self.assertFalse((self.home / 'AGENTS.md').exists())

    def test_overlapping_destinations_are_rejected_before_writing(self):
        with patch.dict(os.environ, {'CODEX_HOME': str(self.home / 'AGENTS.md/nested')}):
            self.run_command('install', expected=1)
        self.assertEqual([], list(self.home.iterdir()))

    def test_provider_directories_can_share_a_real_skill_directory(self):
        shared = self.home / 'shared-skills'
        shared.mkdir()
        for provider in ('.agents', '.claude', '.config/opencode'):
            directory = self.home / provider
            directory.mkdir(parents=True)
            (directory / 'skills').symlink_to(shared)
        self.run_command('install')
        self.run_command('check')
        self.assertEqual(self.skill, (shared / 'sample').resolve())

    def test_capture_requires_names_and_one_provider(self):
        for args in (('capture',), ('capture', 'codex'), ('capture', 'all', '--skill', 'sample'),
                     ('install', 'typo'), ('install', 'all', 'codex'), ('install', 'home', '--only', 'skills')):
            with self.subTest(args=args):
                self.run_command(*args, expected=2)
        self.assertEqual([], list(self.home.iterdir()))

    def test_capture_new_selected_skill_preserves_other_skills(self):
        directory = self.home / '.claude/skills'
        write_skill(directory, 'personal')
        write_skill(directory, 'vendor')
        self.run_command('capture', 'claude-code', '--skill', 'personal', '--dry-run')
        self.assertFalse((self.repo / 'prompts/skills/personal').exists())
        self.run_command('capture', 'claude-code', '--skill', 'personal')
        self.assertTrue((self.repo / 'prompts/skills/personal/SKILL.md').is_file())
        self.assertFalse((self.repo / 'prompts/skills/vendor').exists())
        self.assertEqual('Already matches: personal\n', self.run_command('capture', 'claude-code', '--skill', 'personal'))

    def test_capture_follows_top_level_skill_link(self):
        source = write_skill(self.directory / 'external', 'importable')
        provider = self.home / '.claude/skills'
        provider.mkdir(parents=True)
        (provider / 'importable').symlink_to(source)
        self.run_command('capture', 'claude-code', '--skill', 'importable')
        target = self.repo / 'prompts/skills/importable'
        self.assertFalse(target.is_symlink())
        self.assertEqual((source / 'SKILL.md').read_text(), (target / 'SKILL.md').read_text())

    def test_capture_installed_skill_is_a_noop(self):
        self.run_command('install')
        self.assertIn('Already shared', self.run_command('capture', 'codex', '--skill', 'sample'))

    def test_capture_preflights_missing_and_conflicting_names(self):
        directory = self.home / '.claude/skills'
        write_skill(directory, 'new-skill')
        write_skill(directory, 'sample', 'Different workflow.')
        before = (self.skill / 'SKILL.md').read_text()
        for failure in ('sample', 'missing', '../outside'):
            self.run_command('capture', 'claude-code', '--skill', 'new-skill', '--skill', failure, expected=1)
            self.assertFalse((self.repo / 'prompts/skills/new-skill').exists())
        self.assertEqual(before, (self.skill / 'SKILL.md').read_text())

    def test_capture_rejects_symlinked_resources(self):
        skill = write_skill(self.home / '.claude/skills', 'unsafe')
        (skill / 'outside').symlink_to(self.directory / 'private')
        self.run_command('capture', 'claude-code', '--skill', 'unsafe', expected=1)
        self.assertFalse((self.repo / 'prompts/skills/unsafe').exists())

    def test_legacy_wrappers_expose_help_and_invalid_usage(self):
        for path in ('scripts/install.sh', 'scripts/install-skills.sh', 'prompts/link-skills.sh',
                     'prompts/link-knowledge.sh', 'prompts/capture.sh'):
            with self.subTest(path=path):
                result = subprocess.run([str(ROOT / path), '--help'], text=True, capture_output=True)
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertIn('usage:', result.stdout.lower())
        result = subprocess.run([str(ROOT / 'scripts/install-skills.sh'), '--provider', 'invalid'], capture_output=True)
        self.assertEqual(2, result.returncode)


if __name__ == '__main__':
    unittest.main()
