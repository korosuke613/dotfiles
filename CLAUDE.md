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
  - `setup.sh` - Homebrewインストール、vim-plug導入、シンボリックリンク作成（bash実装、エラーハンドリング付き）
  - `zsh/` - zsh設定（モジュール分割構成）
  - `claude/` - Claude Code設定
  - `git/` - gitconfig、ignore、office用設定
  - `starship/` - プロンプト設定
  - `hammerspoon/` - macOSオートメーション
  - `ghostty/` - ターミナル設定
  - `vim/` - vim設定
  - `scripts/` - dotfiles自動同期スクリプト
- `ubuntu/` - Ubuntu用の設定ファイル（mac/と類似構造）

### zsh設定の分割構成
`.zshrc`は複数のファイルに分割されている：
- `.zshrc.plugins` - zshプラグイン（autosuggestions、syntax-highlighting）
- `.zshrc.alias` - エイリアス定義
- `.zshrc.history` - 履歴設定
- `.zshrc.cd_fzf` - fzfとの連携
- `.zshrc.eza` - ls → eza置き換え設定
- `.zshrc.bat` - cat → bat置き換え設定
- `.zshrc.proxy` - プロキシ設定
- `.zshrc.gcp` - Google Cloud設定
- `.zshrc.autocomplete` - 自動補完設定
- `.zshrc.path` - PATH追加設定
- `.zshrc.local` - ローカル環境固有設定（gitignore対象）

### シンボリックリンク管理
setup.shは各設定ファイルを`~/dotfiles/`から適切な場所（`~/.config/`等）へシンボリックリンクする。
連想配列を使用してリンク定義を一元管理しており、保守性が高い。

### バージョン管理ツール
- miseを使用（旧asdfから移行済み）
- 各種言語のバージョン管理に使用

## 注意事項

- dotfilesはホームディレクトリ直下（`~/dotfiles`）にクローンすること
- zsh設定で`npx`、`npm`、`rm`コマンドは警告を出して実行しない設定になっている
- `rm`の代わりに`trash`を使用すること
