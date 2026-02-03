# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

korosuke613のdotfilesリポジトリ。macOSとUbuntu環境の設定ファイルを管理している。

## セットアップコマンド

### macOS
```bash
cd ~/dotfiles/mac
./setup.sh
```

### Ubuntu
```bash
cd ~/dotfiles/ubuntu
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
- `ubuntu/` - Ubuntu用の設定ファイル（mac/と類似構造）

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
