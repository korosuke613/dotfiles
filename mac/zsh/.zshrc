export DOTFILES_HOME="${DOTFILES_HOME:-$HOME/dotfiles/mac}"
export DOTFILES_ZSH_HOME="$DOTFILES_HOME/zsh"
export PATH="$HOME/.local/bin:$PATH"

for module in options history aliases completion integrations; do
  source "$DOTFILES_ZSH_HOME/$module.zsh"
done

unset PIP_INDEX_URL UV_INDEX_URL
local_config="${DOTFILES_LOCAL_ZSH:-$HOME/.config/dotfiles/local.zsh}"
[[ -f "$local_config" ]] && source "$local_config"

private_root="${DOTFILES_PRIVATE_HOME:-$HOME/.config/dotfiles/private}"
profile_file="${DOTFILES_PROFILE_FILE:-$HOME/.config/dotfiles/profiles}"
if [[ -f "$profile_file" ]]; then
  while IFS= read -r profile; do
    [[ -z "$profile" || "$profile" == \#* ]] && continue
    role_config="$private_root/profiles/$profile/zsh.zsh"
    [[ -f "$role_config" ]] && source "$role_config"
  done < "$profile_file"
fi
