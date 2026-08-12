# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

korosuke613のmacOS用dotfilesリポジトリ。公開共通設定と、端末外のprivate role overlayを分離して管理する。

## セットアップコマンド

### macOS
```bash
cd ~/dotfiles
./mac/setup.sh check
./mac/setup.sh dry-run
./mac/setup.sh apply
```



## アーキテクチャ

### ディレクトリ構造
- `mac/` - macOS用の設定ファイル
  - `setup.sh` - check/dry-run/apply、Homebrew/vim-plug導入、リンク作成、role設定生成
  - `zsh/` - zsh設定（モジュール分割構成）
  - `claude/` - Claude Code設定
  - `git/` - 公開共通gitconfigとignore
  - `scripts/dot` - 明示的なscan/syncコマンド
  - `starship/` - プロンプト設定
  - `hammerspoon/` - macOSオートメーション
  - `ghostty/` - ターミナル設定
- `~/.config/dotfiles/private/` - 別private repoのrole別設定
- `~/.config/dotfiles/profiles` - 有効roleを1行ずつ指定する未追跡manifest

### Public/private role boundary

公開repoには個人共通設定とroleの読み込み機構だけを置く。企業・顧客の
identity、credential helper、package index、Claude plugin/marketplaceは
private repoのroleに置き、公開ファイルへコピーしない。

`mac/setup.sh apply`はmanifestを読み、以下を生成・適用する：

- `~/.config/dotfiles/gitconfig` - 各roleのgitconfigをinclude
- `~/.claude/settings.json` - public settingsとrole JSONを`jq`でmerge
- `.zshrc` - 各roleの`zsh.zsh`をshell起動時にsource

role JSONはpublic設定をベースにmanifestの順序でmergeされ、同じキーは
後のroleが優先される。privateファイルのcredential値やtokenをpublic
repoへ移動してはいけない。

### Safe synchronization

shell startupはgit branch、worktree、remoteを変更しない。公開内容の検査は
`dot scan`、同期は人間が差分を確認する明示的な`dot sync`で行う。
`git add -A`や、startupからのcommit/pushを使用してはいけない。

### zsh設定の分割構成
`.zshrc`は複数のファイルに分割されている：
- `.zshrc.setting` - 基本設定
- `.zshrc.alias` - エイリアス定義
- `.zshrc.history` - 履歴設定
- `.zshrc.cd_fzf` - fzfとの連携
- `.zshrc.local` - 旧来のローカル環境固有設定（gitignore対象）

### シンボリックリンク管理
setup.shは各設定ファイルを`~/dotfiles/`から適切な場所（`~/.config/`等）へシンボリックリンクする。

## 注意事項

- dotfilesはホームディレクトリ直下（`~/dotfiles`）にクローンすること
- private roleは`~/.config/dotfiles/private`にcloneし、manifestで明示的に選択すること
- zsh設定で`npx`、`npm`、`rm`コマンドは警告を出して実行しない設定になっている
- `rm`の代わりに`trash`を使用すること
- private roleの設定をpublic repoのCLAUDE.mdや設定ファイルへ再掲しないこと
