#!/bin/sh

mode="${1:-apply}"
case "$mode" in
    apply) ;;
    check)
        command -v brew >/dev/null 2>&1 || echo "check: Homebrew is not installed"
        command -v zsh >/dev/null 2>&1 || echo "check: zsh is not installed"
        command -v git >/dev/null 2>&1 || echo "check: git is not installed"
        test -d "$HOME/dotfiles/mac" || {
            echo "check: expected checkout at $HOME/dotfiles/mac" >&2
            exit 1
        }
        exit 0
        ;;
    dry-run)
        printf '%s\n' \
            "Would link ~/.vimrc" \
            "Would link ~/.zshrc" \
            "Would link ~/.gitconfig" \
            "Would link ~/.config/git/ignore" \
            "Would link ~/.config/starship.toml" \
            "Would link ~/.local/bin/dot"
        exit 0
        ;;
    *)
        echo "Usage: $0 [check|dry-run|apply]" >&2
        exit 2
        ;;
esac

# brew がインストールされていなければインストール
if [ -z "$(command -v brew)" ]; then
    echo "--- Install Homebrew is Start! ---"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/${USER}/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if [ -f ./Brewfile ]; then
        brew bundle --file=./Brewfile
    fi

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
mkdir -p ~/.local/bin
ln -sf ~/dotfiles/mac/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/mac/git/ignore ~/.config/git/ignore
ln -sf ~/dotfiles/mac/scripts/dot ~/.local/bin/dot


# hammerspoon
mkdir -p ~/.hammerspoon
ln -sf ~/dotfiles/mac/hammerspoon/init.lua ~/.hammerspoon/init.lua

# dotfiles
mkdir -p ~/ghq
ln -sf ~/dotfiles ~/ghq/dotfiles

# tmux
ln -sf ~/dotfiles/mac/tmux/.tmux.conf ~/.tmux.conf

# claude
./claude/setup.sh

echo "--- Link dotfiles is Done!  ---"
