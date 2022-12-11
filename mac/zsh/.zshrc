# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
#!/usr/bin/env zsh
if [[ -z "${DOTFILES_HOME}" ]]; then
  export DOTFILES_HOME=~/dotfiles/mac
fi

export DOTFILES_ZSH_HOME=${DOTFILES_HOME}/zsh

eval "$(/opt/homebrew/bin/brew shellenv)"

# zshの設定
# shellcheck source=.zshrc.setting
source ${DOTFILES_ZSH_HOME}/.zshrc.setting

# proxy設定
# shellcheck source=.zshrc.proxy
source ${DOTFILES_ZSH_HOME}/.zshrc.proxy

# google cloud設定
# shellcheck source=.zshrc.gcp
source ${DOTFILES_ZSH_HOME}/.zshrc.gcp

# pecoでhistory検索
# shellcheck source=.zshrc.peco
source ${DOTFILES_ZSH_HOME}/.zshrc.peco

# direnv
export EDITOR=vim
eval "$(direnv hook zsh)"

# autocomplete
# shellcheck source=.zshrc.autocomplete
source ${DOTFILES_ZSH_HOME}/.zshrc.autocomplete

# ls を exa に置き換える
# shellcheck source=.zshrc.exa
source ${DOTFILES_ZSH_HOME}/.zshrc.exa

# cat を bat に置き換える
# shellcheck source=.zshrc.bat
source ${DOTFILES_ZSH_HOME}/.zshrc.bat

# setting zsh history
# shellcheck source=.zshrc.history
source ${DOTFILES_ZSH_HOME}/.zshrc.history

# setting asdf
# shellcheck source=.zshrc.asdf
source ${DOTFILES_ZSH_HOME}/.zshrc.asdf

# auto assam
# shellcheck source=.zshrc.auto_assam
source ${DOTFILES_ZSH_HOME}/.zshrc.auto_assam

# auto renice
# shellcheck source=.zshrc.auto_renice

# reniceする必要がなくなってきたので一旦オフにする
# source ${DOTFILES_ZSH_HOME}/.zshrc.auto_renice_fast
# source ${DOTFILES_ZSH_HOME}/.zshrc.auto_renice_zoom

# setting tabtab
# shellcheck source=.zshrc.tabtab
source ${DOTFILES_ZSH_HOME}/.zshrc.tabtab

# setting starship
eval "$(starship init zsh)"

# alias
# shellcheck source=.zshrc.alias
source ${DOTFILES_ZSH_HOME}/.zshrc.alias

# cd-fzf
# shellcheck source=.zshrc.cd_fzf
source ${DOTFILES_ZSH_HOME}/.zshrc.cd_fzf

# lima
# shellcheck source=.zshrc.lima
source ${DOTFILES_ZSH_HOME}/.zshrc.lima

# check_update_dotfiles
# shellcheck source=.zshrc.check_update_dotfiles
source ${DOTFILES_ZSH_HOME}/.zshrc.check_update_dotfiles

# exec local script
# shellcheck source=.zshrc.local
if [[ -f "${DOTFILES_ZSH_HOME}/.zshrc.local" ]]; then
  source ${DOTFILES_ZSH_HOME}/.zshrc.local
fi

source ${DOTFILES_ZSH_HOME}/.zshrc.path

# Setting of Go
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin

# bun completions
[ -s "/Users/korosuke613/.bun/_bun" ] && source "/Users/korosuke613/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"



### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/korosuke613/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
