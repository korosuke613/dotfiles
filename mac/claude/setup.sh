#!/bin/sh

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
private_root="${DOTFILES_PRIVATE_HOME:-$HOME/.config/dotfiles/private}"
profile_file="${DOTFILES_PROFILE_FILE:-$HOME/.config/dotfiles/profiles}"

# claude
mkdir -p ~/.claude
ln -sf "$script_dir/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$script_dir/statusline.sh" ~/.claude/statusline.sh

set -- "$script_dir/settings.json"
if [ -f "$profile_file" ]; then
  while IFS= read -r profile; do
    case "$profile" in
      ""|\#*) continue ;;
    esac
    role_settings="$private_root/profiles/$profile/claude-settings.json"
    if [ -f "$role_settings" ]; then
      set -- "$@" "$role_settings"
    fi
  done < "$profile_file"
fi

if [ "$#" -gt 1 ]; then
  merged_settings=$(mktemp)
  jq -s 'reduce .[] as $item ({}; . * $item)' "$@" > "$merged_settings"
  mv "$merged_settings" ~/.claude/settings.json
else
  ln -sf "$script_dir/settings.json" ~/.claude/settings.json
fi

# claude skills
ln -sfn "$script_dir/skills" ~/.claude/skills
