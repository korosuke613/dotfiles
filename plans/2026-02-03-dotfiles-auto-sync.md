# Dotfiles 自動同期 + 月次PR プラン（.zshrc トリガー）

## 概要
- 全てのMacで共有ブランチ `sync` を使用する。
- `.zshrc` 読み込み時に自動同期を実行し、1時間に1回までに制限する。
- 変更があれば GPG 署名なしで自動コミットし、`origin/sync` に push する。
- 月を跨いだ最初の同期時に `sync` → `main` のPRを作成する。
- 通常の出力はターミナルに出さず、エラーのみ表示する。詳細ログは `~/Library/Logs/dotfiles-sync.log`。

## 実装詳細

### 1) 自動同期スクリプト
- ファイル: `mac/scripts/dotfiles-sync.sh`
- 役割:
  - `~/dotfiles` の存在確認
  - `main` と `sync` を fetch
  - `sync` ローカルブランチが無い場合は作成
    - `origin/sync` があればそれを追跡
    - 無ければ `origin/main` から作成して push
  - `pull --rebase --autostash` を実行
  - 変更があれば add → 署名なし commit → push
  - 月次PR作成（`gh` を使用）
- 1時間制限 + 排他:
  - `~/.local/state/dotfiles-sync/last_run` に前回実行時刻を保存
  - 3600秒未満なら即終了
  - `~/.local/state/dotfiles-sync/lock` を使って同時実行を防止
- ログ:
  - コマンド出力は `~/Library/Logs/dotfiles-sync.log` に集約
  - 失敗時のみ stderr に短いメッセージを出し、同じ内容をログにも残す

### 2) zsh トリガー
- ファイル: `mac/zsh/.zshrc`
- 追加内容:
  - `(${DOTFILES_HOME}/scripts/dotfiles-sync.sh >/dev/null &)`

### 3) launchd は不使用
- launchd 関連ファイルとセットアップ変更は削除済み

### 4) README 更新
- `sync` ブランチ運用ルール
- `.zshrc` トリガーの自動同期
- 月次PR作成のタイミング
- 自動コミットは署名なしで実行

## エラー時の挙動
- 失敗時のみターミナルにエラーを表示
- 通常の git 出力はログファイルにのみ記録

## 確認項目
- 新しいターミナル起動時に通常ログが出ないこと
- 変更を入れて `.zshrc` が読まれると `sync` に push されること
- `~/Library/Logs/dotfiles-sync.log` にログが残ること
- 月跨ぎ時に `sync` が `main` より進んでいればPRが作成されること

## 変更ファイル
- 追加: `mac/scripts/dotfiles-sync.sh`
- 更新: `mac/zsh/.zshrc`
- 更新: `README.md`
- 更新: `mac/setup.sh`（launchd削除）
- 削除: `mac/launchd/com.korosuke613.dotfiles-sync.plist`
