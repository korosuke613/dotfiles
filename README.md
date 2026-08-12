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

## Secure Enclave commit signing

Commit signing keys are per-machine and not synced by this repository: the
Secure Enclave cannot import an existing key, only generate a new
non-exportable one, so each machine needs its own key and its own additional
GitHub Signing Key entry (existing keys on other machines are left alone).
`~/.local/bin/ssh-sign` (managed by `mise.toml`) is a generic wrapper; run
this once per machine to actually enable it:

```shell
sc_auth create-ctk-identity -l git-sign -k p-256-ne -t none
ssh-keygen -w /usr/lib/ssh-keychain.dylib -K -N ""
mv id_ecdsa_sk_rk ~/.ssh/id_git_sign
mv id_ecdsa_sk_rk.pub ~/.ssh/id_git_sign.pub
```

Add the machine-local override (not tracked by any repository) to
`~/.gitconfig.local`:

```ini
[user]
	signingkey = ~/.ssh/id_git_sign

[gpg "ssh"]
	program = ~/.local/bin/ssh-sign
```

Register `~/.ssh/id_git_sign.pub` as a **Signing Key** at
https://github.com/settings/keys (a distinct title per machine, e.g.
`<hostname>-secure-enclave`), and optionally append the same line to
`~/.ssh/allowed_signers` for local `git log --show-signature` verification.
`-t none` skips authentication per signature (required for unattended /
agent commits); local processes on this machine can therefore invoke
signing without a human present.

Shell startup performs no downloads, installs, daemon launches, Git mutations,
or remote synchronization. Machine-only zsh settings belong in the untracked
`~/.config/dotfiles/local.zsh`.

`cdq` lists the public and private dotfiles as `dotfiles` and
`dotfiles-private` alongside normal ghq repositories.
