#!/usr/bin/env bash

set -x

cd `dirname $0`

export DOTENV_HOME=$(pwd)/ubuntu

# apt
sudo apt-get update
sudo apt-get install --no-install-recommends -y \
  curl \
  zsh \
  direnv \
  vim \
  fonts-firacode \
  fzf \
  fd-find \
  tig

# gh
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt-get update
sudo apt-get install --no-install-recommends -y gh

# go
sudo add-apt-repository -y ppa:longsleep/golang-backports
sudo apt-get update
sudo apt-get install --no-install-recommends -y golang

# ghq
go install github.com/x-motemen/ghq@latest

# asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.1
. "${HOME}/.asdf/asdf.sh"
asdf update
ln -sf ${DOTENV_HOME}/asdf/.asdfrc ~/.asdfrc

# vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ln -sf ${DOTENV_HOME}/vim/.vimrc ~/.vimrc

# zsh
ln -sf ${DOTENV_HOME}/zsh/.zshrc ~/.zshrc

# starship
mkdir -p ~/.config
ln -sf ${DOTENV_HOME}/starship/starship.toml ~/.config/starship.toml
${DOTENV_HOME}/starship/starship_install.sh --yes

# git
mkdir -p ~/.config/git
ln -sf ${DOTENV_HOME}/git/.gitconfig ~/.gitconfig
ln -sf ${DOTENV_HOME}/git/ignore ~/.config/git/ignore

# デフォルトシェルの変更
sudo chsh -s "$(which zsh)" $USER
