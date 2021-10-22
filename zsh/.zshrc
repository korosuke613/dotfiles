#!/usr/bin/env zsh
#### FIG ENV VARIABLES ####
# Please make sure this block is at the start of this file.
[ -s ~/.fig/shell/pre.sh ] && source ~/.fig/shell/pre.sh
#### END FIG ENV VARIABLES ####

export DOTFILES_HOME=~/dotfiles
export DOTFILES_ZSH_HOME=${DOTFILES_HOME}/zsh

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
source ${DOTFILES_ZSH_HOME}/.zshrc.auto_renice_fast
source ${DOTFILES_ZSH_HOME}/.zshrc.auto_renice_zoom

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
source ${DOTFILES_ZSH_HOME}/.zshrc.local

#### FIG ENV VARIABLES ####
# Please make sure this block is at the end of this file.
[ -s ~/.fig/fig.sh ] && source ~/.fig/fig.sh
#### END FIG ENV VARIABLES ####
export PATH="/usr/local/opt/ansible@2.9/bin:$PATH"
