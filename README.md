# dotfiles
my dotfiles ...

Benchmark: https://korosuke613.github.io/dotfiles/dev/bench/

Private role overlays: https://github.com/korosuke613/dotfiles-private

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

### Select private roles (optional)
Clone the private overlay repository to `~/.config/dotfiles/private`, then
create `~/.config/dotfiles/profiles` with one explicitly selected role per
line. Profiles are never inferred from the current directory, hostname, or
network.

```text
personal
client-role
```

Missing private roles fail closed instead of silently using another identity.

### Install the required libraries && Place each dotfiles as a symbolic link
```shell
cd ~/dotfiles/mac
./setup.sh
```

## Features

### Sync (mac)
Shell startup does not modify the repository or contact the remote. The former
automatic `sync`-branch workflow has been disabled because branch switching,
staging, and pushing from `.zshrc` is unsafe.

After running the macOS setup, `dot sync` is available for reviewed changes.
It only operates on `main`, refuses a dirty worktree or remote divergence,
stages tracked updates only, runs the public-content scanner, and asks for
confirmation again before commit and push. `dot scan` runs the scanner without
syncing.
