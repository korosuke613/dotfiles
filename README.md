# dotfiles
my dotfiles ...

## Setup

### Clone this repository
**Please clone the dotfiles directly under your home directory.**

```shell
cd ~
git clone https://github.com/korosuke613/dotfiles.git
```

### Add zsh/.zshrc.proxy_ip
```shell
cd ~/dotfiles/zsh
touch .zshrc.proxy_ip
```

### Install the required libraries && Place each dotfiles as a symbolic link
```shell
cd ~/dotfiles
./setup.sh
```

## Features

### Check update dotfiles repository
When loading .zshrc, it will tell you if there are any changes in the dotfiles repository.

[details](./zsh/.zshrc.check_update_dotfiles)

```
=== DOTFILES IS DIRTY ===
  The dotfiles have been changed. Please update them with the following command.

  cd /Users/korosuke613/dotfiles
  git add .
  git commit -m "update dotfiles"
  git push origin main
=========================

dotfiles on  main [!] 📨 gmail.com 
❯ 
```
