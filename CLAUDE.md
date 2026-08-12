# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

korosuke613のmacOS用dotfilesリポジトリ。公開共通設定と、端末外のprivate role overlayを分離して管理する。

Private role repository: https://github.com/korosuke613/dotfiles-private

## セットアップコマンド

### macOS (Apple Silicon)
```bash
cd ~/dotfiles
./setup.sh check
./setup.sh dry-run
./setup.sh apply
```



## アーキテクチャ

### ディレクトリ構造
- `mise.toml` / `mise.lock` - CLIの厳密なバージョンとdotfile配置
- `setup.sh` - pinned mise導入、check/dry-run/apply
- `mac/` - macOS用の設定ファイル
  - `zsh/` - zsh設定（モジュール分割構成）
  - `claude/` - Claude Code設定
  - `git/` - 公開共通gitconfigとignore
  - `scripts/dot` - scan/doctor/tools updateコマンド
  - `starship/` - プロンプト設定
  - `hammerspoon/` - macOSオートメーション
  - `ghostty/` - ターミナル設定
- `~/.config/dotfiles/private/` - 別private repoのrole別設定
- `~/.config/dotfiles/profiles` - 有効roleを1行ずつ指定する未追跡manifest

### Public/private role boundary

公開repoには個人共通設定とroleの読み込み機構だけを置く。企業・顧客の
identity、credential helper、package index、Claude plugin/marketplaceは
private repoのroleに置き、公開ファイルへコピーしない。

`setup.sh apply`はmanifestを読み、以下を生成・適用する：

- `~/.config/dotfiles/gitconfig` - 各roleのgitconfigをinclude
- `~/.claude/settings.json` - public settingsとrole JSONを`jq`でmerge
- `.zshrc` - 各roleの`zsh.zsh`をshell起動時にsource

role JSONはpublic設定をベースにmanifestの順序でmergeされ、同じキーは
後のroleが優先される。privateファイルのcredential値やtokenをpublic
repoへ移動してはいけない。

### Safe synchronization

shell startupはネットワークアクセス、daemon起動、git branch、worktree、
remoteを変更しない。公開内容の検査は`dot scan`で行い、通常のGit操作で
人間が差分を確認して同期する。`git add -A`やstartupからのcommit/pushを
使用してはいけない。

### zsh設定の分割構成
`.zshrc`は責務別の`options.zsh`、`history.zsh`、`aliases.zsh`、
`completion.zsh`、`integrations.zsh`に分割されている。端末固有設定は
未追跡の`~/.config/dotfiles/local.zsh`へ置く。

### シンボリックリンク管理
mise bootstrapは各設定ファイルを`~/dotfiles/`から適切な場所へリンクする。

## 注意事項

- dotfilesはホームディレクトリ直下（`~/dotfiles`）にクローンすること
- private roleは`~/.config/dotfiles/private`にcloneし、manifestで明示的に選択すること
- CLIは原則miseで管理し、Homebrewとの重複は`dot doctor`で検出する
- zsh設定で`npx`、`npm`、`rm`コマンドは警告を出して実行しない
- `rm`の代わりに`trash`を使用すること
- private roleの設定をpublic repoのCLAUDE.mdや設定ファイルへ再掲しないこと
- roleの実装を調査するときはprivate repositoryも参照すること。ただし秘密値を回答やpublic repoへ転載しないこと
