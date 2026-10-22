"""The one-click wrapper must fail closed on its own, independent of the Python gate.

These run the real shell script (Bash 3.2 on the macOS CI image, Bash 5 locally) with a stubbed
python3/git/uname so every branch can be exercised without a device, a compiler or a build.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / 'research/stock-v243-offscreen-20261021/G1-一键运行.command'


def _pick_bash():
    """Prefer a POSIX-shell bash that can see native paths; WSL bash cannot run D:\\ fixtures."""
    candidates = []
    found = shutil.which('bash')
    if found:
        candidates.append(found)
    # A Git for Windows install ships its own bash next to the git binary.
    git_binary = shutil.which('git')
    if git_binary:
        root = Path(git_binary).resolve().parent.parent
        for relative in ('bin/bash.exe', 'usr/bin/bash.exe'):
            candidate = root / relative
            if candidate.exists():
                candidates.append(str(candidate))
    for guess in (r'C:\Program Files\Git\bin\bash.exe', r'C:\Program Files (x86)\Git\bin\bash.exe'):
        if Path(guess).exists():
            candidates.append(guess)
    for candidate in candidates:
        try:
            probe = subprocess.run([candidate, '-c', 'uname -s'], capture_output=True, text=True,
                                   encoding='utf-8', errors='replace', timeout=30)
        except Exception:
            continue
        text = (probe.stdout or '')
        # Reject WSL (reports plain Linux): it cannot see D:\ fixtures.
        if probe.returncode == 0 and any(mark in text for mark in ('MINGW', 'MSYS', 'CYGWIN', 'Darwin')):
            return candidate
    return candidates[0] if candidates else '/bin/bash'


BASH = os.environ.get('G1_TEST_BASH') or _pick_bash()
DARWIN = sys.platform == 'darwin'
NEEDS_DARWIN = unittest.skipUnless(DARWIN, 'the wrapper refuses non-Darwin hosts before these branches')


def git(root, *args):
    result = subprocess.run(['git', '-C', str(root), *args], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(result.stderr)
    return result.stdout.strip()


class WrapperFixture:
    def __init__(self, root):
        self.root = Path(root)
        self.app = self.root / 'app'
        self.repo = self.app / 'g1-repo'
        self.nm = self.app / 'g1-src/nm'
        self.nv = self.app / 'g1-src/nv'
        self.tools = self.app / 'g1-tools'
        self.bin = self.root / 'fakebin'
        self.home = self.root / 'home'
        for path in (self.app, self.repo, self.nm, self.nv, self.tools, self.bin, self.home):
            path.mkdir(parents=True, exist_ok=True)
        (self.app / 'G1-一键运行.command').write_bytes(WRAPPER.read_bytes())
        (self.repo / 'scripts/g1').mkdir(parents=True)
        (self.repo / 'scripts/g1/offline_build.py').write_text('# fixture entry\n')
        (self.tools / 'make-4.4.1.tar.gz').write_bytes(b'fixture')
        (self.app / 'expected-commit.txt').write_text(self.commit(self.repo) + '\n')
        for tree in (self.nm, self.nv):
            (tree / 'input.txt').write_text('fixed\n')
            self.commit(tree)
        self.write_stubs()

    @staticmethod
    def commit(tree):
        git(tree, 'init', '-q')
        git(tree, 'config', 'core.autocrlf', 'false')
        git(tree, 'config', 'user.name', 'fixture')
        git(tree, 'config', 'user.email', 'fixture@example.invalid')
        git(tree, 'add', '-A')
        git(tree, 'commit', '-qm', 'fixture')
        return git(tree, 'rev-parse', 'HEAD')

    def write_stubs(self):
        (self.bin / 'uname').write_text('#!/bin/bash\nprintf "Darwin\\n"\n')
        # The payloads travel in files: a JSON document inside ${VAR:-default} is not reliably
        # re-expanded by every shell, and the resulting malformed text made the pass case look broken.
        self.preflight_payload = self.root / 'fake-preflight.json'
        self.build_payload = self.root / 'fake-build.json'
        self.preflight_payload.write_text('{}')
        self.build_payload.write_text('{}')
        (self.bin / 'python3').write_text(
            '#!/bin/bash\n'
            'if [ "${1:-}" = "-" ]; then exec "%s" "$@"; fi\n'
            'case "${2:-}" in\n'
            '  preflight) cat "%s"; exit "${G1_FAKE_PREFLIGHT_RC:-0}" ;;\n'
            '  build) cat "%s"; exit "${G1_FAKE_BUILD_RC:-0}" ;;\n'
            'esac\n'
            'exec "%s" "$@"\n' % (Path(sys.executable).as_posix(), self.preflight_payload.as_posix(),
                                  self.build_payload.as_posix(), Path(sys.executable).as_posix()))
        for name in ('uname', 'python3'):
            (self.bin / name).chmod(0o755)

    def run(self, stdin='', expected_override=None, name='expected-commit.txt'):
        env = dict(os.environ)
        env['PATH'] = str(self.bin) + os.pathsep + env.get('PATH', '')
        env['HOME'] = str(self.home)
        env['REPO'] = str(self.repo)
        env['NM_SRC'] = str(self.nm)
        env['NV_SRC'] = str(self.nv)
        env['G1_TOOLS'] = str(self.tools)
        env['WORK'] = str(self.root / ('work-' + str(os.getpid())))
        env.pop('G1_EXPECTED_COMMIT', None)
        return subprocess.run([BASH, str(self.app / 'G1-一键运行.command')],
                              input=stdin, capture_output=True, text=True,
                              encoding='utf-8', errors='replace', env=env, timeout=120)

    def set_preflight(self, payload, rc=0):
        self.preflight_payload.write_text(payload, encoding='utf-8')
        os.environ['G1_FAKE_PREFLIGHT_RC'] = str(rc)

    def set_build(self, payload, rc=0):
        self.build_payload.write_text(payload, encoding='utf-8')
        os.environ['G1_FAKE_BUILD_RC'] = str(rc)

    def preflight_json(self, checks=14, status='PASS', repo_commit=None, per_check='PASS'):
        head = repo_commit if repo_commit is not None else git(self.repo, 'rev-parse', 'HEAD')
        rows = [dict(id='c%d' % i, status=per_check) for i in range(checks)]
        return json.dumps(dict(status=status, checks=rows, check_count=len(rows),
                               repo_commit=head), indent=2)


class OneClickFailClosed(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.fx = WrapperFixture(self.tmp.name)

    def test_missing_expected_commit_file_stops(self):
        (self.fx.app / 'expected-commit.txt').unlink()
        result = self.fx.run()
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)

    def test_malformed_expected_commit_stops(self):
        (self.fx.app / 'expected-commit.txt').write_text('abc\n')
        result = self.fx.run()
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)

    @NEEDS_DARWIN
    def test_repo_head_mismatch_stops(self):
        (self.fx.app / 'expected-commit.txt').write_text('0' * 40 + '\n')
        result = self.fx.run()
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)

    @NEEDS_DARWIN
    def test_nonzero_exit_with_pass_json_is_failure(self):
        self.fx.set_preflight(self.fx.preflight_json(), rc=7)
        self.addCleanup(os.environ.pop, 'G1_FAKE_PREFLIGHT_RC', None)
        result = self.fx.run()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn('要继续编译吗', result.stdout)

    @NEEDS_DARWIN
    def test_zero_exit_with_failed_json_is_failure(self):
        self.fx.set_preflight(self.fx.preflight_json(status='FAILED', per_check='FAIL'))
        self.addCleanup(os.environ.pop, 'G1_FAKE_PREFLIGHT_RC', None)
        result = self.fx.run()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    @NEEDS_DARWIN
    def test_partial_check_list_is_failure(self):
        self.fx.set_preflight(self.fx.preflight_json(checks=13))
        self.addCleanup(os.environ.pop, 'G1_FAKE_PREFLIGHT_RC', None)
        result = self.fx.run()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    @NEEDS_DARWIN
    def test_repo_commit_binding_in_json_is_required(self):
        self.fx.set_preflight(self.fx.preflight_json(repo_commit='f' * 40))
        self.addCleanup(os.environ.pop, 'G1_FAKE_PREFLIGHT_RC', None)
        result = self.fx.run()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    @NEEDS_DARWIN
    def test_full_pass_offers_build_and_quit_is_zero(self):
        self.fx.set_preflight(self.fx.preflight_json())
        self.addCleanup(os.environ.pop, 'G1_FAKE_PREFLIGHT_RC', None)
        result = self.fx.run(stdin='\n')
        self.assertIn('要继续编译吗', result.stdout)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    @NEEDS_DARWIN
    def test_build_json_without_artifacts_is_failure(self):
        self.fx.set_preflight(self.fx.preflight_json())
        self.fx.set_build(json.dumps(dict(status='PASS_COMPILE_LINK_ONLY_NOT_LOAD_OR_GPU', artifacts={})))
        for key in ('G1_FAKE_PREFLIGHT_RC', 'G1_FAKE_BUILD_RC'):
            self.addCleanup(os.environ.pop, key, None)
        result = self.fx.run(stdin='BUILD\n')
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)


class WrapperScrubScope(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.fx = WrapperFixture(self.tmp.name)

    @NEEDS_DARWIN
    def test_tracked_metadata_survives_and_untracked_is_removed(self):
        tracked = self.fx.repo / '.DS_Store'
        tracked.write_bytes(b'tracked bytes')
        self.fx.commit(self.fx.repo)
        (self.fx.app / 'expected-commit.txt').write_text(git(self.fx.repo, 'rev-parse', 'HEAD') + '\n')
        untracked = self.fx.repo / 'nested/.DS_Store'
        untracked.parent.mkdir()
        untracked.write_bytes(b'finder junk')
        self.fx.set_preflight(self.fx.preflight_json(status='FAILED', per_check='FAIL'), rc=1)
        self.addCleanup(os.environ.pop, 'G1_FAKE_PREFLIGHT_RC', None)
        result = self.fx.run()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(tracked.exists(), 'tracked .DS_Store must survive the scrub')
        self.assertFalse(untracked.exists(), 'untracked .DS_Store should be removed')


if __name__ == '__main__':
    unittest.main()
