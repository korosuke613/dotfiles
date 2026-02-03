---
name: zsh-startup-analyzer
description: zshの起動時間を分析しボトルネックを特定。「zsh起動を高速化」「シェルが遅い」「zshボトルネック調査」で起動。macOS/Linux両対応。
allowed-tools: Read, Glob, Grep, Bash(bash */zsh-startup-analyzer/scripts/*)
---

# zsh起動高速化分析スキル

このスキルはzshの起動時間を自動計測・分析し、ボトルネックを特定します。

## 関連ファイル
- `scripts/analyze-zshrc.sh`: zshrc構造の静的解析スクリプト
- `scripts/measure-startup.sh`: zsh起動時間計測スクリプ
- `scripts/measure-individual.sh`: 個別処理時間計測スクリプト
- `scripts/compare-before-after.sh`: 最適化前後の比較スクリプト
- `references/bottleneck-patterns.md` - よくあるボトルネックパターン
- `references/optimization-techniques.md` - 最適化テクニック集

## 分析フロー

0. 各種スクリプトの実行
   - `./scripts/` にあるスクリプト群を確認、実行する
     - 実行方法: `bash <Claude skill dir>/scripts/<script-name>.sh [args]`

1. **zshrc構造の把握**
   - ZDOTDIRの確認
   - sourceされているファイル一覧の取得（**再帰的に取得**）
   - 分割構成の把握

2. **ボトルネック候補の静的解析**
   - `eval`コマンドの使用箇所を検出
   - 外部コマンド呼び出し（`$(...)`, `` `...` ``）を検出
   - `compinit`の呼び出し位置を確認（**source先ファイルも含む**）
   - サブシェル起動を検出
   - **🆕 NEW**: `compinit`の重複呼び出しを自動検出
   - **🆕 NEW**: `eval`と`alias`の重複を自動検出

3. **起動時間の全体計測**
   - `time zsh -i -c exit`で10回計測して平均値を取得
   - `zprof`による詳細なプロファイリング
   - **🆕 NEW**: `calls > 1` の関数を自動検出（重複呼び出し警告）
   - macOS/Linux両対応

4. **個別処理の時間計測**
   - 各evalコマンドの実行時間を個別に計測
   - compinit、direnv、mise、atuin等の初期化時間を計測
   - OS別の最適化対象を判定

5. **レポート生成**
   - ボトルネック候補の優先順位付き一覧
   - 最適化提案（遅延読み込み、キャッシュ化など）
   - references/内の最適化テクニックを参照

6. **🆕 Before/After比較（オプション）**
   - 最適化前後の起動時間を定量比較
   - 改善率と削減時間を自動計算
   - 高速化の倍率を表示

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

## 🆕 新機能の使い方

### Before/After 比較

最適化の効果を定量的に測定できます：

```bash
# 1. 最適化前の計測
bash scripts/compare-before-after.sh before

# 2. 最適化を実施（.zshrc の編集等）

# 3. 最適化後の計測と比較
bash scripts/compare-before-after.sh after

# 保存済みの結果を再表示
bash scripts/compare-before-after.sh compare
```

### compinit 重複検出

`analyze-zshrc.sh` が自動的に検出します：
- source先ファイル内の compinit 呼び出し
- 複数箇所での compinit 実行（重複警告）

### 重複コード検出

同一の eval や alias が複数ファイルに存在する場合に警告します。

