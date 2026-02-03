# zsh起動最適化テクニック集

具体的な最適化手法とコード例を紹介します。

---

## 🚀 高速化の基本原則

1. **遅延読み込み（Lazy Loading）**: 初回使用時まで初期化を遅延
2. **キャッシュ化**: 変化しない結果を保存して再利用
3. **条件付き実行**: 必要な時だけ実行
4. **非同期初期化**: バックグラウンドで初期化
5. **不要な処理の削除**: 使っていない機能は無効化

---

## 1. evalキャッシュ化

### 対象
- `brew shellenv`
- `mise activate`
- `starship init`
- その他の`eval`コマンド

### Before（遅い）
```zsh
eval "$(brew shellenv)"
```

### After（速い）
```zsh
# キャッシュファイルのパス
BREW_SHELLENV_CACHE="$HOME/.cache/zsh/brew_shellenv.zsh"

# キャッシュが1日以上古いか存在しない場合は再生成
if [[ ! -f "$BREW_SHELLENV_CACHE" ]] || [[ $(find "$BREW_SHELLENV_CACHE" -mtime +1 2>/dev/null | wc -l) -gt 0 ]]; then
    mkdir -p "$(dirname "$BREW_SHELLENV_CACHE")"
    brew shellenv > "$BREW_SHELLENV_CACHE"
fi

# キャッシュを読み込み（evalより高速）
source "$BREW_SHELLENV_CACHE"
```

### 効果
- **80-150ms → 5-10ms** (約90%短縮)

---

## 2. compinit最適化

### 方法A: 1日1回だけ実行

```zsh
# compdumpファイルのパス
COMPDUMP="$HOME/.zcompdump"

# 1日1回だけcompinit実行
autoload -Uz compinit
if [[ -n $COMPDUMP(#qN.mh+24) ]]; then
    # 24時間以上経過している場合のみ再生成
    compinit
else
    # キャッシュを使用（チェックスキップ）
    compinit -C
fi
```

### 方法B: バックグラウンドでチェック

```zsh
autoload -Uz compinit

# 即座に-Cでキャッシュ使用
compinit -C

# バックグラウンドでcompdumpを更新
{
    if [[ -n $HOME/.zcompdump(#qN.mh+24) ]]; then
        compinit
    fi
} &!
```

### 効果
- **60-200ms → 10-30ms** (約80%短縮)

---

## 3. mise/asdf最適化

### mise（推奨）
miseはasdfより高速ですが、さらに最適化可能：

```zsh
# キャッシュを使用
MISE_CACHE="$HOME/.cache/zsh/mise.zsh"

if [[ ! -f "$MISE_CACHE" ]] || [[ $(find "$MISE_CACHE" -mtime +7 2>/dev/null | wc -l) -gt 0 ]]; then
    mkdir -p "$(dirname "$MISE_CACHE")"
    mise activate zsh > "$MISE_CACHE"
fi

source "$MISE_CACHE"
```

### asdf（レガシー）
```zsh
# 遅延読み込み版
mise() {
    unfunction mise
    source "$HOME/.asdf/asdf.sh"
    mise "$@"
}
```

### 効果
- **50-100ms → 5-15ms** (約85%短縮)

---

## 4. starship最適化

### 方法A: キャッシュ化

```zsh
STARSHIP_CACHE="$HOME/.cache/zsh/starship.zsh"

if [[ ! -f "$STARSHIP_CACHE" ]] || [[ $(find "$STARSHIP_CACHE" -mtime +7 2>/dev/null | wc -l) -gt 0 ]]; then
    mkdir -p "$(dirname "$STARSHIP_CACHE")"
    starship init zsh > "$STARSHIP_CACHE"
fi

source "$STARSHIP_CACHE"
```

### 方法B: 非同期初期化

```zsh
# 一時的にシンプルなプロンプトを設定
PS1="%~ %# "

# バックグラウンドでstarship初期化
{
    eval "$(starship init zsh)"
} &!
```

### 効果
- **30-50ms → 5-10ms** (約80%短縮)

---

## 5. direnv最適化

### キャッシュ化

```zsh
DIRENV_CACHE="$HOME/.cache/zsh/direnv.zsh"

if [[ ! -f "$DIRENV_CACHE" ]] || [[ $(find "$DIRENV_CACHE" -mtime +7 2>/dev/null | wc -l) -gt 0 ]]; then
    mkdir -p "$(dirname "$DIRENV_CACHE")"
    direnv hook zsh > "$DIRENV_CACHE"
fi

source "$DIRENV_CACHE"
```

### 効果
- **20-40ms → 5-10ms** (約75%短縮)

---

## 6. プラグイン遅延読み込み

### zinit/sheldon向け

```zsh
# 即座に必要なもの（シンタックスハイライト等）
zinit light zsh-users/zsh-syntax-highlighting

# 遅延読み込み（初回コマンド実行時）
zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

zinit ice wait lucid
zinit light zsh-users/zsh-completions
```

### 手動実装

```zsh
# fzf遅延読み込みの例
fzf-lazy-load() {
    unfunction fzf fzf-lazy-load 2>/dev/null
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    fzf "$@"
}

# エイリアス
alias fzf='fzf-lazy-load'
```

### 効果
- **プラグイン1つあたり10-30ms短縮**

---

## 7. 条件付き読み込み

### コマンド存在確認を効率化

```zsh
# Before（遅い）
if type brew &>/dev/null; then
    eval "$(brew shellenv)"
fi

# After（速い）- brewの存在は基本的に変わらないため
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
```

### 環境別の分岐

```zsh
# OSごとにファイルを分離
case "$OSTYPE" in
    darwin*)
        source ~/.zshrc.macos
        ;;
    linux*)
        source ~/.zshrc.linux
        ;;
esac
```

---

## 8. 統合最適化テンプレート

全ての最適化を組み合わせた例：

```zsh
# キャッシュディレクトリ
ZSH_CACHE_DIR="$HOME/.cache/zsh"
mkdir -p "$ZSH_CACHE_DIR"

# Homebrewキャッシュ（1日ごと）
_cache_eval() {
    local cache_file="$ZSH_CACHE_DIR/$1.zsh"
    local max_age="${3:-7}" # デフォルト7日

    if [[ ! -f "$cache_file" ]] || [[ $(find "$cache_file" -mtime +$max_age 2>/dev/null | wc -l) -gt 0 ]]; then
        eval "$2" > "$cache_file"
    fi
    source "$cache_file"
}

# 使用例
_cache_eval "brew_shellenv" "brew shellenv" 1
_cache_eval "mise_activate" "mise activate zsh" 7
_cache_eval "starship_init" "starship init zsh" 7
_cache_eval "direnv_hook" "direnv hook zsh" 7

# compinit（1日1回）
autoload -Uz compinit
if [[ -n $HOME/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
```

---

## 9. 計測と検証

### Before/Afterの確認

```zsh
# 最適化前
time zsh -i -c exit

# 最適化後
time zsh -i -c exit

# 差分を確認
```

### 継続的な監視

```zsh
# .zshrc の最後に追加（開発時のみ）
# 起動時間を記録
if [[ -n $ZSH_PROFILE ]]; then
    zmodload zsh/zprof
    zprof
fi
```

使い方：
```bash
ZSH_PROFILE=1 zsh -i -c exit
```

---

## 10. キャッシュ管理

### キャッシュクリアスクリプト

```zsh
# ~/.zshrc に追加
alias zsh-cache-clear='rm -rf ~/.cache/zsh/*.zsh && echo "zshキャッシュをクリアしました"'
alias zsh-cache-rebuild='zsh-cache-clear && exec zsh'
```

### 自動キャッシュ更新

Brewfileやmise設定が変更されたら自動的にキャッシュを無効化：

```zsh
# Brewfile更新時にキャッシュクリア
if [[ ~/Brewfile -nt $ZSH_CACHE_DIR/brew_shellenv.zsh ]]; then
    rm -f $ZSH_CACHE_DIR/brew_shellenv.zsh
fi
```

---

## 📊 期待される改善効果

| 項目 | Before | After | 削減率 |
|------|--------|-------|--------|
| brew shellenv | 120ms | 8ms | 93% |
| compinit | 150ms | 20ms | 87% |
| mise | 80ms | 10ms | 88% |
| starship | 40ms | 8ms | 80% |
| direnv | 30ms | 8ms | 73% |
| **合計** | **420ms** | **54ms** | **87%** |

---

## ⚠️ 注意事項

1. **キャッシュの有効期限**: 環境変更（brew update等）後は手動でキャッシュクリア
2. **デバッグ時**: 最適化を無効化して問題の切り分けを容易に
3. **メンテナンス性**: 過度な最適化は保守性を損なう可能性
4. **バックアップ**: 最適化前に`.zshrc`をバックアップ

---

## 🔗 関連リソース

- [zsh Performance](https://htr3n.github.io/2018/07/faster-zsh/)
- [Speeding up zsh](https://blog.mattclemente.com/2020/06/26/oh-my-zsh-slow-to-load/)
- [mise Documentation](https://mise.jdx.dev/)
