---
name: dependabot-cleanup
description: Dependabotアラートを一括で分析・対応する。直接依存はアップデートし、推移的依存はdismissする。Node.js（pnpm）とGoに対応。
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/*), Bash(pnpm *), Bash(go *), Read, Glob, Grep, AskUserQuestion
---

# Dependabot アラートお掃除スキル

## 重要: GitHub API直接呼び出しの禁止

以下のコマンドは絶対に使用しないこと：

```bash
# 禁止: gh api を直接使用
gh api /repos/{owner}/{repo}/dependabot/alerts
gh api --method PATCH /repos/{owner}/{repo}/dependabot/alerts/{number}

# 代わりに: 必ず scripts/ 配下のスクリプトを使用する
${CLAUDE_SKILL_DIR}/scripts/get-open-alerts.sh
${CLAUDE_SKILL_DIR}/scripts/dismiss-alert.sh 123 tolerable_risk "reason"
```

## 実行フロー

### Phase 1: アラート一覧取得

```bash
${CLAUDE_SKILL_DIR}/scripts/get-open-alerts.sh
```

owner/repo は git remote origin から自動検出される。
出力されるJSON配列から全オープンアラートを把握する。

### Phase 2: 分類

各アラートを以下の手順で分類する：

1. **エコシステム判定**（manifest_path / ecosystem フィールドから）
   - `package.json` / `pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` → **Node.js**
   - `go.sum` / `go.mod` → **Go**

2. **直接依存か推移的依存かの判定**
   - **Node.js**: 該当 `package.json` を Read ツールで読み、`dependencies` / `devDependencies` にパッケージ名が存在するか確認
   - **Go**: `go.mod` を Read ツールで読み、`require` ブロック内で `// indirect` コメントがないものが直接依存

3. **推移的依存の依存元調査**（カテゴリB候補に対して実施）
   - **Node.js**: `pnpm why <vulnerable-pkg>` で依存元の直接パッケージを特定する
   - **Go**: `go mod graph | grep <vulnerable-module>` で依存元を特定する
   - 依存元の直接パッケージごとに、最新バージョンで脆弱な推移的依存が解消されるかを確認する
     - `pnpm info <parent-pkg> version` で最新版を確認
     - 最新版にアップデートすれば解消する可能性がある場合、カテゴリ B1 に分類する

4. **分類カテゴリ**
   - **A. 直接アップデート可能**: 依存定義ファイルに直接記載されている脆弱パッケージ
   - **B1. 依存元アップデートで解消可能性あり**: 推移的依存だが、依存元の直接パッケージをアップデートすれば解消する可能性がある。依存元パッケージ名・現在バージョン・最新バージョン・メジャーアップかどうかを明記する
   - **B2. 推移的依存（上流待ち）**: 依存元をアップデートしても解消しない、または依存元のアップデートにリスクが大きい
   - **C. 環境非該当/リスク低**: OS限定脆弱性やdevDependency限定で影響軽微

分類結果をテーブル形式でユーザーに提示する。カテゴリ B1 のテーブルには以下の列を含めること：

| # | 脆弱パッケージ | 依存元（直接依存） | 現バージョン | 最新バージョン | メジャーアップ | 備考 |

方針の確認には **AskUserQuestion ツール** を使い、選択肢を提示すること。

### Phase 3: アップデート（カテゴリA, B1）

**AskUserQuestion** でアップデート対象と方針の最終確認をユーザーに求めてから実行する。
特にカテゴリ B1 はメジャーバージョンアップを伴う場合があるため、リスクを明示した上で選択肢を提示すること。

#### Node.js (pnpm)

| package.jsonの記法 | 手段 |
|---|---|
| `"^1.0.0"` / `"~1.0.0"` （レンジ指定） | `pnpm update <pkg>` |
| `"1.2.3"` （固定バージョン） | `pnpm add [-D] <pkg>@<target-version>` |

**注意事項**:
- `@latest` は絶対に使わない。メジャーバージョンが上がりピアデペンデンシーが崩壊する
- `first_patched_version` を参照し最小限のバージョンアップに留める（`${CLAUDE_SKILL_DIR}/scripts/get-alert-detail.sh` で取得可能）
- 同一エコシステムのパッケージ群（例: storybook + @storybook/addon-*）はバージョンを揃える
- **カテゴリ B1（依存元アップデート）**: 依存元の直接パッケージをアップデートした後、`pnpm why <vulnerable-pkg>` で推移的依存が実際に解消されたか検証する。解消されなかった場合はカテゴリ B2 に再分類して dismiss する

#### Go

```bash
go get <module>@v<patched-version>
go mod tidy
```

**注意事項**:
- `@latest` は使わない。`first_patched_version` で指定する
- `go mod tidy` で不要な依存を整理する
- 推移的依存は `go get` で直接更新できない場合がある。上流モジュールの更新を待つ

### Phase 4: Dismiss（カテゴリB2, C）

dismissするアラートの一覧をテーブル形式でユーザーに提示し、**AskUserQuestion で承認を得てから**実行する。

```bash
# 単一dismiss
${CLAUDE_SKILL_DIR}/scripts/dismiss-alert.sh 123 tolerable_risk "Transitive dependency via textlint. Awaiting upstream update."

# 一括dismiss（同一理由で複数アラート）
${CLAUDE_SKILL_DIR}/scripts/dismiss-alerts-batch.sh "89 90 96 97" tolerable_risk "Transitive dependency. Awaiting upstream update."
```

### Phase 5: 結果レポート

対応結果をテーブル形式でサマリー表示：

| カテゴリ | 件数 | アラート番号 |
|---|---|---|
| A. 直接アップデートで解決 | N件 | #xxx, #yyy |
| B1. 依存元アップデートで解決 | N件 | #xxx, #yyy |
| B2. dismiss済み（推移的依存・上流待ち） | N件 | #xxx, #yyy |
| C. dismiss済み（環境非該当/リスク低） | N件 | #xxx, #yyy |
| 残存（push後に自動クローズ予定） | N件 | #xxx, #yyy |

## リファレンス

API仕様の詳細や実戦で判明した落とし穴については `${CLAUDE_SKILL_DIR}/references/api-notes.md` を参照すること。
