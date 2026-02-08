# dotfiles-sync.sh

dotfiles リポジトリを `sync` ブランチで自動同期するためのスクリプトです。
`.zshrc` から呼び出され、人間がターミナルを開いたときだけ動くように制御されています。

## 目的
- 複数の Mac 間で dotfiles を自動同期する
- 差分があるときはコミット＆プッシュを促す
- 月次で `sync` → `main` の PR を作成する

## 動作概要
1. 1時間に1回までの制限（`last_run`）
2. 同時起動を防ぐロック（`lock`）
3. `sync` ブランチの準備（無ければ作成）
4. `pull --rebase --autostash` を実行
5. 変更があれば「コミット＆プッシュするか」を質問
6. 月を跨いだ最初の実行で PR 作成

## 仕様（詳細）
### 起動条件
- `.zshrc` から呼び出される前提
- 対話的シェルのみ（`interactive` + `PS1`）
- stdin と stderr が TTY のときのみ（`-t 0`, `-t 2`）
- `CI` 環境変数がない場合のみ
- `SSH_ORIGINAL_COMMAND` がない場合のみ（ssh 非対話実行を除外）
- `CLAUDECODE` 環境変数がない場合のみ（Claude Code 環境での実行を除外）

### 実行頻度
- 最終実行時刻を `~/.local/state/dotfiles-sync/last_run` に保存
- 前回実行から 3600 秒未満なら即終了

### 排他制御
- `~/.local/state/dotfiles-sync/lock` を `mkdir` ロックとして使用
- ロックが 10 分（600 秒）以上古い場合は自動削除して再試行
- ロック取得に失敗した場合はスキップ通知を表示して終了

### Git 同期の流れ
1. `git fetch origin main sync`
2. ローカル `sync` がなければ作成
   - `origin/sync` があれば追跡ブランチとして作成
   - なければ `origin/main` から作成して `origin/sync` に push
3. `git pull --rebase --autostash origin sync`
4. 作業ツリーに差分があれば、コミット＆プッシュ確認を行う

### コミット & プッシュ
- 変更がある場合のみ `Commit and push dotfiles changes now? [y/N]:` を表示
- `y` / `Y` 以外は実行せず終了
- コミットメッセージ形式: `sync: YYYY-MM-DD HH:MM`
- 署名は Git 設定に従う（例: 1Password SSH 署名）

### 月次PR作成
- 月が変わった最初の実行のみ対象
- `sync` が `main` より進んでいる場合のみ PR 作成
- `gh` が利用可能な場合のみ作成
- PR タイトル: `dotfiles: sync YYYY-MM`
- PR 本文: `Monthly squash merge for YYYY-MM.`
- 既にPRが存在する場合は作成せず月の記録だけ更新

### 出力とログ
- ターミナルには「人間向けメッセージ」だけ表示
- git の生ログは `~/Library/Logs/dotfiles-sync.log` に集約
- 通知の外枠は色付き（stderr が TTY の場合）

### 失敗時の挙動
- `git fetch/pull/commit/push` が失敗するとエラーメッセージを表示して終了
- rebase 失敗時は `rebase --abort` を試行して終了
- `gh` が無い場合は PR 作成をスキップし、処理は継続

## 通知メッセージ
同期開始時に以下のメッセージを表示します。

```
=== DOTFILES CHANGES DETECTED ===
Syncing now (runs at most once per hour)...
Log: ~/Library/Logs/dotfiles-sync.log
=================================
```

ロック中は以下のように表示されます。

```
=== DOTFILES CHANGES DETECTED ===
Sync already running (started ~42s ago). Skipping this run.
Log: ~/Library/Logs/dotfiles-sync.log
=================================
```

## ログ
- ログ出力先: `~/Library/Logs/dotfiles-sync.log`
- git の生ログは常にログファイルへ集約
- ターミナルには人間向けのメッセージのみ表示

## 状態ファイル
- `~/.local/state/dotfiles-sync/last_run`
  - 最終実行時刻（epoch）
- `~/.local/state/dotfiles-sync/lock`
  - ロックディレクトリ（10分以上古いものは自動削除）
- `~/.local/state/dotfiles-sync/last_pr_month`
  - 最後に PR を作成した月（YYYY-MM）

## PR 作成
- 月を跨いだ最初の同期で PR を作成
- ただし `sync` が `main` より進んでいる場合のみ
- `gh` コマンドが利用可能な場合のみ

## 変更したいときのポイント
- 同期頻度: `last_run` の判定（3600秒）
- ロックの寿命: 10分（600秒）
- 通知文面: `dotfiles-sync.sh` の通知出力

## 関連ファイル
- `mac/scripts/dotfiles-sync.sh`
- `mac/zsh/.zshrc`
