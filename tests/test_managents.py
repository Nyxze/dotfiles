import contextlib
import dataclasses
import importlib.machinery
import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('managents', str(ROOT / 'scripts/managents'))
spec = importlib.util.spec_from_loader('managents', loader)
setup = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = setup
spec.loader.exec_module(setup)


def write_skill(root, name, body='Run the task.'):
    directory = root / name
    directory.mkdir(parents=True, exist_ok=True)
    (directory / 'SKILL.md').write_text(f'---\nname: {name}\ndescription: Run {name}.\n---\n\n{body}\n')
    return directory


class SetupAgentsTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='managents-')
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.repo = self.directory / 'repo with spaces'
        self.home = self.directory / 'user home'
        self.repo.mkdir()
        self.home.mkdir()
        for context in (
            patch.object(setup, 'ROOT', self.repo),
            patch.object(Path, 'home', return_value=self.home),
            patch.dict(os.environ, {name: '' for name in (
                'CODEX_HOME', 'CLAUDE_CONFIG_DIR', 'XDG_CONFIG_HOME', 'XDG_STATE_HOME')}),
        ):
            context.start()
            self.addCleanup(context.stop)
        self.source = self.repo / '.agents'
        self.claude, self.codex, self.opencode = setup.providers()

    def run_command(self, *args, expected=0):
        if not args or args[0].startswith('--'):
            args = ('setup', *args)
        output = io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            result = setup.main(list(args))
        self.assertEqual(expected, result, output.getvalue())
        return output.getvalue()

    def test_creates_the_source_and_links_every_provider(self):
        self.run_command()
        self.assertTrue((self.source / 'AGENTS.md').is_file())
        self.assertTrue((self.source / 'skills').is_dir())
        self.assertEqual(self.source, (self.home / '.agents').resolve())
        for provider in (self.claude, self.codex, self.opencode):
            self.assertEqual(self.source / 'AGENTS.md', provider.entry.resolve())
            self.assertEqual(self.home / '.agents/AGENTS.md', Path(os.readlink(provider.entry)))

    def test_second_run_changes_nothing_and_check_passes(self):
        write_skill(self.source / 'skills', 'sample')
        self.run_command()
        self.assertIn('Already set up', self.run_command())
        self.assertIn('Everything is linked', self.run_command('check'))

    def test_check_fails_until_setup_ran(self):
        self.run_command('check', expected=1)
        self.assertFalse((self.home / '.agents').exists())

    def test_dry_run_writes_nothing(self):
        existing = self.home / '.agents/skills'
        write_skill(existing, 'sample')
        self.run_command('--dry-run', '--force')
        self.assertEqual([], list(self.repo.iterdir()))
        self.assertTrue(existing.is_dir() and not existing.is_symlink())

    def test_instructions_are_seeded_from_a_live_entry_file(self):
        self.claude.entry.parent.mkdir(parents=True)
        self.claude.entry.write_text('# My rules\n')
        self.run_command()
        self.assertEqual('# My rules\n', (self.source / 'AGENTS.md').read_text())
        self.assertEqual(self.source / 'AGENTS.md', self.claude.entry.resolve())

    def test_a_real_agents_directory_is_adopted_and_backed_up(self):
        existing = self.home / '.agents'
        write_skill(existing / 'skills', 'installed-by-cli', 'Third party.')
        (existing / '.skill-lock.json').write_text('{"version": 3}\n')
        self.run_command()
        self.assertTrue((self.source / 'skills/installed-by-cli/SKILL.md').is_file())
        self.assertEqual('{"version": 3}\n', (self.source / '.skill-lock.json').read_text())
        self.assertEqual(self.source, existing.resolve())
        self.assertEqual(self.source / 'skills/installed-by-cli', (self.claude.skills / 'installed-by-cli').resolve())
        self.assertEqual(self.home / '.agents/skills/installed-by-cli', Path(os.readlink(self.claude.skills / 'installed-by-cli')))
        backups = list((self.home / '.local/state/dotfiles/agent-backups').glob('setup-*/0/.agents/skills/installed-by-cli'))
        self.assertEqual(1, len(backups))

    def test_adoption_merges_into_a_source_that_already_has_skills(self):
        write_skill(self.source / 'skills', 'managents')
        write_skill(self.home / '.agents/skills', 'installed-by-cli')
        self.run_command()
        self.assertTrue((self.source / 'skills/managents/SKILL.md').is_file())
        self.assertTrue((self.source / 'skills/installed-by-cli/SKILL.md').is_file())
        self.assertEqual({'managents', 'installed-by-cli'}, {p.name for p in (self.claude.skills).iterdir()})

    def test_adoption_refuses_a_skill_that_differs_from_the_source(self):
        write_skill(self.source / 'skills', 'sample', 'Source version.')
        write_skill(self.home / '.agents/skills', 'sample', 'Other version.')
        self.assertIn('differs', self.run_command(expected=1))
        self.assertTrue((self.home / '.agents').is_dir() and not (self.home / '.agents').is_symlink())

    def test_a_provider_copy_identical_to_the_source_becomes_a_link(self):
        write_skill(self.source / 'skills', 'sample')
        write_skill(self.claude.skills, 'sample')
        self.run_command()
        self.assertTrue((self.claude.skills / 'sample').is_symlink())

    def test_a_provider_skill_of_its_own_is_left_alone(self):
        write_skill(self.source / 'skills', 'shared')
        own = write_skill(self.claude.skills, 'claude-only')
        self.run_command()
        self.assertFalse(own.is_symlink())
        self.assertTrue((self.claude.skills / 'shared').is_symlink())
        self.assertFalse((self.codex.entry.parent / 'skills').exists())

    def test_a_conflicting_file_stops_everything_before_any_write(self):
        write_skill(self.source / 'skills', 'sample')
        for entry, rules in ((self.claude.entry, 'claude rules\n'), (self.opencode.entry, 'other rules\n')):
            entry.parent.mkdir(parents=True)
            entry.write_text(rules)
        self.assertIn('--force', self.run_command(expected=1))
        self.assertFalse((self.home / '.agents').exists())
        self.assertFalse(self.claude.entry.is_symlink())

    def test_force_backs_up_the_conflicting_file(self):
        self.opencode.entry.parent.mkdir(parents=True)
        self.opencode.entry.write_text('other rules\n')
        self.run_command('--force')
        self.assertTrue(self.opencode.entry.is_symlink())
        saved = list((self.home / '.local/state/dotfiles/agent-backups').glob('setup-*/*/AGENTS.md'))
        self.assertEqual(['other rules\n'], [path.read_text() for path in saved])

    def test_docs_link_to_the_knowledge_base_when_it_exists(self):
        self.run_command()
        self.assertFalse((self.source / 'docs').exists())
        knowledge = self.home / 'work/docs'
        knowledge.mkdir(parents=True)
        (knowledge / 'index.md').write_text('# Docs\n')
        self.run_command()
        self.assertEqual(knowledge, (self.source / 'docs').resolve())
        self.assertEqual('# Docs\n', (self.home / '.agents/docs/index.md').read_text())
        self.assertIn('Already set up', self.run_command())

    def test_a_real_docs_directory_in_the_source_is_not_replaced(self):
        (self.home / 'work/docs').mkdir(parents=True)
        (self.source / 'docs').mkdir(parents=True)
        (self.source / 'docs/notes.md').write_text('mine\n')
        self.assertIn('docs', self.run_command(expected=1))

    def adopt_setup(self):
        self.run_command()  # ~/.agents must be linked first
        self.assertTrue((self.home / '.agents').is_symlink())

    def test_adopt_promotes_a_provider_skill_and_links_every_provider(self):
        self.adopt_setup()
        write_skill(self.claude.skills, 'gh')
        write_skill(self.opencode.skills, 'gh')
        self.run_command('skills', 'promote', 'gh', 'global')
        self.assertTrue((self.source / 'skills/gh/SKILL.md').is_file())
        for provider in (self.claude, self.opencode):
            link = provider.skills / 'gh'
            self.assertEqual(self.home / '.agents/skills/gh', Path(os.readlink(link)))
        saved = list((self.home / '.local/state/dotfiles/agent-backups').glob('setup-*/*/gh/SKILL.md'))
        self.assertGreaterEqual(len(saved), 1)
        self.run_command('check')

    def test_adopt_links_a_provider_that_has_no_copy(self):
        self.adopt_setup()
        write_skill(self.claude.skills, 'gh')
        self.run_command('skills', 'promote', 'gh', 'global')
        self.assertTrue((self.opencode.skills / 'gh').is_symlink())

    def test_adopt_needs_setup_first(self):
        write_skill(self.claude.skills, 'gh')
        self.assertIn('run setup first', self.run_command('skills', 'promote', 'gh', 'global', expected=1))
        self.assertTrue((self.claude.skills / 'gh').is_dir() and not (self.claude.skills / 'gh').is_symlink())

    def test_adopt_refuses_copies_that_differ_unless_one_is_chosen(self):
        self.adopt_setup()
        write_skill(self.claude.skills, 'gh', 'claude version')
        write_skill(self.opencode.skills, 'gh', 'opencode version')
        self.assertIn('--from', self.run_command('skills', 'promote', 'gh', 'global', expected=1))
        self.assertFalse((self.source / 'skills/gh').exists())
        self.run_command('skills', 'promote', 'gh', 'global', '--from', 'claude-code', '--force')
        self.assertIn('claude version', (self.source / 'skills/gh/SKILL.md').read_text())
        self.assertTrue((self.opencode.skills / 'gh').is_symlink())

    def test_adopt_refuses_an_unknown_skill_and_a_bad_name(self):
        self.adopt_setup()
        self.assertIn('no skill folder', self.run_command('skills', 'promote', 'nothing', 'global', expected=1))
        self.assertIn('not a skill name', self.run_command('skills', 'promote', '../x', 'global', expected=1))

    def test_adopt_dry_run_writes_nothing(self):
        self.adopt_setup()
        write_skill(self.claude.skills, 'gh')
        self.run_command('skills', 'promote', 'gh', 'global', '--dry-run')
        self.assertFalse((self.source / 'skills/gh').exists())
        self.assertFalse((self.claude.skills / 'gh').is_symlink())

    def test_status_reports_shared_and_provider_owned_skills_as_json(self):
        write_skill(self.source / 'skills', 'shared')
        write_skill(self.claude.skills, 'claude-only')
        self.run_command()
        report = json.loads(self.run_command('status', '--json'))
        self.assertEqual('linked', report['home_link'])
        self.assertEqual(['shared'], report['shared_skills'])
        claude = report['providers']['claude-code']
        self.assertEqual({'shared': 'linked'}, claude['skills'])
        self.assertEqual(['claude-only'], claude['own_skills'])
        self.assertEqual('native', report['providers']['codex']['mode'])
        self.assertIn('own skills: claude-only', self.run_command('status'))

    def test_status_before_setup_shows_what_is_missing(self):
        report = json.loads(self.run_command('status', '--json'))
        self.assertEqual('missing', report['home_link'])
        self.assertEqual('missing', report['providers']['claude-code']['entry'])

    def test_promote_only_accepts_the_global_scope(self):
        for args in (['skills', 'promote', 'gh', 'claude-code'], ['skills', 'promote', 'gh'], ['skills'], ['status', 'gh']):
            with self.assertRaises(SystemExit):
                with contextlib.redirect_stderr(io.StringIO()):
                    setup.main(args)

    def test_skills_ls_shows_the_scope_of_every_skill(self):
        write_skill(self.source / 'skills', 'shared')
        write_skill(self.claude.skills, 'claude-only')
        self.run_command()
        rows = {row['name']: row for row in json.loads(self.run_command('skills', 'ls', '--json'))}
        self.assertEqual('global', rows['shared']['scope'])
        self.assertEqual('linked', rows['shared']['providers']['claude-code'])
        self.assertEqual('native', rows['shared']['providers']['codex'])
        self.assertEqual({'name': 'claude-only', 'scope': 'claude-code', 'providers': {'claude-code': 'own'}},
                         rows['claude-only'])
        text = self.run_command('skills', 'ls')
        self.assertRegex(text, r'claude-only\s+claude-code\s+claude-code=own')

    def test_setup_links_the_command_into_local_bin(self):
        script = self.repo / 'scripts/managents'
        script.parent.mkdir()
        script.write_text('#!/usr/bin/env python3\n')
        self.run_command()
        self.assertEqual(script, (self.home / '.local/bin/managents').resolve())
        self.run_command('check')

    def test_a_stale_link_into_the_source_is_removed_but_other_links_stay(self):
        write_skill(self.source / 'skills', 'kept')
        self.run_command()
        (self.claude.skills / 'gone').symlink_to(self.home / '.agents/skills/gone')
        elsewhere = self.directory / 'elsewhere'
        elsewhere.mkdir()
        (self.claude.skills / 'foreign').symlink_to(elsewhere)
        self.run_command()
        self.assertFalse((self.claude.skills / 'gone').is_symlink())
        self.assertTrue((self.claude.skills / 'foreign').is_symlink())

    def with_directory_mode(self):
        modes = [dataclasses.replace(p, mode=setup.DIRECTORY) if p.name == 'opencode' else p for p in setup.providers()]
        context = patch.object(setup, 'providers', return_value=modes)
        context.start()
        self.addCleanup(context.stop)

    def test_directory_mode_links_the_whole_skills_directory(self):
        self.with_directory_mode()
        write_skill(self.source / 'skills', 'sample')
        self.run_command()
        self.assertEqual(self.home / '.agents/skills', Path(os.readlink(self.opencode.skills)))
        self.run_command('check')

    def test_directory_mode_refuses_a_provider_that_has_skills_of_its_own(self):
        self.with_directory_mode()
        write_skill(self.source / 'skills', 'shared')
        write_skill(self.opencode.skills, 'own')
        self.assertIn('own', self.run_command(expected=1))
        self.assertFalse(self.opencode.skills.is_symlink())

    def test_directory_mode_replaces_an_empty_or_identical_directory(self):
        self.with_directory_mode()
        write_skill(self.source / 'skills', 'shared')
        write_skill(self.opencode.skills, 'shared')
        self.run_command()
        self.assertTrue(self.opencode.skills.is_symlink())


if __name__ == '__main__':
    unittest.main()
