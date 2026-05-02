---
name: issue-compact
description: "GitHub Issueのコンパクト化。Issueとすべてのコメントを読み込み、背景・確定した設計判断・アクションアイテムを集約したv2 Issueを作成し、元のIssueをクローズする。「issueをコンパクトに」「issue整理」で起動。"
argument-hint: "[issue-number or URL]"
disable-model-invocation: false
allowed-tools: "Bash(gh issue view:*), Bash(gh api:*), Bash(gh issue comment:*), Bash(gh issue create:*), Bash(gh issue close:*), Read, AskUserQuestion"
---

# /issue-compact — Issue コンパクト化ワークフロー

GitHub Issue とすべてのコメントを読み込み、背景・確定した設計判断・アクションアイテムを集約した v2 Issue を作成し、元の Issue をクローズするワークフロー。

## Phase 0: 入力パース・検証

1. `$ARGUMENTS` を解析する
   - **数字のみ**（例: `42`）→ Issue 番号として扱う。`gh` が git remote から自動検出する
   - **GitHub URL**（例: `https://github.com/owner/repo/issues/42`）→ owner/repo/number をパースし、以降の `gh` コマンドに `--repo owner/repo` を付与する
   - **空・不正値** → エラーメッセージを出して終了する
2. `gh issue view <number> --json title,body,state,labels` で存在確認
   - Issue が存在しない → エラーで終了
   - state が `CLOSED` → 「この Issue はクローズ済みです。続行しますか？」と AskUserQuestion で確認

## Phase 1: 読み込みと分析

1. `gh issue view <number> --json title,body,state,labels,comments` で全情報取得
2. 全テキスト（本文 + 全コメント）から以下を抽出・分類する:
   - **背景/動機**: なぜこの Issue が作られたか、解決したい課題
   - **確定済み判断**: 「決定:」「→」で示された結論、`[x]` チェック済み項目、設計判断サマリのテーブル
   - **未解決項目**: まだ決まっていない事項（あれば）
   - **アクションアイテム**: 具体的な実装タスク、TODO
   - **スコープ外**: 明示的に除外されたもの
3. 分析結果をユーザーに提示し、抽出内容の過不足を確認する

## Phase 2: v2 Issue ドラフト作成

1. 以下の構造で v2 Issue のドラフトを作成する:

   ```markdown
   > 詳細な技術検討・議論の経緯は #<元Issue番号> を参照

   ## 背景
   [Issue の動機・解決したい課題を簡潔にまとめる]

   ## 設計判断（確定）
   | # | 判断ポイント | 決定 | 理由 |
   |---|-------------|------|------|
   | 1 | ...         | ...  | ...  |

   ## [ドメイン固有セクション]
   [Issue の内容に応じた具体的なセクション。例: アーキテクチャ、設定、デプロイ手順 等]

   ## フェーズ / アクションアイテム
   - [ ] タスク1
   - [ ] タスク2
   - [ ] ...

   ## スコープ外
   - スコープ外項目1（理由）
   - ...
   ```

2. タイトル: `{元タイトル} v2`
3. 元 Issue のラベルを引き継ぐ（`--label` で指定）

## Phase 3: ユーザーレビュー

1. v2 Issue の全文（タイトル + 本文）をユーザーに提示する
2. AskUserQuestion で次のアクションを確認:
   - 「そのまま作成する」→ Phase 4 へ
   - 「編集してから作成する」→ 編集内容を聞いて反映し、再度レビュー（ループ）
   - 「キャンセルする」→ 何もせず終了
3. 編集ループは最大 5 回まで。それ以上は「現在の内容で作成するか、キャンセルするか」を確認する

## Phase 4: v2 作成 + 元 Issue クローズ

1. `gh issue create` で v2 Issue を作成する:
   ```
   gh issue create --title "{元タイトル} v2" --label "label1,label2" --body "$(cat <<'ISSUE_EOF'
   v2 本文
   ISSUE_EOF
   )"
   ```
   - 本文が 65,536 文字を超える場合は、セクション単位で簡略化して収める
2. 作成された v2 Issue の番号を取得する
3. 元 Issue にクローズコメントを投稿する:
   ```
   gh issue comment <元番号> --body "$(cat <<'CLOSE_EOF'
   Superseded by #<v2番号>。詳細な議論は本 Issue のコメント履歴を参照。
   CLOSE_EOF
   )"
   ```
4. 元 Issue をクローズする:
   ```
   gh issue close <元番号>
   ```
5. ユーザーに完了報告する:
   - v2 Issue の URL
   - 元 Issue のクローズ確認
   - 作成された v2 の概要（セクション数、アクションアイテム数）

## 注意事項

- **リポジトリ非依存**: `gh` CLI の自動検出に依存する。URL 指定時は `--repo` で明示する
- **長文対策**: GitHub Issue 本文上限 65,536 文字。超える場合はセクションを簡略化する
- **Shell エスケープ**: `gh issue create --body` / `gh issue comment --body` には必ず heredoc を使用する
- **ラベル引き継ぎ**: 元 Issue のラベルを `--label` で v2 に付与する。ラベルが存在しない場合はスキップする
- **ロールバック**: v2 作成後にクローズが失敗した場合、v2 の URL を報告し手動クローズを案内する
