# dotfiles

Personal dotfiles for Apple Silicon Macs. `mise bootstrap` owns CLI versions
and symlinked configuration; client and work identities remain in the private
role repository.

Private role overlays: https://github.com/korosuke613/dotfiles-private

## Setup

Clone directly under the home directory:

```shell
git clone https://github.com/korosuke613/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Optionally clone the private repository to
`~/.config/dotfiles/private`, then list enabled roles one per line in
`~/.config/dotfiles/profiles`. Roles are explicit and are never inferred from
the hostname, network, or current directory.

Preview before applying:

```shell
./setup.sh check
./setup.sh dry-run
./setup.sh apply
```

`apply` installs a checksum-pinned mise binary when needed, validates private
roles, applies dotfiles, and installs the exact CLI versions in `mise.toml`
using `mise.lock`. It does not install Homebrew formulae, casks, or GUI apps.
`dry-run` temporarily downloads and verifies the same pinned mise binary when
it is not installed. `dot doctor` reports manual prerequisites.
Claude Code and GitHub Copilot CLI keep their standalone installers. This
repository manages Claude's settings, status line, and skills only.

## Maintenance

```shell
dot doctor        # diagnose missing tools, apps, links, and private roles
dot doctor --duplicates # list optional Homebrew cleanup commands
dot scan          # scan tracked public content
dot tools update  # pin releases at least seven days old and refresh mise.lock
```

Review the diff after `dot tools update`. Homebrew duplicates reported by
`dot doctor` are intentionally removed by hand.

Shell startup performs no downloads, installs, daemon launches, Git mutations,
or remote synchronization. Machine-only zsh settings belong in the untracked
`~/.config/dotfiles/local.zsh`.

`cdq` lists the public and private dotfiles as `dotfiles` and
`dotfiles-private` alongside normal ghq repositories.
