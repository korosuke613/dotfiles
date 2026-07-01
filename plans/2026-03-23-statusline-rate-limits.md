# ステータスライン rate_limits 改善プラン

## Context

`statusline.sh` のレートリミット表示は、現在 macOS Keychain からOAuthトークンを取得し `api.anthropic.com/api/oauth/usage` をAPI呼び出ししている（99-221行目、約120行）。Claude Code v2.1.80+ では `rate_limits` フィールドがJSON入力として直接渡されるようになったため、API呼び出し・キャッシュ・トークン取得がすべて不要になる。

参考: https://nyosegawa.com/posts/claude-code-statusline-rate-limits/

## 対象ファイル

- `/Users/korosuke613/dotfiles/mac/claude/statusline.sh`（唯一の変更対象）

## 変更内容

### 1. 削除するもの（99-221行目）

| 対象 | 理由 |
|------|------|
| `CACHE_FILE`, `CACHE_MAX_AGE` 変数 | キャッシュ不要 |
| `OP_CLAUDE_TOKEN_ITEM_NAME` 変数 | OAuthトークン不要 |
| `fetch_usage()` 関数（security + curl） | API呼び出し不要 |
| `get_usage()` 関数（キャッシュロジック） | キャッシュ不要 |
| ISO 8601 → epoch 変換（`date -j -f`） | Unixタイムスタンプ直接使用 |

### 2. 新コード（99行目以降に挿入）

JSON入力の `rate_limits` から直接読み取る:

```bash
usage_info=""
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

if [ -n "$five_pct" ] && [ -n "$seven_pct" ]; then
    five_int=$(printf "%.0f" "$five_pct")
    seven_int=$(printf "%.0f" "$seven_pct")
    now_epoch=$(date +%s)

    # 5h残り時間（算術演算のみ）
    five_reset_time=""
    if [ -n "$five_reset" ]; then
        remaining=$((five_reset - now_epoch))
        # ... hours/minutes計算（現行と同じロジック）
    fi

    # 7d残り時間（同上）
    seven_reset_time=""
    if [ -n "$seven_reset" ]; then
        remaining=$((seven_reset - now_epoch))
        # ... days/hours計算（現行と同じロジック）
    fi

    # 色分け・表示フォーマットは現行と同一
    usage_info=" | limit: ${five_color}${five_int}%${RESET}(...), ${seven_color}${seven_int}%${RESET}(...)"
fi
```

### 3. テストケース更新（16-39行目）

- テストブロック冒頭に動的タイムスタンプ変数を追加
- 既存テストケースのJSONに `rate_limits` フィールドを追加
- 新規テストケース追加: green / yellow / red / rate_limitsなし

## Before / After

| 項目 | Before | After |
|------|--------|-------|
| 行数（99-221） | ~123行 | ~40行 |
| 外部依存 | `security`, `curl`, `jq`, `date -j -f` | `jq`, `date +%s` |
| キャッシュ | `/tmp/claude-usage-cache.json` | なし |
| ネットワーク | あり（最大3秒timeout） | なし |
| 時刻パース | ISO 8601変換 | Unixタイムスタンプ直接 |

## 検証

```bash
bash ~/dotfiles/mac/claude/statusline.sh --test
```

- 各色（緑/黄/赤）の正しい表示
- rate_limitsなしの場合にusage_info空
- 残り時間フォーマット（`22m`, `1h30m`, `1d18h`）
