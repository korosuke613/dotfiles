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

### Sync (mac)
Shell startup does not modify the repository or contact the remote. The former
automatic `sync`-branch workflow has been disabled because branch switching,
staging, and pushing from `.zshrc` is unsafe.

Until the explicit `dot sync` workflow is installed, review and synchronize
changes manually from the repository with ordinary Git commands. Never use
`git add -A` for this repository.
