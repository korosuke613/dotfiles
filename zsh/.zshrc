#!/usr/bin/env zsh

export DOTFILES_ZSH_HOME=~/dotfiles/zsh

# zplugの設定
# shellcheck source=.zshrc.zplug
source ${DOTFILES_ZSH_HOME}/.zshrc.zplug

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

# setting JAVA_HOME
export JAVA_HOME=$(/usr/libexec/java_home)

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

# setting tabtab
# shellcheck source=.zshrc.tabtab
source ${DOTFILES_ZSH_HOME}/.zshrc.tabtab

# setting starship
eval "$(starship init zsh)"

# alias
# shellcheck source=.zshrc.alias
source ${DOTFILES_ZSH_HOME}/.zshrc.alias
