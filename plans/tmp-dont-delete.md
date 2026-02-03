# zsh起動高速化 分析計画

## 目的
zshシェルの起動時間を計測・分析し、ボトルネックを数値で特定する。

---

## 実施内容

### Step 1: ベースライン取得

起動時間の現状を計測する。

```bash
for i in {1..10}; do (time zsh -i -c exit) 2>&1; done
```

### Step 2: zprof 有効化

`.zshrc` を編集してプロファイラを有効化する。

**変更箇所:**
- 行2: `# zmodload zsh/zprof` → `zmodload zsh/zprof` （コメント解除）
- 末尾に `zprof` を追加

### Step 3: プロファイル結果の取得

新しいシェルを起動してzprofの出力を取得・分析する。

```bash
zsh -i -c exit 2>&1 | head -50
```

### Step 4: 個別処理の時間計測

zprofでは捉えにくい `eval` や外部コマンドの時間を個別計測するスクリプトを作成・実行する。

計測対象:
| 処理 | ファイル:行 |
|------|------------|
| brew shellenv (1回目) | `.zshrc:14` |
| brew shellenv (2回目/重複) | `.zshrc:135` |
| $(brew --prefix) x3 | `.zshrc.gcp:4,5`, `.zshrc.autocomplete:12` |
| direnv hook zsh | `.zshrc:35` |
| starship init zsh | `.zshrc:54` |
| go env GOPATH | `.zshrc:89` |
| atuin init zsh | `.zshrc:107` |
| mise activate | `.zshrc:116` |
| compinit | `.zshrc.autocomplete:14` |

### Step 5: 分析レポート作成

計測結果をまとめ、ボトルネックの優先順位を確定する。

---

## コード調査で判明している問題点（参考）

| 問題 | 箇所 | 推定影響 |
|------|------|---------|
| brew shellenv 重複 | `.zshrc` 行14, 135 | 50-100ms |
| alias 重複 | `.zshrc` 行10-12, 137-139 | 微小 |
| $(brew --prefix) 3回呼出 | `.zshrc.gcp` 行4,5 / `.zshrc.autocomplete` 行12 | 100-200ms |
| compinit 毎回フルスキャン | `.zshrc.autocomplete` 行14 | 100-300ms |
| go env GOPATH 毎回実行 | `.zshrc` 行89 | 20-50ms |
| eval x 4箇所 | direnv(35), starship(54), atuin(107), mise(116) | 各50-150ms |

---

## 成果物

- 起動時間のベースライン数値
- zprofプロファイル結果
- 個別処理の時間計測結果
- ボトルネック優先順位リスト（改善検討用）
