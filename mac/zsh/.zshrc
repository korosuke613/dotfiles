# Q pre block. Keep at the top of this file.
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

    # キャッシュが存在しないか、空か、max_age日より古い場合は再生成
    if [[ ! -s "$cache_file" ]] || [[ -n $(find "$cache_file" -mtime +${max_age} 2>/dev/null) ]]; then
        eval "$command" > "$cache_file"
    fi
    source "$cache_file"
}

# ファイルがあれば source、無ければ対処法つき警告を出す
# 使用法: _source_or_warn <file> <表示名> <対処コマンド>
_source_or_warn() {
    if [[ -f "$1" ]]; then
        source "$1"
    else
        echo "⚠ $2 未インストール → $3" >&2
    fi
}

# brew shellenv のキャッシュ化（1日ごとに更新）
_cache_eval "brew_shellenv" "/opt/homebrew/bin/brew shellenv" 1

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)


# zshの設定
# shellcheck source=.zshrc.setting
source ${DOTFILES_ZSH_HOME}/.zshrc.setting

# proxy設定
# shellcheck source=.zshrc.proxy
source ${DOTFILES_ZSH_HOME}/.zshrc.proxy

# google cloud設定
# shellcheck source=.zshrc.gcp
source ${DOTFILES_ZSH_HOME}/.zshrc.gcp

# direnv
export EDITOR=vim
_cache_eval "direnv_hook" "direnv hook zsh" 7

# ls を exa に置き換える
# shellcheck source=.zshrc.exa
source ${DOTFILES_ZSH_HOME}/.zshrc.exa

# cat を bat に置き換える
# shellcheck source=.zshrc.bat
source ${DOTFILES_ZSH_HOME}/.zshrc.bat

# setting zsh history
# shellcheck source=.zshrc.history
source ${DOTFILES_ZSH_HOME}/.zshrc.history

# auto assam
# shellcheck source=.zshrc.auto_assam
source ${DOTFILES_ZSH_HOME}/.zshrc.auto_assam

# setting starship
_cache_eval "starship_init" "starship init zsh" 7

# alias
# shellcheck source=.zshrc.alias
source ${DOTFILES_ZSH_HOME}/.zshrc.alias

# cd-fzf
# shellcheck source=.zshrc.cd_fzf
source ${DOTFILES_ZSH_HOME}/.zshrc.cd_fzf

# autocomplete
# shellcheck source=.zshrc.autocomplete
source ${DOTFILES_ZSH_HOME}/.zshrc.autocomplete

# exec local script
# shellcheck source=.zshrc.local
if [[ -f "${DOTFILES_ZSH_HOME}/.zshrc.local" ]]; then
  source ${DOTFILES_ZSH_HOME}/.zshrc.local
else
  # Client-specific package indexes belong in a private role overlay.
  unset PIP_INDEX_URL UV_INDEX_URL
fi

source ${DOTFILES_ZSH_HOME}/.zshrc.path

# VSCodeでは強制的にEmacsモード
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    bindkey -e  # Emacsモード
fi
if [[ "$TERM_PROGRAM" == "kiro" ]]; then
    bindkey -e  # Emacsモード
fi


# Setting of Go（GOPATHはデフォルト値を使用して高速化）
if [[ -z "$GOPATH" ]]; then
    export GOPATH="${HOME}/go"
fi
export PATH="$PATH:$GOPATH/bin"


_source_or_warn "$HOME/.config/op/plugins.sh" "op plugins" "op plugin init gh"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Terraform
export TF_CLI_ARGS_plan="--parallelism=50"
export TF_CLI_ARGS_apply="--parallelism=50"

# atuin
_cache_eval "atuin_init" "atuin init zsh --disable-up-arrow" 7

_source_or_warn "$HOME/.rye/env" "rye" "rye は開発終了のため uv への移行を検討"

# aqua
export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

[ -f ~/.inshellisense/key-bindings.zsh ] && source ~/.inshellisense/key-bindings.zsh

_cache_eval "mise_activate" "mise activate zsh" 7

# 1Password CLI
# https://github.com/direnv/direnv/issues/662#issuecomment-2088058684
op daemon -d

# zprof

# Created by `pipx` on 2025-06-28 13:40:13
export PATH="$PATH:$HOME/.local/bin"

# Turso
export PATH="$PATH:$HOME/.turso"

# docker sandboxes のテレメトリをオフ
export SBX_NO_TELEMETRY=1

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section


unalias -m 'gh'
gh () {
        command gh "$@"
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# NemoClaw PATH setup
export PATH="$HOME/.local/bin:$PATH"
# end NemoClaw PATH setup

# Optional private role overlays are explicit and never inferred from cwd,
# hostname, or network location.
DOTFILES_PRIVATE_HOME="${DOTFILES_PRIVATE_HOME:-$HOME/.config/dotfiles/private}"
DOTFILES_PROFILE_FILE="${DOTFILES_PROFILE_FILE:-$HOME/.config/dotfiles/profiles}"
if [[ -f "$DOTFILES_PROFILE_FILE" ]]; then
  while IFS= read -r profile; do
    [[ -z "$profile" || "$profile" == \#* ]] && continue
    profile_file="$DOTFILES_PRIVATE_HOME/profiles/$profile/zsh.zsh"
    if [[ -f "$profile_file" ]]; then
      source "$profile_file"
    else
      echo "dotfiles: private profile '$profile' is missing: $profile_file" >&2
      return 1
    fi
  done < "$DOTFILES_PROFILE_FILE"
fi
