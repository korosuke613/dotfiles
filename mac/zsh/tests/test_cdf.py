import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ALIASES = Path(__file__).resolve().parents[1] / "aliases.zsh"


class CdfTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.home = self.root / "home"
        self.home.mkdir()
        self.capture = self.root / "candidates"
        self.env = dict(
            os.environ,
            HOME=str(self.home),
            XDG_CONFIG_HOME=str(self.home / ".config"),
            GIT_CONFIG_GLOBAL=str(self.home / ".gitconfig"),
            GIT_CONFIG_NOSYSTEM="1",
            CDF_CAPTURE=str(self.capture),
        )

    def init_repo(self, path):
        subprocess.run(
            ["git", "init", "-q", str(path)], env=self.env, check=True
        )

    def workspace(self, name):
        path = self.home / "ghq" / "example.com" / "owner" / name
        self.init_repo(path)
        (path / ".gitignore").write_text("repos/\nouter-build/\n")
        (path / "outer-build").mkdir()
        (path / "docs").mkdir()
        repo = path / "repos" / "service [one]"
        self.init_repo(repo)
        (repo / ".gitignore").write_text("node_modules/\nbuild/\n")
        (repo / ".ignore").write_text("ignored-by-fd/\n")
        for directory in ("src/lib", "node_modules/pkg", "build", "ignored-by-fd"):
            (repo / directory).mkdir(parents=True)
        return path, repo

    def run_cdf(self, cwd, selected="", cancel=False, fd_failure=False):
        env = dict(
            self.env,
            CDF_SELECTED=selected,
            CDF_CANCEL="1" if cancel else "0",
            CDF_FD_FAILURE="1" if fd_failure else "0",
        )
        result = subprocess.run(
            [
                "zsh", "-f", "-c",
                '''
source "$1"
fzf() {
  command cat > "$CDF_CAPTURE"
  [[ "$CDF_CANCEL" == 0 ]] || return 130
  print -r -- "$CDF_SELECTED"
}
if [[ "$CDF_FD_FAILURE" == 1 ]]; then
  fd() { print -u2 "fd fixture failure"; return 7; }
fi
cdf || exit $?
print -r -- "$PWD"
''',
                "cdf-test", str(ALIASES),
            ],
            cwd=cwd, env=env, capture_output=True, text=True,
        )
        candidates = self.capture.read_text().splitlines() if self.capture.exists() else []
        return result, candidates

    def test_named_workspaces_and_search_origins(self):
        for name in ("team-vmonorepo", "home"):
            workspace, repo = self.workspace(name)
            for cwd in (workspace, workspace / "repos", repo, repo / "src"):
                with self.subTest(name=name, cwd=cwd):
                    selected = str((repo / "src/lib").relative_to(cwd))
                    result, candidates = self.run_cdf(cwd, selected)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stdout.strip(), str(repo / "src/lib"))
                    self.assertIn(selected, candidates)
                    self.assertEqual(len(candidates), len(set(candidates)))
                    self.assertNotIn("", candidates)
                    for ignored in ("node_modules", "build", "ignored-by-fd"):
                        self.assertFalse(any(ignored in entry for entry in candidates))

    def test_multiple_workspaces_below_current_directory(self):
        for name in ("first-workspace", "second-workspace"):
            self.workspace(name)
        selected = "ghq/example.com/owner/second-workspace/repos/service [one]/src"
        result, candidates = self.run_cdf(self.home, selected)
        self.assertEqual(result.returncode, 0, result.stderr)
        for name in ("first-workspace", "second-workspace"):
            self.assertIn(
                f"ghq/example.com/owner/{name}/repos/service [one]/src", candidates
            )

    def test_explicit_symlink_repository(self):
        workspace, _ = self.workspace("home")
        external = self.root / "external"
        self.init_repo(external)
        (external / ".gitignore").write_text("generated/\n")
        (external / "src").mkdir()
        (external / "generated").mkdir()
        (workspace / "repos" / "linked").symlink_to(external, target_is_directory=True)
        result, candidates = self.run_cdf(workspace, "repos/linked/src")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("repos/linked/src", candidates)
        self.assertNotIn("repos/linked/generated", candidates)

    def test_gitfile_repository(self):
        workspace, _ = self.workspace("home")
        repo = workspace / "repos" / "gitfile"
        subprocess.run(
            ["git", "init", "-q", "--separate-git-dir", str(self.root / "metadata"), str(repo)],
            env=self.env, check=True,
        )
        (repo / "src").mkdir()
        result, candidates = self.run_cdf(workspace, "repos/gitfile/src")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("repos/gitfile/src", candidates)

    def test_ignored_non_repositories_stay_hidden(self):
        workspace, _ = self.workspace("home")
        (workspace / "repos" / "not-a-repo" / "cache").mkdir(parents=True)
        result, candidates = self.run_cdf(workspace, "docs")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any("not-a-repo" in entry for entry in candidates))

    def test_global_and_repository_excludes_are_preserved(self):
        workspace, repo = self.workspace("home")
        global_ignore = self.root / "global-ignore"
        global_ignore.write_text("global-cache/\n")
        Path(self.env["GIT_CONFIG_GLOBAL"]).write_text(
            f'[core]\n\texcludesFile = "{global_ignore}"\n'
        )
        (repo / ".git/info/exclude").write_text("local-cache/\n")
        (repo / ".fdignore").write_text("fd-cache/\n")
        for name in ("global-cache", "local-cache", "fd-cache"):
            (repo / name).mkdir()
        result, candidates = self.run_cdf(workspace, "docs")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any("cache" in entry for entry in candidates))

    def test_cancel_does_not_change_directory(self):
        workspace, _ = self.workspace("home")
        result, _ = self.run_cdf(workspace, cancel=True)
        self.assertEqual(result.returncode, 130)

    def test_empty_directory(self):
        result, candidates = self.run_cdf(self.home)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(self.home))
        self.assertEqual(candidates, [])
        self.assertFalse(self.capture.exists())

    def test_fd_failure_is_propagated(self):
        result, _ = self.run_cdf(self.home, fd_failure=True)
        self.assertEqual(result.returncode, 7)
        self.assertIn("fd fixture failure", result.stderr)
        self.assertFalse(self.capture.exists())

    def test_outside_home_is_rejected(self):
        result, _ = self.run_cdf(self.root)
        self.assertEqual(result.returncode, 1)
        self.assertIn("current directory must be under", result.stderr)


if __name__ == "__main__":
    unittest.main()
