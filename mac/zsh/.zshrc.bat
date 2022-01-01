#!/usr/bin/env zsh

# cat を bat に置き換える
if [ "$(command -v bat)" ]; then
  unalias -m 'cat'
  alias cat='bat -pp --theme="Nord"'
fi
