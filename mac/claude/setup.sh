#!/bin/sh

# claude
mkdir -p ~/.claude
ln -sf ~/dotfiles/mac/claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf ~/dotfiles/mac/claude/settings.json ~/.claude/settings.json
ln -sf ~/dotfiles/mac/claude/statusline.sh ~/.claude/statusline.sh

# claude skills
ln -sfn ~/dotfiles/mac/claude/skills ~/.claude/skills
