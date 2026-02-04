# zmodload zsh/zprof

if [[ -z "${DOTFILES_HOME}" ]]; then
  export DOTFILES_HOME=~/dotfiles/mac
fi

export DOTFILES_ZSH_HOME=${DOTFILES_HOME}/zsh

# キャッシュディレクトリの初期化
ZSH_CACHE_DIR="$HOME/.cache/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

# evalキャッシュ関数
# 使用法: _cache_eval "キャッシュ名" "コマンド" [有効期限（日）]
_cache_eval() {
    local cache_name="$1"
    local command="$2"
    local max_age="${3:-7}"  # デフォルト7日
    local cache_file="$ZSH_CACHE_DIR/${cache_name}.zsh"

    # キャッシュが存在しないか、max_age日より古い場合は再生成
    if [[ ! -f "$cache_file" ]] || [[ -n $(find "$cache_file" -mtime +${max_age} 2>/dev/null) ]]; then
        eval "$command" > "$cache_file"
    fi
    source "$cache_file"
}

# brew shellenv のキャッシュ化（1日ごとに更新）
_cache_eval "brew_shellenv" "/opt/homebrew/bin/brew shellenv" 1

# zshの設定
# shellcheck source=.zshrc.plugins
source ${DOTFILES_ZSH_HOME}/.zshrc.plugins

# proxy設定
# shellcheck source=.zshrc.proxy
source ${DOTFILES_ZSH_HOME}/.zshrc.proxy

# google cloud設定
# shellcheck source=.zshrc.gcp
source ${DOTFILES_ZSH_HOME}/.zshrc.gcp

# direnv
export EDITOR=vim
_cache_eval "direnv_hook" "direnv hook zsh" 7

# ls を eza に置き換える
# shellcheck source=.zshrc.eza
source ${DOTFILES_ZSH_HOME}/.zshrc.eza

# cat を bat に置き換える
# shellcheck source=.zshrc.bat
source ${DOTFILES_ZSH_HOME}/.zshrc.bat

# setting zsh history
# shellcheck source=.zshrc.history
source ${DOTFILES_ZSH_HOME}/.zshrc.history


# setting starship
_cache_eval "starship_init" "starship init zsh" 7

# alias
# shellcheck source=.zshrc.alias
source ${DOTFILES_ZSH_HOME}/.zshrc.alias

# cd-fzf
# shellcheck source=.zshrc.cd_fzf
source ${DOTFILES_ZSH_HOME}/.zshrc.cd_fzf

# dotfiles auto sync (runs at most once per hour)
${DOTFILES_HOME}/scripts/dotfiles-sync.sh

# autocomplete
# shellcheck source=.zshrc.autocomplete
source ${DOTFILES_ZSH_HOME}/.zshrc.autocomplete

# exec local script
# shellcheck source=.zshrc.local
if [[ -f "${DOTFILES_ZSH_HOME}/.zshrc.local" ]]; then
  source ${DOTFILES_ZSH_HOME}/.zshrc.local
fi

source ${DOTFILES_ZSH_HOME}/.zshrc.path

# VSCode/Kiroでは強制的にEmacsモード
if [[ "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "kiro" ]]; then
    bindkey -e  # Emacsモード
fi

[[ -f "$HOME/.config/op/plugins.sh" ]] && source "$HOME/.config/op/plugins.sh"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Terraform
export TF_CLI_ARGS_plan="--parallelism=50"
export TF_CLI_ARGS_apply="--parallelism=50"

# atuin
_cache_eval "atuin_init" "atuin init zsh --disable-up-arrow" 7

[[ -f "$HOME/.rye/env" ]] && source "$HOME/.rye/env"

[ -f ~/.inshellisense/key-bindings.zsh ] && source ~/.inshellisense/key-bindings.zsh

_cache_eval "mise_activate" "mise activate zsh" 7

# 1Password CLI
# https://github.com/direnv/direnv/issues/662#issuecomment-2088058684
op daemon -d

# zprof
