
# User configuration
export PATH="/usr/bin:/bin"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/bin:/usr/bin:/usr/local/bin:$PATH"
export PATH="/usr/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH=~/dotfiles/create:$PATH
export PATH="$HOME/.poetry/bin:$PATH"


#ユーザー設定の読み込み
source $DOTFILES/zsh/.zshrc.custom
source $DOTFILES/zsh/.zshrc.alias

fpath+=~/.zfunc

eval "$(starship init zsh)"
