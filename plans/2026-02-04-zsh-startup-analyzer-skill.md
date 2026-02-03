# zsh起動高速化分析スキル作成

## 目的
dotfiles高速化のための分析を自動化するClaude Skillを作成する。

---

## 作成するスキル

### スキル名
`zsh-startup-analyzer`

### 起動トリガー
- 「zsh起動を高速化」
- 「シェルが遅い」
- 「zshのボトルネックを調査」

---

## ディレクトリ構造

```
mac/claude/skills/zsh-startup-analyzer/
├── SKILL.md                    # スキル定義
├── scripts/
│   ├── analyze-zshrc.sh        # zshrc構造解析
│   ├── measure-startup.sh      # 起動時間計測
│   └── measure-individual.sh   # 個別処理時間計測
└── references/
    ├── bottleneck-patterns.md  # ボトルネックパターン集
    └── optimization-techniques.md  # 最適化テクニック集
```

---

## 実装内容

### 1. SKILL.md

```yaml
---
name: zsh-startup-analyzer
description: zshの起動時間を分析しボトルネックを特定。「zsh起動を高速化」「シェルが遅い」「zshボトルネック調査」で起動。macOS/Linux両対応。
allowed-tools: Read, Glob, Grep, Bash(bash */analyze-zshrc.sh:*), Bash(bash */measure-startup.sh:*), Bash(bash */measure-individual.sh:*)
---
```

本文には以下の分析フローを記載：
1. zshrc構造の自動検出
2. ボトルネック候補の静的解析
3. 起動時間の全体計測（time, zprof）
4. 個別処理の時間計測
5. レポート生成

### 2. scripts/analyze-zshrc.sh
- zshrcファイルの場所を自動検出（ZDOTDIR対応）
- sourceされているファイル一覧を出力
- ボトルネック候補（eval, compinit, サブシェル等）を検出

### 3. scripts/measure-startup.sh
- 基本計測（10回平均）
- zprof詳細計測
- macOS/Linux両対応

### 4. scripts/measure-individual.sh
- 各eval/外部コマンドの個別時間計測
- OS検出して適切なコマンドを実行
- brew shellenv, starship, direnv, mise, atuin, compinit等

### 5. references/
- bottleneck-patterns.md: 高/中/低影響のパターン解説
- optimization-techniques.md: compinit最適化、evalキャッシュ化、遅延読み込み等

---

## セットアップ

### setup.sh への追加

```sh
# skills
mkdir -p ~/.claude/skills
ln -sf ~/dotfiles/mac/claude/skills/zsh-startup-analyzer ~/.claude/skills/zsh-startup-analyzer
```

---

## 対応環境

| 環境 | 検出対象 |
|------|---------|
| macOS | brew shellenv, mise, atuin |
| Ubuntu | asdf, dircolors |
| 共通 | direnv, starship, compinit |

---

## 修正対象ファイル

| ファイル | 操作 |
|----------|------|
| `mac/claude/skills/zsh-startup-analyzer/SKILL.md` | 新規作成 |
| `mac/claude/skills/zsh-startup-analyzer/scripts/analyze-zshrc.sh` | 新規作成 |
| `mac/claude/skills/zsh-startup-analyzer/scripts/measure-startup.sh` | 新規作成 |
| `mac/claude/skills/zsh-startup-analyzer/scripts/measure-individual.sh` | 新規作成 |
| `mac/claude/skills/zsh-startup-analyzer/references/bottleneck-patterns.md` | 新規作成 |
| `mac/claude/skills/zsh-startup-analyzer/references/optimization-techniques.md` | 新規作成 |
| `mac/claude/setup.sh` | skills用シンボリックリンク追加 |

---

## 検証方法

1. `./mac/claude/setup.sh` を実行してシンボリックリンクを作成
2. Claude Codeで「zsh起動を高速化して」と入力
3. スキルが起動し、分析フローが実行されることを確認
4. 各スクリプトが正常に動作することを確認
