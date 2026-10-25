import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ALIASES = Path(__file__).resolve().parents[1] / "aliases.zsh"


class SbxTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        bin_dir = Path(self.temp.name) / "bin"
        bin_dir.mkdir()
        fake = bin_dir / "sbx"
        fake.write_text('#!/bin/sh\nprintf "%s|%s\\n" "${HERDR_AGENT-unset}" "$*"\n')
        fake.chmod(0o755)
        self.env = {k: v for k, v in os.environ.items() if k not in ("HERDR_PANE_ID", "HERDR_AGENT")}
        self.env["PATH"] = f"{bin_dir}:{self.env['PATH']}"

    def run_sbx(self, *args, pane=True):
        env = dict(self.env, HERDR_PANE_ID="w1:1") if pane else self.env
        result = subprocess.run(
            ["zsh", "-f", "-c", 'source "$1"; shift; sbx "$@"', "sbx-test", str(ALIASES), *args],
            env=env, capture_output=True, text=True, check=True,
        )
        return result.stdout.strip()

    def test_agent_name(self):
        self.assertEqual(self.run_sbx("run", "claude"), "claude|run claude")

    def test_sandbox_name(self):
        self.assertEqual(self.run_sbx("run", "claude-home"), "claude|run claude-home")

    def test_flags_before_agent(self):
        self.assertEqual(
            self.run_sbx("run", "--name", "work", "copilot", "."),
            "copilot|run --name work copilot .",
        )

    def test_agent_args_are_ignored(self):
        self.assertEqual(
            self.run_sbx("run", "my-box", "--", "codex"),
            "unset|run my-box -- codex",
        )

    def test_other_subcommands(self):
        self.assertEqual(self.run_sbx("ls", "claude-home"), "unset|ls claude-home")

    def test_outside_herdr(self):
        self.assertEqual(self.run_sbx("run", "claude", pane=False), "unset|run claude")


if __name__ == "__main__":
    unittest.main()
