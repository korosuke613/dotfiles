#!/bin/bash
set -euo pipefail

# DOTFILES_HOME変数の設定
DOTFILES_HOME="${DOTFILES_HOME:-$HOME/dotfiles/mac}"

# brew がインストールされていなければインストール
if [ -z "$(command -v brew)" ]; then
    echo "--- Install Homebrew is Start! ---"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    brew bundle

    echo "--- Install Homebrew is Done!  ---"
fi

# vim-plugをインストール（存在チェック付き）
if [[ ! -f ~/.vim/autoload/plug.vim ]]; then
    echo "--- Installing vim-plug ---"
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "--- vim-plug installation done ---"
fi

# dotfilesを配置
echo "--- Link dotfiles is Start! ---"

# シンボリックリンク定義（連想配列）
declare -A SYMLINKS=(
    ["vim/.vimrc"]="$HOME/.vimrc"
    ["zsh/.zshrc"]="$HOME/.zshrc"
    ["starship/starship.toml"]="$HOME/.config/starship.toml"
    ["git/.gitconfig"]="$HOME/.gitconfig"
    ["git/ignore"]="$HOME/.config/git/ignore"
    ["git/office.gitconfig"]="$HOME/.config/git/office"
    ["hammerspoon/init.lua"]="$HOME/.hammerspoon/init.lua"
)

# シンボリックリンク作成
for src in "${!SYMLINKS[@]}"; do
    target="${SYMLINKS[$src]}"
    mkdir -p "$(dirname "$target")"
    ln -sf "${DOTFILES_HOME}/${src}" "$target"
    echo "Linked: ${DOTFILES_HOME}/${src} -> $target"
done

# dotfiles -> ghq/dotfiles へのリンク
mkdir -p ~/ghq
ln -sf ~/dotfiles ~/ghq/dotfiles
echo "Linked: ~/dotfiles -> ~/ghq/dotfiles"

# claude設定のセットアップ
if [[ -f "${DOTFILES_HOME}/claude/setup.sh" ]]; then
    echo "--- Setting up Claude ---"
    "${DOTFILES_HOME}/claude/setup.sh"
fi

echo "--- Link dotfiles is Done!  ---"
