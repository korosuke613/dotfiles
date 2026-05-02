---
name: issue-discuss
description: "GitHub Issueの調査・意思決定ワークフロー。Issueを読み込み、関連トピックを調査してコメント投稿し、未決定の判断ポイントをQ&A形式で意思決定し、決定サマリーをコメント投稿する。「issueを議論して」「issueの意思決定」で起動。"
argument-hint: "[issue-number or URL]"
disable-model-invocation: false
allowed-tools: "Bash(gh issue view:*), Bash(gh api:*), Bash(gh issue comment:*), Read, Grep, Glob, WebSearch, WebFetch, AskUserQuestion, Task"
---

# /issue-discuss — Issue 調査・意思決定ワークフロー

GitHub Issue を読み込み、関連トピックを調査してコメント投稿し、未決定の判断ポイントを Q&A 形式で意思決定し、決定サマリーをコメント投稿するワークフロー。

## Phase 0: 入力パース・検証

1. `$ARGUMENTS` を解析する
   - **数字のみ**（例: `42`）→ Issue 番号として扱う。`gh` が git remote から自動検出する
   - **GitHub URL**（例: `https://github.com/owner/repo/issues/42`）→ owner/repo/number をパースし、以降の `gh` コマンドに `--repo owner/repo` を付与する
   - **空・不正値** → エラーメッセージを出して終了する
2. `gh issue view <number> --json title,body,state,labels` で存在確認
   - Issue が存在しない → エラーで終了
   - state が `CLOSED` → 「この Issue はクローズ済みです。続行しますか？」と AskUserQuestion で確認

## Phase A: Issue とコメントの読み込み

1. `gh issue view <number> --json title,body,state,labels,comments` で全情報取得
2. 取得した内容を分析し、ユーザーに現状サマリーを提示:
   - Issue タイトルと概要（1-2 行）
   - 既存コメント数と議論の概況
   - 何が議論済みで何が未決かの概観
3. ユーザーに「Phase B（調査）に進むか」を確認する

## Phase B: 関連トピックの調査

1. Issue 本文・コメントで言及されたトピック・ツール・ライブラリ・サービスを特定する
2. 以下の手段で調査する:
   - **コードベース調査**: Glob, Grep, Read で既存の関連コードや設定を探索
   - **外部調査**: WebSearch, WebFetch で公式ドキュメント、比較記事、ベストプラクティスを調査
   - **深掘り調査**: 必要に応じて Task（Explore エージェント）でコードベースを広範に調査
3. 調査結果をまとめてユーザーに提示する（見出し付き、箇条書き）
4. AskUserQuestion で次のアクションを確認:
   - 「コメントとして投稿する」
   - 「追加調査する（トピック指定）」
   - 「調査をスキップして意思決定に進む」

## Phase C: 調査結果のコメント投稿

1. 構造化されたコメントを作成する:
   - 見出し: `## 調査結果（YYYY-MM-DD）`
   - セクション分け（比較テーブル、コード例、参考リンク等を適宜使用）
   - 情報ソースの明記
2. コメント全文をユーザーにプレビュー表示する
3. AskUserQuestion: 「このまま投稿 / 編集してから投稿 / 投稿しない」
4. 承認後に `gh issue comment <number> --body` で投稿する
   - コメント本文は heredoc を使用してシェルエスケープ問題を回避する:
     ```
     gh issue comment <number> --body "$(cat <<'COMMENT_EOF'
     コメント本文
     COMMENT_EOF
     )"
     ```
   - 65,536 文字を超える場合は分割投稿する

## Phase D: 判断ポイントの特定

1. Issue 本文 + 全コメントから未決事項を抽出する。抽出のシグナル:
   - `?` で終わる文
   - 「要検討」「判断ポイント」「選択肢」「TBD」「TODO」「未決」等のキーワード
   - 決定済みマーク（`[x]`、「決定:」）のない比較テーブルや選択肢リスト
2. 番号付きリストでユーザーに提示する
3. AskUserQuestion で調整を確認:
   - 判断ポイントの追加・削除・並べ替え
   - 不要な項目の除外

## Phase E: Q&A 意思決定

1. Phase D で確定した判断ポイントを順番に処理する
2. 各判断ポイントについて AskUserQuestion を実行:
   - 質問文: 判断ポイントの背景・トレードオフを簡潔に説明
   - 選択肢: 2-4 の具体的オプション（推奨を先頭に「(Recommended)」付きで配置）
   - 各選択肢に description でメリット/デメリットを記載
3. 全決定完了後にサマリーテーブルを作成:
   ```
   | # | 判断ポイント | 決定 | 理由 |
   |---|-------------|------|------|
   | 1 | ...         | ...  | ...  |
   ```
4. ユーザーに最終確認を求める

## Phase F: 決定サマリーのコメント投稿

1. 以下の形式でコメントを作成:
   ```markdown
   ## 設計判断サマリ（YYYY-MM-DD 議論結果）

   | # | 判断ポイント | 決定 | 理由 |
   |---|-------------|------|------|
   | 1 | ...         | ...  | ...  |

   ### 次のアクション
   - [ ] アクション項目1
   - [ ] アクション項目2
   ```
2. ユーザーにプレビュー表示する
3. AskUserQuestion: 「このまま投稿 / 編集してから投稿 / 投稿しない」
4. 承認後に `gh issue comment` で投稿する（heredoc 使用）
5. 完了報告をユーザーに行う

## 注意事項

- **リポジトリ非依存**: `gh` CLI の自動検出に依存する。URL 指定時は `--repo` で明示する
- **長文コメント**: GitHub コメント上限 65,536 文字。超える場合は分割投稿する
- **Shell エスケープ**: `gh issue comment --body` には必ず heredoc を使用する
- **中断耐性**: 途中中断しても、投稿済みコメントは残るため再開可能
- **各 Phase の進行**: Phase 間でユーザー確認を挟み、スキップや順序変更に対応する
