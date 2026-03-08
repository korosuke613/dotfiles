# Dependabot Cleanup スキル汎用化プラン

## Context

`homepage-2nd/.claude/commands/dependabot-cleanup/` にある Dependabot アラート対応スキルを、リポジトリ非依存の汎用スキルとして `~/.claude/commands/dependabot-cleanup/` に配置する。

現状の homepage-2nd 特化要素:
- `korosuke613 homepage-2nd` のハードコード
- pnpm 限定のコマンド群
- `tools/` ディレクトリ（monorepo ワークスペース）対応
- 検証フェーズ（build-types, lint, test:unit）

## 方針

### 対応エコシステム
- **Node.js**: pnpm 前提（npm/yarn 非対応）
- **Go**: go.mod ベースの依存管理

### 変更サマリー

| 項目 | 現状 | 汎用版 |
|---|---|---|
| owner/repo | ハードコード | `git remote` から自動検出（スクリプト側） |
| エコシステム | pnpm のみ | pnpm + Go（manifest_path で自動判定） |
| tools/ 対応 | あり | 削除 |
| 検証フェーズ | build-types/lint/test:unit | 削除 |
| 配置先 | プロジェクト `.claude/commands/` | `~/.claude/commands/` |

## 実装詳細

### 1. `~/.claude/commands/dependabot-cleanup/SKILL.md`

#### allowed-tools
```
Bash(./scripts/*), Bash(pnpm *), Bash(go get *), Bash(go mod *), Read, Glob, Grep
```

#### Phase 1: アラート一覧取得
- `./scripts/get-open-alerts.sh`（引数なし、git remote から自動検出）

#### Phase 2: 分類
- **manifest_path によるエコシステム判定**:
  - `package.json` / `pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` → Node.js（pnpm）
  - `go.sum` / `go.mod` → Go
- **直接依存の判定**:
  - Node.js: `package.json` の `dependencies` / `devDependencies` を確認
  - Go: `go.mod` の `require` ブロックに `// indirect` がないものが直接依存
- 分類カテゴリは現状通り（A: 直接, B: 推移的上流待ち, C: 環境非該当/低リスク）

#### Phase 3: アップデート（カテゴリ A）

**Node.js (pnpm)**:
- レンジ指定（`^`, `~`）→ `pnpm update <pkg>`
- 固定バージョン → `pnpm add [-D] <pkg>@<target-version>`
- `@latest` 禁止ルールはそのまま

**Go**:
- `go get <module>@<patched-version>`
- `go mod tidy` で整理

#### Phase 4: Dismiss（カテゴリ B, C）
- 現状のスクリプトをそのまま使用（owner/repo 自動検出化のみ）

#### Phase 5: 検証 → 削除

#### Phase 6: 結果レポート
- 現状通り

### 2. スクリプト群の変更

全スクリプトで owner/repo 引数を廃止し、`git remote get-url origin` から自動検出する共通関数を導入。

#### `scripts/detect-repo.sh`（新規）
```bash
# git remote get-url origin をパースして OWNER と REPO を export
# HTTPS: https://github.com/owner/repo.git
# SSH: git@github.com:owner/repo.git
```

#### 既存スクリプトの変更
- `get-open-alerts.sh`: 引数廃止 → `source detect-repo.sh`
- `dismiss-alert.sh`: owner/repo 引数廃止 → `source detect-repo.sh`、残りの引数（alert_number, reason, comment）は維持
- `dismiss-alerts-batch.sh`: 同上（alert_numbers, reason, comment）
- `get-alert-detail.sh`: owner/repo 引数廃止 → `source detect-repo.sh`、alert_number は維持

### 3. `references/api-notes.md`
- 現状のまま（すでにリポジトリ非依存の内容）
- Go エコシステム向けの注意事項を追記:
  - `go get` でのバージョン指定方法
  - `// indirect` 依存の扱い

## ファイル構成

```
~/.claude/commands/dependabot-cleanup/
├── SKILL.md
├── scripts/
│   ├── detect-repo.sh      # 新規: owner/repo 自動検出
│   ├── get-open-alerts.sh   # 改修: 引数廃止
│   ├── get-alert-detail.sh  # 改修: 引数廃止
│   ├── dismiss-alert.sh     # 改修: owner/repo引数廃止
│   └── dismiss-alerts-batch.sh  # 改修: owner/repo引数廃止
└── references/
    └── api-notes.md         # Go向け追記
```

## 検証方法

1. 任意の GitHub リポジトリで `./scripts/get-open-alerts.sh` を実行し、owner/repo が正しく自動検出されることを確認
2. `./scripts/get-alert-detail.sh <number>` でアラート詳細が取得できることを確認
3. Claude Code から `/dependabot-cleanup` でスキルが認識されることを確認
