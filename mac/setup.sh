#!/bin/sh

# brew がインストールされていなければインストール
if [ -z "$(command -v brew)" ]; then
    echo "--- Install Homebrew is Start! ---"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew bundle

    echo "--- Install Homebrew is Done!  ---"
fi

# vim-plugをインストール
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# dotfilesを配置
echo "--- Link dotfiles is Start! ---"

# vim
ln -sf ~/dotfiles/mac/vim/.vimrc ~/.vimrc

# zsh
ln -sf ~/dotfiles/mac/zsh/.zshrc ~/.zshrc

# starship
mkdir -p ~/.config
ln -sf ~/dotfiles/mac/starship/starship.toml ~/.config/starship.toml

# asdf
ln -sf ~/dotfiles/mac/asdf/.asdfrc ~/.asdfrc
ln -sf ~/dotfiles/mac/asdf/.tool-versions ~/.tool-versions

# git
mkdir -p ~/.config/git
ln -sf ~/dotfiles/mac/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/mac/git/ignore ~/.config/git/ignore

# hammerspoon
mkdir -p ~/.hammerspoon
ln -sf ~/dotfiles/mac/hammerspoon/init.lua ~/.hammerspoon/init.lua


echo "--- Link dotfiles is Done!  ---"
