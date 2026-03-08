# dotfiles-sync 月次PR作成フローの改善

## Context

dotfiles-syncの月次PR作成機能は、`sync`ブランチから直接PRを作成している。mainへのマージはsquash mergeで行うため、syncブランチには個別コミットが残り続け、次月以降のPRにコミット差分が蓄積し続ける問題がある。

加えて、既存のPRチェック(`run gh pr list | grep`)は`run`関数がstdoutをログファイルにリダイレクトするため、パイプに何も流れず**常に偽を返すバグ**がある。

## 修正方針

### 新フロー

1. エフェメラルブランチ `sync-pr/YYYY-MM` を `sync` から作成
2. `git reset --soft origin/main` で全差分をステージング状態に圧縮
3. 1コミットとしてcommit & push
4. そのブランチからPR作成
5. 元のブランチに復帰
6. 古い `sync-pr/*` ローカルブランチを削除

### 既存バグ修正

- PRチェックで `run` を使わず、`gh pr list --json` で直接件数を取得

## 修正対象ファイル

- `/Users/korosuke613/dotfiles/mac/scripts/dotfiles-sync.sh` — `create_monthly_pr` 関数（行321-358）のみ

## 実装詳細

```zsh
create_monthly_pr() {
  local current_month=$(date '+%Y-%m')
  local last_month=""
  if [[ -f "$STATE_FILE" ]]; then
    last_month=$(cat "$STATE_FILE" | tr -d '\n')
  fi

  if [[ "$current_month" == "$last_month" ]]; then
    return 0
  fi

  if ! command -v gh >/dev/null 2>&1; then
    log "gh not available; skipping PR creation"
    return 0
  fi

  local ahead_count=$(git -C "$REPO" rev-list --count origin/main.."$SYNC_BRANCH")
  if [[ "$ahead_count" -eq 0 ]]; then
    log "No changes to main..sync; skipping PR"
    return 0
  fi

  local pr_branch="sync-pr/${current_month}"

  # 既存PRチェック（run を使わず直接gh cliを呼ぶ）
  local pr_count
  pr_count=$(gh pr list --repo "$REPO" --base main --head "$pr_branch" --state open --json number --jq 'length' 2>>"$LOG_FILE") || true
  if [[ "${pr_count:-0}" -gt 0 ]]; then
    echo "$current_month" > "$STATE_FILE"
    log "Monthly PR already exists for $pr_branch; recorded month"
    return 0
  fi

  # 現在のブランチを記録
  local original_branch
  original_branch=$(git -C "$REPO" rev-parse --abbrev-ref HEAD)

  # エフェメラルPRブランチ作成
  if ! run git -C "$REPO" switch -c "$pr_branch" "$SYNC_BRANCH"; then
    err "Failed to create branch $pr_branch"
    run git -C "$REPO" switch "$original_branch" || true
    return 1
  fi

  # main との差分をステージング状態に圧縮
  if ! run git -C "$REPO" reset --soft origin/main; then
    err "git reset --soft origin/main failed"
    run git -C "$REPO" switch "$original_branch" || true
    run git -C "$REPO" branch -D "$pr_branch" || true
    return 1
  fi

  # 1コミットにまとめる
  if ! run git -C "$REPO" commit -m "dotfiles: sync $current_month"; then
    err "git commit failed on $pr_branch"
    run git -C "$REPO" switch "$original_branch" || true
    run git -C "$REPO" branch -D "$pr_branch" || true
    return 1
  fi

  # プッシュ
  if ! run git -C "$REPO" push -u origin "$pr_branch"; then
    err "git push failed for $pr_branch"
    run git -C "$REPO" switch "$original_branch" || true
    run git -C "$REPO" branch -D "$pr_branch" || true
    return 1
  fi

  # PR作成
  if run gh pr create --repo "$REPO" --base main --head "$pr_branch" \
       --title "dotfiles: sync $current_month" \
       --body "Monthly squash merge for $current_month."; then
    echo "$current_month" > "$STATE_FILE"
    log "Created monthly PR for $current_month from $pr_branch"
  else
    err "gh pr create failed"
    run git -C "$REPO" switch "$original_branch" || true
    return 1
  fi

  # 元のブランチに復帰
  if ! run git -C "$REPO" switch "$original_branch"; then
    err "Failed to switch back to $original_branch"
    return 1
  fi

  # 古いPRブランチをローカル削除
  local old_branches
  old_branches=$(git -C "$REPO" branch --list 'sync-pr/*' | grep -v "$pr_branch" || true)
  if [[ -n "$old_branches" ]]; then
    echo "$old_branches" | while read -r branch; do
      branch="${branch## }"
      log "Deleting old PR branch: $branch"
      run git -C "$REPO" branch -D "$branch" || true
    done
  fi

  return 0
}
```

## 設計上のポイント

- **syncブランチは一切変更しない** — エフェメラルブランチのみ操作
- **エラー時は元ブランチに復帰 + 失敗ブランチ削除**で安全に失敗
- **`git reset --soft`はワーキングツリーを触らない**ため、未コミット変更があっても安全（ただし`sync_changes`が先に実行されるため通常はクリーン）
- **PRブランチが既にリモートに存在する場合**: `switch -c`が失敗 → エラーハンドリングで復帰。必要に応じて`push --force-with-lease`に変更可能
- **リモートの古いPRブランチ削除**: GitHubの「マージ時にブランチ削除」設定に依存。未設定の場合は `git push origin --delete` を追加

## 検証方法

1. `DOTFILES_SYNC_DEBUG=1` で手動実行し、ブランチ作成・reset・commit・push・PR作成の各ステップを確認
2. 作成されたPRのFiles changedタブで、コミット数が1であることを確認
3. エラーケースのテスト: PR作成後に再度実行し、既存PRチェックで正しくスキップされることを確認
4. `git log --oneline sync-pr/YYYY-MM` で1コミットのみであることを確認
