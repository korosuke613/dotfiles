if (( $+commands[mise] )); then
  IFS= read -r mise_min_line < "$DOTFILES_HOME/../mise.toml"
  required_mise="${${mise_min_line#*\"}%\"*}"
  installed_mise=$(mise --version 2>/dev/null)
  installed_mise="${installed_mise%% *}"
  if [[ "$installed_mise" == "$required_mise" ]]; then
    mise_activation=$(mise activate zsh) && eval "$mise_activation"
    unset mise_activation
  fi
  unset mise_min_line required_mise installed_mise
fi

if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

[[ -f /opt/homebrew/share/google-cloud-sdk/path.zsh.inc ]] &&
  source /opt/homebrew/share/google-cloud-sdk/path.zsh.inc
[[ -f "$HOME/.config/op/plugins.sh" ]] &&
  source "$HOME/.config/op/plugins.sh"

[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"
