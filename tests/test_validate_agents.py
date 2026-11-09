import importlib.util
from pathlib import Path
import shutil
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from lib.skill_manifest import read_manifest

spec = importlib.util.spec_from_file_location('validate_agents', ROOT / 'scripts/validate-agents.py')
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class AgentValidationTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='agent-validation-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        agents = self.root / '.agents'
        shutil.copytree(ROOT / '.agents/knowledge', agents / 'knowledge')
        (agents / 'skills').mkdir(parents=True)
        for name in ('AGENTS.md', 'skills/INDEX.md'):
            shutil.copy2(ROOT / '.agents' / name, agents / name)
        for skill in validator.personal_skills(ROOT):
            shutil.copytree(skill, agents / 'skills' / skill.name, ignore=shutil.ignore_patterns('__pycache__'))
        shutil.copy2(ROOT / 'AGENTS.md', self.root / 'AGENTS.md')
        shutil.copy2(ROOT / 'CLAUDE.md', self.root / 'CLAUDE.md')

    def add_to_index(self, text):
        index = self.root / '.agents/knowledge/INDEX.md'
        index.write_text(index.read_text() + '\n' + text + '\n')

    def errors(self):
        return validator.validate(self.root)[0]

    def test_repository_contract_passes(self):
        self.assertEqual([], self.errors())

    def test_missing_target_and_fragment_are_rejected(self):
        self.add_to_index('[Missing](absent.md) [Section](git.md#missing)')
        errors = '\n'.join(self.errors())
        self.assertIn('missing link: absent.md', errors)
        self.assertIn('missing fragment: git.md#missing', errors)

    def test_existing_fragments_and_reference_links_are_followed(self):
        page = self.root / '.agents/knowledge/references.md'
        page.write_text('# Title\n\n## Same heading\n\n## Same heading\n\n[Local](#same-heading-1)\n')
        self.add_to_index('[New page][new]\n[new]: references.md#same-heading')
        self.assertEqual([], self.errors())

    def test_orphaned_supporting_reference_is_detected(self):
        path = self.root / '.agents/skills/create-cli/references/orphan.md'
        path.write_text('# Unreachable\n')
        self.assertTrue(any('orphan.md: unreachable' in e for e in self.errors()))

    def test_code_examples_are_not_treated_as_navigation(self):
        self.add_to_index('```markdown\n[Example](not-a-real-page.md)\n```\n`[Inline](also-missing.md)`')
        self.assertEqual([], self.errors())

    def test_undefined_reference_is_rejected(self):
        self.add_to_index('[Text][undefined]')
        self.assertTrue(any('undefined link reference' in e for e in self.errors()))

    def test_external_links_are_not_local_dependencies(self):
        self.add_to_index('[Web](https://example.com/missing#anything)')
        self.assertEqual([], self.errors())

    def test_absolute_and_escaping_links_are_rejected(self):
        self.add_to_index('[Absolute](/tmp) [Escape](../../../outside.md)')
        errors = self.errors()
        self.assertEqual(2, sum('must stay relative' in e for e in errors))

    def test_url_encoded_spaces_and_angle_brackets_resolve(self):
        page = self.root / '.agents/knowledge/space name.md'
        page.write_text('# Space Name\n')
        self.add_to_index('[A](space%20name.md#space-name) [B](<space name.md>)')
        self.assertEqual([], self.errors())

    def test_required_entry_cannot_disappear_silently(self):
        (self.root / '.agents/AGENTS.md').unlink()
        self.assertTrue(any('required entry point missing' in e for e in self.errors()))

    def test_claude_import_bridge_resolves_its_project_instructions(self):
        (self.root / 'CLAUDE.md').write_text('@missing.md\n')
        self.assertTrue(any('CLAUDE.md: missing link: missing.md' in e for e in self.errors()))

    def test_machine_specific_paths_and_oversized_entrypoints_are_rejected(self):
        path = self.root / '.agents/AGENTS.md'
        path.write_text(path.read_text() + '\n/home/example/source\n' + 'extra ' * 250)
        errors = '\n'.join(self.errors())
        self.assertIn('machine-specific home path', errors)
        self.assertIn('entry-point budget', errors)

    def manifest(self, frontmatter):
        directory = self.root / 'manifest-test'
        directory.mkdir(exist_ok=True)
        (directory / 'SKILL.md').write_text('---\n' + frontmatter + '\n---\n\nWorkflow.\n')
        return directory

    def test_quoted_names_and_folded_descriptions_are_valid_yaml(self):
        directory = self.manifest('name: "manifest-test"\ndescription: >\n  Make a useful\n  artifact.')
        self.assertEqual('Make a useful artifact.', read_manifest(directory)['description'].strip())

    def test_manifest_semantic_errors_are_rejected(self):
        cases = (
            'name: manifest-test',
            'name: mismatch\ndescription: Test',
            'name: manifest-test\nname: manifest-test\ndescription: Test',
            'name: manifest-test\ndescription: []',
            'name: manifest-test\ndescription: yes',
            'name: manifest-test\ndescription: Test\nmodel: sonnet',
            'name: manifest-test\ndescription: Test\nmetadata: {count: 1}',
            'name: manifest-test\ndescription: Test\nmetadata: {1: text}',
            'name: manifest-test\ndescription: [bad yaml',
            'name: manifest-test\ndescription: ' + 'x' * 1025,
        )
        for frontmatter in cases:
            with self.subTest(frontmatter=frontmatter):
                with self.assertRaises(ValueError):
                    read_manifest(self.manifest(frontmatter))

    def test_nested_skill_manifest_is_rejected(self):
        directory = self.manifest('name: manifest-test\ndescription: Test')
        (directory / 'nested').mkdir()
        (directory / 'nested/SKILL.md').write_text('nested')
        with self.assertRaisesRegex(ValueError, 'nested'):
            read_manifest(directory)


if __name__ == '__main__':
    unittest.main()
