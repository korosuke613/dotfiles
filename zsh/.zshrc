
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
export DOTFILES="${HOME}/dotfiles"
source $DOTFILES/zsh/.zshrc.custom
source $DOTFILES/zsh/.zshrc.alias

eval "$(starship init zsh)"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
