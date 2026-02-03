# Q pre block. Keep at the top of this file.
# zmodload zsh/zprof

if [[ -z "${DOTFILES_HOME}" ]]; then
  export DOTFILES_HOME=~/dotfiles/mac
fi

export DOTFILES_ZSH_HOME=${DOTFILES_HOME}/zsh

alias npx='echo "WARNING: npx は実行しないでください" && false'
alias npm='echo "WARNING: npm は実行しないでください" && false'
alias rm='echo "WARNING: rm は実行しないでください。代わりに trash を使ってください" && false'

eval "$(/opt/homebrew/bin/brew shellenv)"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/korosuke613/.rd/bin:$PATH"
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
eval "$(direnv hook zsh)"

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
eval "$(starship init zsh)"

# alias
# shellcheck source=.zshrc.alias
source ${DOTFILES_ZSH_HOME}/.zshrc.alias

# cd-fzf
# shellcheck source=.zshrc.cd_fzf
source ${DOTFILES_ZSH_HOME}/.zshrc.cd_fzf

# check_update_dotfiles
# shellcheck source=.zshrc.check_update_dotfiles
(source ${DOTFILES_ZSH_HOME}/.zshrc.check_update_dotfiles &) > /dev/null

# dotfiles auto sync (runs at most once per hour)
(${DOTFILES_HOME}/scripts/dotfiles-sync.sh >/dev/null &)

# autocomplete
# shellcheck source=.zshrc.autocomplete
source ${DOTFILES_ZSH_HOME}/.zshrc.autocomplete

# exec local script
# shellcheck source=.zshrc.local
if [[ -f "${DOTFILES_ZSH_HOME}/.zshrc.local" ]]; then
  source ${DOTFILES_ZSH_HOME}/.zshrc.local
fi

source ${DOTFILES_ZSH_HOME}/.zshrc.path

# VSCodeでは強制的にEmacsモード
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    bindkey -e  # Emacsモード
fi
if [[ "$TERM_PROGRAM" == "kiro" ]]; then
    bindkey -e  # Emacsモード
fi


# Setting of Go
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin


source /Users/korosuke613/.config/op/plugins.sh

# bun completions
[ -s "/Users/korosuke613/.bun/_bun" ] && source "/Users/korosuke613/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Terraform
export TF_CLI_ARGS_plan="--parallelism=50"
export TF_CLI_ARGS_apply="--parallelism=50"

# atuin
eval "$(atuin init zsh --disable-up-arrow)"

source "$HOME/.rye/env"

# aqua
export PATH="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin:$PATH"

[ -f ~/.inshellisense/key-bindings.zsh ] && source ~/.inshellisense/key-bindings.zsh

eval "$(mise activate)"

# 1Password CLI
# https://github.com/direnv/direnv/issues/662#issuecomment-2088058684
op daemon -d

# zprof


[[ -f "$HOME/fig-export/dotfiles/dotfile.zsh" ]] && builtin source "$HOME/fig-export/dotfiles/dotfile.zsh"

# Q post block. Keep at the bottom of this file.

# Created by `pipx` on 2025-06-28 13:40:13
export PATH="$PATH:/Users/korosuke613/.local/bin"

# Turso
export PATH="$PATH:/Users/korosuke613/.turso"

eval "$(/opt/homebrew/bin/brew shellenv)"

alias npx='echo "WARNING: npx は実行しないでください" && false'
alias npm='echo "WARNING: npm は実行しないでください" && false'
alias rm='echo "WARNING: rm は実行しないでください。代わりに trash を使ってください" && false'

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/korosuke613/.lmstudio/bin"
# End of LM Studio CLI section
