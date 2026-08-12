# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

korosuke613のmacOS用dotfilesリポジトリ。公開共通設定と、端末外のprivate role overlayを分離して管理する。

## セットアップコマンド

### macOS
```bash
cd ~/dotfiles/mac
./setup.sh
```



## アーキテクチャ

### ディレクトリ構造
- `mac/` - macOS用の設定ファイル
  - `setup.sh` - Homebrewインストール、vim-plug導入、シンボリックリンク作成
  - `Brewfile` - Homebrew管理パッケージ一覧
  - `zsh/` - zsh設定（モジュール分割構成）
  - `claude/` - Claude Code設定
  - `git/` - gitconfig、ignore、office用設定
  - `starship/` - プロンプト設定
  - `hammerspoon/` - macOSオートメーション
  - `ghostty/` - ターミナル設定
- `~/.config/dotfiles/private/` - 公開repo外のrole別設定（未追跡）

### zsh設定の分割構成
`.zshrc`は複数のファイルに分割されている：
- `.zshrc.setting` - 基本設定
- `.zshrc.alias` - エイリアス定義
- `.zshrc.history` - 履歴設定
- `.zshrc.cd_fzf` - fzfとの連携
- `.zshrc.local` - ローカル環境固有設定（gitignore対象）

### シンボリックリンク管理
setup.shは各設定ファイルを`~/dotfiles/`から適切な場所（`~/.config/`等）へシンボリックリンクする。

## 注意事項

- dotfilesはホームディレクトリ直下（`~/dotfiles`）にクローンすること
- zsh設定で`npx`、`npm`、`rm`コマンドは警告を出して実行しない設定になっている
- `rm`の代わりに`trash`を使用すること
