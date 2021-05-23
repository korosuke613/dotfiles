#!/bin/sh

echo "dotfilesLink is Start !"

# vim
ln -sf ~/dotfiles/vim/.vimrc ~/.vimrc

# zsh
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc

# starship
mkdir -p ~/.config
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# asdf
ln -sf ~/dotfiles/asdf/.asdfrc ~/.asdfrc
ln -sf ~/dotfiles/asdf/.tool-versions ~/.tool-versions

# git
mkdir -p ~/.config/git
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/git/ignore ~/.config/git/ignore

echo "dotfilesLink is End !"
