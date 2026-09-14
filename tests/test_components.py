import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ComponentInstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root/'repo'
        self.repo.mkdir()
        for directory in ['commands', 'skills', 'shared']:
            shutil.copytree(ROOT/directory, self.repo/directory, ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
        shutil.copy2(ROOT/'install.sh', self.repo/'install.sh')
        self.home = self.root/'home'
        self.home.mkdir()
        self.git = shutil.which('git')
        self.manifest = json.loads((self.repo/'shared/components.json').read_text())
        routes = {}
        for c in self.manifest['components']:
            source = self.root/c['id']
            source.mkdir()
            subprocess.run([self.git, 'init', '-q', str(source)], check=True)
            (source/'LICENSE').write_text('Fixture license')
            (source/'SKILL.md').write_text('Fixture source for '+c['id'])
            (source/'install.sh').write_text('touch "$HOME/UNEXPECTED_INSTALL"\n')
            subprocess.run([self.git, '-C', str(source), 'add', '.'], check=True)
            subprocess.run([self.git, '-C', str(source), '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'fixture'], check=True)
            c['sha'] = subprocess.check_output([self.git, '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
            routes[c['url']] = str(source)
        (self.repo/'shared/components.json').write_text(json.dumps(self.manifest))
        bindir = self.root/'bin'
        bindir.mkdir()
        wrapper = bindir/'git'
        wrapper.write_text('#!/usr/bin/env python3\nimport os,sys\na=sys.argv[1:]\nr='+repr(routes)+'\nif "remote" in a and "add" in a and a[-1] in r: a[-1]=r[a[-1]]\nos.execv('+repr(self.git)+', ['+repr(self.git)+']+a)\n')
        wrapper.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), CODEX_HOME=str(self.home/'codex'), GEMINI_HOME=str(self.home/'gemini'), PATH=str(bindir)+os.pathsep+os.environ['PATH'])

    def install(self, *args):
        return subprocess.run(['bash', str(self.repo/'install.sh'), *args], env=self.env, text=True, capture_output=True)

    def test_opt_in_cache_exact_revisions_and_backup_without_upstream_execution(self):
        proc = self.install('--codex-only', '--with-components')
        self.assertEqual(proc.returncode, 0, proc.stdout+proc.stderr)
        cache = self.home/'.under-claw/components'
        self.assertFalse((self.home/'UNEXPECTED_INSTALL').exists())
        self.assertFalse((self.home/'.claude').exists())
        for c in self.manifest['components']:
            actual = subprocess.check_output([self.git, '-C', str(cache/c['id']), 'rev-parse', 'HEAD'], text=True).strip()
            self.assertEqual(actual, c['sha'])
            self.assertTrue((cache/c['id']/'LICENSE').is_file())
        self.assertTrue((self.home/'codex/skills/under-claw-meta-prompt/shared/evidence.py').is_file())
        sentinel = cache/'humanize/local-note.txt'
        sentinel.write_text('preserve me')
        proc = self.install('--codex-only', '--with-components')
        self.assertEqual(proc.returncode, 0, proc.stdout+proc.stderr)
        backups = list(self.home.glob('.under-claw-jarvis-plan-backup-*/components/humanize/local-note.txt'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), 'preserve me')
        self.assertFalse(sentinel.exists())
        self.assertFalse((self.home/'UNEXPECTED_INSTALL').exists())

    def test_failed_fetch_preserves_current_component_and_returns_failure(self):
        self.assertEqual(self.install('--codex-only', '--with-components').returncode, 0)
        cache = self.home/'.under-claw/components/humanize'
        previous = (cache/'SKILL.md').read_bytes()
        self.manifest['components'][0]['sha'] = '0'*40
        (self.repo/'shared/components.json').write_text(json.dumps(self.manifest))
        proc = self.install('--codex-only', '--with-components')
        self.assertNotEqual(proc.returncode, 0)
        self.assertEqual((cache/'SKILL.md').read_bytes(), previous)

    def test_default_contains_adapters_without_source_download(self):
        proc = self.install('--codex-only')
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertFalse((self.home/'.under-claw').exists())
        for skill in ('under-claw-jarvis-plan', 'under-claw-jarvis-plan-loop', 'under-claw-meta-prompt'):
            installed = self.home/'codex/skills'/skill/'shared'
            for c in self.manifest['components']:
                self.assertTrue((installed/c['adapter']).is_file())
            proc = subprocess.run(['python3', str(installed/'evidence.py'), '--help'], capture_output=True)
            self.assertEqual(proc.returncode, 0)


if __name__ == '__main__':
    unittest.main()
