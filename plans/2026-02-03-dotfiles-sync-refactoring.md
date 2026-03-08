# dotfiles-sync.sh 可読性改善計画

## 概要

247行の `mac/scripts/dotfiles-sync.sh` をリファクタリングし、可読性を向上させる。
動作は変更せず、構造のみ改善する。

## 現状の問題

1. **メインロジックがトップレベルに展開** - 全体の流れが見えにくい
2. **ロック処理のネストが深い** - 条件分岐が3段階
3. **関数化されているのはログ関連のみ** - 責務が混在
4. **処理フローが追いにくい** - 247行を上から下まで読む必要がある

## 改善方針

### main関数パターンの導入

処理フローを一箇所で俯瞰できるようにする:

```zsh
main() {
  setup_colors
  check_prerequisites || exit 0
  acquire_lock || exit 0

  print_start_notice

  ensure_sync_branch || exit 1
  sync_changes
  create_monthly_pr

  log "Finished dotfiles sync"
}

main "$@"
```

### 関数分割（7関数）

| 関数名 | 責務 | 元の行 |
|--------|------|--------|
| `setup_colors()` | 色変数の初期化 | 25-38 |
| `check_prerequisites()` | human-guard + repo/コマンド確認 | 73-93 |
| `acquire_lock()` | ロック取得・スロットル処理 | 95-141 |
| `ensure_sync_branch()` | sync branchの準備（fetch含む） | 152-180 |
| `sync_changes()` | pull --rebase + commit/push | 182-213 |
| `create_monthly_pr()` | 月次PR作成 | 215-243 |
| `main()` | 全体フロー制御 | 新規 |

### 内部ヘルパー関数（アンダースコアプレフィックス）

- `_check_throttle()` - 1時間制限チェック
- `_try_acquire_lock()` - ロック取得試行
- `_setup_cleanup_trap()` - trap設定
- `_create_sync_branch()` - sync branch作成
- `_commit_and_push()` - コミット＆プッシュ実行

## 実装順序

リスクが低い順に実装:

### Phase 1: 低リスク
1. `setup_colors()` 関数化
2. `check_prerequisites()` 関数化

### Phase 2: 中リスク
3. `ensure_sync_branch()` 関数化
4. `sync_changes()` 関数化
5. `create_monthly_pr()` 関数化

### Phase 3: 高リスク
6. `acquire_lock()` 関数化（最も複雑）

### Phase 4: 統合
7. `main()` 関数導入
8. セクションコメント整理

## 改善後のファイル構成

```
1-25:    shebang、定数定義、ディレクトリ作成
26-75:   ユーティリティ関数（色、ログ、run）
76-90:   check_prerequisites()
91-140:  acquire_lock() + ヘルパー
141-175: ensure_sync_branch() + ヘルパー
176-215: sync_changes() + ヘルパー
216-250: create_monthly_pr()
251-270: main() + print_start_notice()
271:     main "$@"
```

推定行数: 約270行（+23行程度）

## 対象ファイル

- `mac/scripts/dotfiles-sync.sh` - リファクタリング対象

## 検証方法

1. **構文チェック**: `zsh -n mac/scripts/dotfiles-sync.sh`
2. **デバッグモード実行**: `DOTFILES_SYNC_DEBUG=1 ./mac/scripts/dotfiles-sync.sh`
3. **実際の動作確認**: 新しいターミナルを開いて `.zshrc` が正常にロードされることを確認
4. **各シナリオのテスト**:
   - 変更がない場合
   - 変更があり、コミットする場合
   - ロックが存在する場合（別ターミナルで実行中）

## 変更しないもの

- 変数定義（REPO, SYNC_BRANCH等）
- ログ関数の実装（log, err, info, success, dbg, run）
- 全体的な処理フロー・ロジック
- エラーハンドリングの方針
