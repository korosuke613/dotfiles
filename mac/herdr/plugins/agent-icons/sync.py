"""Prefix the displayed agent name with a brand emoji for each pane.

The sidebar joins adjacent tokens with " · ", so the emoji goes into the
display name itself rather than a separate token.

Runs on startup and on every pane.agent_detected event. It reconciles all
panes instead of parsing the event payload, so it is idempotent.
"""

import json
import os
import subprocess

HERDR = os.environ.get("HERDR_BIN_PATH", "herdr")
SOURCE = "plugin:korosuke613.agent-icons"

# Keys are canonical agent ids; aliases cover ids used in other config keys.
ICONS = {
    "claude": "🦀",
    "codex": "🌀",
    "copilot": "🐙",
    "github_copilot": "🐙",
    "cursor": "🧊",
    "opencode": "⬜",
    "open_code": "⬜",
    "pi": "🥧",
    "omp": "🧁",
    "droid": "🏭",
    "devin": "👷",
    "kimi": "🌙",
    "kilo": "🟨",
    "hermes": "👟",
    "qodercli": "🟩",
    "qwen": "🟣",
    "letta": "💌",
    "mastracode": "🎼",
    "grok": "⚫",
    "antigravity-cli": "🌈",
    "agy": "🌈",
    "amp": "⚡",
    "kiro": "👻",
    "maki": "🍣",
    "gemini": "✨",
    "cline": "🤖",
}


def herdr(*args):
    return subprocess.run([HERDR, *args], capture_output=True, text=True, check=True).stdout


def main():
    panes = json.loads(herdr("pane", "list"))["result"]["panes"]
    for pane in panes:
        agent = pane.get("agent") or ""
        icon = ICONS.get(agent.lower())
        if icon:
            # --agent guards the display name so it only applies to this agent.
            args = ["--agent", agent, "--display-agent", f"{icon} {agent}"]
        else:
            args = ["--clear-display-agent"]
        herdr("pane", "report-metadata", pane["pane_id"], "--source", SOURCE, *args)


if __name__ == "__main__":
    main()
