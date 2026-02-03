# dotfiles
my dotfiles ...

Benchmark: https://korosuke613.github.io/dotfiles/dev/bench/

## Setup (mac)

### Clone this repository
**Please clone the dotfiles directly under your home directory.**

```shell
cd ~
git clone https://github.com/korosuke613/dotfiles.git
```

### Add zsh/.zshrc.proxy_ip
```shell
cd ~/dotfiles/mac/zsh
touch .zshrc.proxy_ip
touch .zshrc.local
```

### Install the required libraries && Place each dotfiles as a symbolic link
```shell
cd ~/dotfiles/mac
./setup.sh
```

## Setup (ubuntu)

### Clone this repository
**Please clone the dotfiles directly under your home directory.**

```shell
cd ~
git clone https://github.com/korosuke613/dotfiles.git
```

### Install

```console
cd ~/dotfiles/ubuntu
./setup.sh
```

## Features

### Check update dotfiles repository
When loading .zshrc, it will tell you if there are any changes in the dotfiles repository.

[details](mac/zsh/.zshrc.check_update_dotfiles)

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

### Auto sync (mac)
Each Mac uses the shared `sync` branch and automatically syncs every hour when `.zshrc` is loaded.

Behavior:
- `pull --rebase` from `origin/sync`
- If there are changes, auto commit (no GPG signing) and push to `origin/sync`
- When the month changes, create a PR from `sync` to `main` (monthly squash merge)

Notes:
- The default branch on GitHub remains `main`
- The monthly PR is created at the first sync run after the month changes
