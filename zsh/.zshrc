# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh
export DOTFILES=~/dotfiles

ZSH_THEME="candy"

# oh my zshで利用できるプラグインを指定
plugins=(brew brew-cask cdd gem git rbenv vagrant)

# User configuration
export PATH="/usr/bin:/bin"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/bin:/usr/bin:/usr/local/bin:$PATH"
export PATH="/usr/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH=~/dotfiles/create:$PATH
export PATH="$HOME/.poetry/bin:$PATH"

source $ZSH/oh-my-zsh.sh

#ユーザー設定の読み込み
source $DOTFILES/zsh/.zshrc.custom
source $DOTFILES/zsh/.zshrc.alias

fpath+=~/.zfunc

export GEM_HOME="$HOME/.gem"

