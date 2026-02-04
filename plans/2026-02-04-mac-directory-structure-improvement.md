# mac ディレクトリ構造改善計画

## 概要

macOS用dotfilesの可読性とメンテナンス性を向上させるための段階的改善計画。

**実施範囲**: 全フェーズ（Phase 1〜4）
**確認済み事項**:
- asdf/ ディレクトリ → 削除OK（mise移行済み）
- iTerm2/ ディレクトリ → 削除OK（Ghostty移行済み）

## 現状の主な問題点

1. **不要ファイル**: `.DS_Store`、空ディレクトリ、死んでいるコード
2. **命名の不統一**: `.zshrc.exa`（中身はeza）、拡張子なしファイル
3. **ハードコードされたパス**: `/Users/korosuke613/...` が複数箇所に散在
4. **setup.sh の脆弱性**: エラーハンドリングなし、シンボリックリンクが個別にハードコード
5. **PATH設定の分散**: `.zshrc` 本体と `.zshrc.path` に散在

---

## Phase 1: クリーンアップ（低リスク）

既存の動作に影響しない単純な削除・リネーム作業。

### 1.1 不要ファイルの削除

| ファイル | 作業 |
|---------|------|
| `mac/.DS_Store` | `git rm --cached` で削除 |
| `mac/claude/skills/` | 空ディレクトリを削除 |
| `mac/zsh/.zshrc.auto_assam` | 全コメントアウトのため削除 |
| `mac/asdf/` | mise移行済みのため削除 |
| `mac/iTerm2/` | Ghostty移行済みのため削除 |

### 1.2 .gitignore の更新

```gitignore
# 追加
.DS_Store
*/.DS_Store
```

### 1.3 ファイル名のリネーム

| 対象 | 変更後 |
|------|--------|
| `mac/zsh/.zshrc.exa` | `mac/zsh/.zshrc.eza` |
| `mac/git/office` | `mac/git/office.gitconfig` |
| `mac/scripts/README.dotfiles-sync.md` | `mac/scripts/README.md` |
| `mac/zsh/.zshrc.setting` | `mac/zsh/.zshrc.plugins`（内容に合わせる） |

### 修正対象ファイル

- `/Users/korosuke613/dotfiles/.gitignore`
- `/Users/korosuke613/dotfiles/mac/setup.sh`（asdfリンク削除、office.gitconfig対応）
- `/Users/korosuke613/dotfiles/mac/zsh/.zshrc`（source先のファイル名変更対応）

---

## Phase 2: zsh設定の整理（中リスク）

### 2.1 ハードコードされたパスの変数化

`.zshrc` 内の以下を `$HOME` に置き換え：

```zsh
# Before → After
/Users/korosuke613/.rd/bin → $HOME/.rd/bin
/Users/korosuke613/.config/op/plugins.sh → $HOME/.config/op/plugins.sh
/Users/korosuke613/.bun/_bun → $HOME/.bun/_bun
/Users/korosuke613/.local/bin → $HOME/.local/bin
/Users/korosuke613/.turso → $HOME/.turso
/Users/korosuke613/.lmstudio/bin → $HOME/.lmstudio/bin
```

### 2.2 .zshrc.auto_assam の source 行削除

```zsh
# 削除対象（line 65-67）
# auto assam
# shellcheck source=.zshrc.auto_assam
source ${DOTFILES_ZSH_HOME}/.zshrc.auto_assam
```

### 2.3 VSCode/Kiro の重複if文を統合

```zsh
# Before（line 96-101）
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    bindkey -e
fi
if [[ "$TERM_PROGRAM" == "kiro" ]]; then
    bindkey -e
fi

# After
if [[ "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "kiro" ]]; then
    bindkey -e
fi
```

### 2.4 zsh-cache-clear エイリアスの修正

`.zshrc.alias` 内の `rm` を `command rm` に変更（自身のrm警告機能を回避）

### 修正対象ファイル

- `/Users/korosuke613/dotfiles/mac/zsh/.zshrc`
- `/Users/korosuke613/dotfiles/mac/zsh/.zshrc.alias`

---

## Phase 3: setup.sh の改善（中〜高リスク）

### 3.1 エラーハンドリングの追加

```bash
#!/bin/bash
set -euo pipefail
```

### 3.2 DOTFILES_HOME 変数の導入

```bash
DOTFILES_HOME="${DOTFILES_HOME:-$HOME/dotfiles/mac}"
```

### 3.3 シンボリックリンク定義の配列化

```bash
declare -A SYMLINKS=(
    ["vim/.vimrc"]="$HOME/.vimrc"
    ["zsh/.zshrc"]="$HOME/.zshrc"
    ["starship/starship.toml"]="$HOME/.config/starship.toml"
    ["git/.gitconfig"]="$HOME/.gitconfig"
    ["git/ignore"]="$HOME/.config/git/ignore"
    ["git/office.gitconfig"]="$HOME/.config/git/office"
    ["hammerspoon/init.lua"]="$HOME/.hammerspoon/init.lua"
)

for src in "${!SYMLINKS[@]}"; do
    target="${SYMLINKS[$src]}"
    mkdir -p "$(dirname "$target")"
    ln -sf "${DOTFILES_HOME}/${src}" "$target"
done
```

### 3.4 vim-plug の存在チェック追加

```bash
if [[ ! -f ~/.vim/autoload/plug.vim ]]; then
    echo "Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
```

### 3.5 ghostty/setup.sh の呼び出し追加（オプション）

### 修正対象ファイル

- `/Users/korosuke613/dotfiles/mac/setup.sh`

---

## Phase 4: ドキュメント整備（低リスク）

### 4.1 CLAUDE.md の更新

- Brewfile の記述を削除（存在しないため）
- asdf → mise への移行を反映
- 現在の構造を正確に記載

### 修正対象ファイル

- `/Users/korosuke613/dotfiles/CLAUDE.md`

---

## 検証方法

各フェーズ完了後：

1. **新しいターミナルセッションを開く**
2. **`echo $PATH` でPATH設定を確認**
3. **エイリアスの動作確認**（`ll`, `gst`, `k` など）
4. **setup.sh のドライラン**（新環境がない場合はコードレビュー）

---

## 実装優先順位

1. Phase 1（低リスク）- 即座に実行可能
2. Phase 2（中リスク）- 動作確認必須
3. Phase 3（中〜高リスク）- 慎重にテスト
4. Phase 4（低リスク）- 最後にドキュメント整備
