# Issue ライフサイクル管理スキルの作成

## Context

Issue #4 → #5 で行った「調査情報の収集 → Q&A 形式の意思決定 → コンパクト化した v2 Issue 作成」のワークフローを、再利用可能な Claude Code スキルとして定義する。

今回のワークフローの実績:
1. Issue を読み込み、関連トピック（Headlamp Flux プラグイン）を調査してコメント投稿
2. 未決定の判断ポイント（Secret 管理、ノード配置、タグ戦略等）を AskUserQuestion で一問一答
3. 決定サマリーをコメント投稿
4. 全情報を集約した v2 Issue を作成し、元 Issue をクローズ

## 作成するスキル

| スキル | 用途 | 配置先 |
|--------|------|--------|
| `/issue-discuss` | Issue の調査 + Q&A 意思決定 | `~/.claude/skills/issue-discuss/SKILL.md` |
| `/issue-compact` | Issue のコンパクト化（v2 作成 + 元 Issue クローズ） | `~/.claude/skills/issue-compact/SKILL.md` |

両方 `disable-model-invocation: true`（手動起動のみ、副作用あるため）。

## 実装ステップ

### Step 1: ディレクトリ作成

```
~/.claude/skills/
├── issue-discuss/
│   └── SKILL.md
└── issue-compact/
    └── SKILL.md
```

`~/.claude/skills/` は現在存在しないため新規作成。

### Step 2: `/issue-discuss` SKILL.md 作成

**ファイル**: `~/.claude/skills/issue-discuss/SKILL.md`

**frontmatter**:
```yaml
---
name: issue-discuss
description: GitHub Issueの調査・意思決定ワークフロー。Issueを読み込み、関連トピックを調査してコメント投稿し、未決定の判断ポイントをQ&A形式で意思決定し、決定サマリーをコメント投稿する。「issueを議論して」「issueの意思決定」で起動。
argument-hint: "[issue-number or URL]"
disable-model-invocation: true
allowed-tools: Bash(gh issue view:*), Bash(gh api:*), Bash(gh issue comment:*), Read, Grep, Glob, WebSearch, WebFetch, AskUserQuestion, Task
---
```

**ワークフロー（6フェーズ）**:

- **Phase 0: 入力パース・検証**
  - `$ARGUMENTS` を Issue 番号 or GitHub URL として解析
  - 番号のみ → `gh` が git remote から自動検出
  - URL → owner/repo/number をパースし `--repo` で指定
  - `gh issue view` で存在確認・状態チェック（クローズ済みなら警告）

- **Phase A: Issue とコメントの読み込み**
  - `gh issue view <number> --json title,body,state,labels,comments` で全情報取得
  - 現状サマリーをユーザーに提示（何が議論済みで何が未決か）

- **Phase B: 関連トピックの調査**
  - Issue 内で言及されたトピック・ツール・ライブラリを特定
  - コードベース調査（Glob, Grep, Read）+ 外部調査（WebSearch, WebFetch）
  - 調査結果をまとめてユーザーに提示
  - AskUserQuestion で「投稿するか / 追加調査するか / スキップするか」を確認

- **Phase C: 調査結果のコメント投稿**
  - 構造化されたコメント（見出し、比較テーブル、コード例）を作成
  - ユーザーにプレビュー表示 → 承認後に `gh issue comment` で投稿

- **Phase D: 判断ポイントの特定**
  - Issue 本文 + 全コメントから未決事項を抽出（`?` で終わる行、「要検討」「判断ポイント」「選択肢」等のキーワード、決定済みマークのない比較テーブル）
  - 番号付きリストでユーザーに提示
  - AskUserQuestion で追加・削除・並べ替えを確認

- **Phase E: Q&A 意思決定**
  - 確定した判断ポイントごとに AskUserQuestion で一問一答
  - 各質問に 2-4 の具体的選択肢（推奨を先頭に配置）
  - 全決定完了後にサマリーテーブルを作成

- **Phase F: 決定サマリーのコメント投稿**
  - 「## 設計判断サマリ（YYYY-MM-DD 議論結果）」形式のコメント
  - テーブル: 判断ポイント | 決定 | 理由
  - 次のアクション項目
  - ユーザーにプレビュー → 承認後に投稿

### Step 3: `/issue-compact` SKILL.md 作成

**ファイル**: `~/.claude/skills/issue-compact/SKILL.md`

**frontmatter**:
```yaml
---
name: issue-compact
description: GitHub Issueのコンパクト化。Issueとすべてのコメントを読み込み、背景・確定した設計判断・アクションアイテムを集約したv2 Issueを作成し、元のIssueをクローズする。「issueをコンパクトに」「issue整理」で起動。
argument-hint: "[issue-number or URL]"
disable-model-invocation: true
allowed-tools: Bash(gh issue view:*), Bash(gh api:*), Bash(gh issue comment:*), Bash(gh issue create:*), Bash(gh issue close:*), Read, AskUserQuestion
---
```

**ワークフロー（4フェーズ）**:

- **Phase 0: 入力パース・検証**
  - issue-discuss と同じパースロジック

- **Phase 1: 読み込みと分析**
  - `gh issue view <number> --json title,body,state,labels,comments` で全取得
  - 抽出対象: 背景/動機、確定済み判断、未解決項目、アクションアイテム、スコープ外

- **Phase 2: v2 Issue ドラフト作成**
  - 構造: `## 背景` → `## 設計判断（確定）` → `## ドメイン固有セクション` → `## フェーズ/アクションアイテム` → `## Scope外`
  - タイトル: `{元タイトル} v2`
  - 元 Issue ラベルを引き継ぎ
  - 元 Issue への参照: `> 詳細な技術検討・議論の経緯は #XX を参照`

- **Phase 3: ユーザーレビュー**
  - v2 全文をユーザーに提示
  - AskUserQuestion: 「そのまま作成 / 編集してから作成 / キャンセル」
  - 編集要求があれば反映して再提示（ループ）

- **Phase 4: v2 作成 + 元 Issue クローズ**
  - `gh issue create --title "..." --body "..."` で v2 作成
  - 元 Issue にクローズコメント: `Superseded by #XX。詳細な議論は本 Issue のコメント履歴を参照。`
  - `gh issue close <original>` でクローズ
  - 新 Issue URL をユーザーに報告

## 設計上の注意点

- **リポジトリ非依存**: `gh` CLI の自動検出に依存。URL 指定時は `--repo` で明示
- **長文コメント**: GitHub コメント上限 65,536 文字。超える場合は分割投稿
- **Shell エスケープ**: `gh issue comment --body` には heredoc を使用
- **中断耐性**: issue-discuss で途中中断しても、投稿済みコメントは残るため再開可能

## 検証方法

1. `~/.claude/skills/` が認識されることを確認
   - Claude Code で `/issue-discuss` がスキル一覧に表示されるか
2. テスト用 Issue を作成して `/issue-discuss <number>` を実行
   - Phase A-F が正しく動作するか
   - コメントが正しく投稿されるか
3. 議論済み Issue に対して `/issue-compact <number>` を実行
   - v2 Issue が正しく作成されるか
   - 元 Issue がクローズされるか
