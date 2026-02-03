---
name: zsh-startup-analyzer
description: zshの起動時間を分析しボトルネックを特定。「zsh起動を高速化」「シェルが遅い」「zshボトルネック調査」で起動。macOS/Linux両対応。
allowed-tools: Read, Glob, Grep, Bash(bash */analyze-zshrc.sh *), Bash(bash */measure-startup.sh *), Bash(bash */measure-individual.sh *)
---

# zsh起動高速化分析スキル

このスキルはzshの起動時間を自動計測・分析し、ボトルネックを特定します。

## 分析フロー

0. 各種スクリプトの実行
   - `./scripts/` にあるスクリプト群を確認、実行する
     - 実行方法: `bash <Claude skill dir>/scripts/<script-name>.sh [args]`

1. **zshrc構造の把握**
   - ZDOTDIRの確認
   - sourceされているファイル一覧の取得
   - 分割構成の把握

2. **ボトルネック候補の静的解析**
   - `eval`コマンドの使用箇所を検出
   - 外部コマンド呼び出し（`$(...)`, `` `...` ``）を検出
   - `compinit`の呼び出し位置を確認
   - サブシェル起動を検出

3. **起動時間の全体計測**
   - `time zsh -i -c exit`で10回計測して平均値を取得
   - `zprof`による詳細なプロファイリング
   - macOS/Linux両対応

4. **個別処理の時間計測**
   - 各evalコマンドの実行時間を個別に計測
   - compinit、direnv、mise、atuin等の初期化時間を計測
   - OS別の最適化対象を判定

5. **レポート生成**
   - ボトルネック候補の優先順位付き一覧
   - 最適化提案（遅延読み込み、キャッシュ化など）
   - references/内の最適化テクニックを参照

## 使い方

以下のフレーズで起動します：
- 「zsh起動を高速化」
- 「シェルが遅い」
- 「zshのボトルネックを調査」

## 対応環境

| 環境 | 検出対象 |
|------|---------|
| macOS | brew shellenv, mise, atuin |
| Ubuntu | asdf, dircolors |
| 共通 | direnv, starship, compinit |

## 出力例

```
=== zsh起動時間分析レポート ===

【全体計測結果】
平均起動時間: 0.245秒 (10回計測)

【ボトルネック TOP3】
1. eval "$(brew shellenv)" - 約85ms (34.7%)
2. compinit - 約62ms (25.3%)
3. eval "$(starship init zsh)" - 約38ms (15.5%)

【最適化提案】
- brew shellenvをキャッシュ化 → 約80ms短縮
- compinit遅延読み込み → 約60ms短縮
- starshipを非同期初期化 → 約30ms短縮

期待される改善効果: 約170ms (69%短縮)
```

## 参照ドキュメント

- `references/bottleneck-patterns.md` - よくあるボトルネックパターン
- `references/optimization-techniques.md` - 最適化テクニック集
