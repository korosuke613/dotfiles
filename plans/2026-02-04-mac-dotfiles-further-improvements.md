# macOS dotfiles さらなる改善計画

## 概要

前回のPhase 1-4に続く、追加の改善項目。コードベース調査により発見された問題点を優先度別に整理。

## 改善項目一覧

### Phase 5: セキュリティ・エラーハンドリング（高優先度）

#### 5.1 source文の存在チェック追加

存在しないファイルをsourceするとエラーになるため、チェックを追加。

**修正対象ファイル**: `/Users/korosuke613/dotfiles/mac/zsh/.zshrc`

```zsh
# Before
source $HOME/.config/op/plugins.sh
source "$HOME/.rye/env"

# After
[[ -f "$HOME/.config/op/plugins.sh" ]] && source "$HOME/.config/op/plugins.sh"
[[ -f "$HOME/.rye/env" ]] && source "$HOME/.rye/env"
```

#### 5.2 gitconfigのハードコードパス修正

**修正対象ファイル**: `/Users/korosuke613/dotfiles/mac/git/.gitconfig`

| 行 | Before | After |
|----|--------|-------|
| 43 | `/Users/korosuke613/.ssh/allowed_signers` | `~/.ssh/allowed_signers` |

---

### Phase 6: 不要コードの削除（高優先度）

#### 6.1 fig-export関連の削除

Fig（現CodeWhisperer）は2023年にサービス終了。

**修正対象ファイル**: `/Users/korosuke613/dotfiles/mac/zsh/.zshrc`

```zsh
# 削除対象（行137付近）
[[ -f "$HOME/fig-export/dotfiles/dotfile.zsh" ]] && builtin source "$HOME/fig-export/dotfiles/dotfile.zsh"
```

#### 6.2 Q pre/post blockコメントの削除

Amazon Q CLIの古いコメントを削除。

**修正対象ファイル**: `/Users/korosuke613/dotfiles/mac/zsh/.zshrc`

```zsh
# 削除対象（行1, 139付近）
# Q pre block. Keep at the top of this file.
# Q post block. Keep at the bottom of this file.
```

#### 6.3 hammerspoonの未使用Warpホットキー削除

Ghosttyに移行済みのため、Warp用設定を削除。

**修正対象ファイル**: `/Users/korosuke613/dotfiles/mac/hammerspoon/init.lua`

```lua
-- 削除対象（行13-23）
-- Warpをホットキーで起動するやつ (行13-23のブロック)
```

#### 6.4 コメントアウトコードの整理

**修正対象ファイル**: `/Users/korosuke613/dotfiles/mac/zsh/.zshrc.alias`

```zsh
# 削除対象
#alias gsw='echo_eval_arg "git switch"'  # 行34
# wip関連のコメントアウト2行  # 行38-39
```

**修正対象ファイル**: `/Users/korosuke613/dotfiles/mac/git/.gitconfig`

```gitconfig
# 削除対象（または有効化）
#	pager = delta  # 行11
# [delta] セクション全体  # 行24-26
```

---

### Phase 7: PATH設定の統合（中優先度）

#### 7.1 分散したPATH設定を`.zshrc.path`に集約

現状、`.zshrc`内の複数箇所にPATH追加が散在している。

**修正対象ファイル**:
- `/Users/korosuke613/dotfiles/mac/zsh/.zshrc`
- `/Users/korosuke613/dotfiles/mac/zsh/.zshrc.path`

**統合対象のPATH設定**:
| 現在の場所 | 内容 |
|-----------|------|
| .zshrc 行33 | `$HOME/.rd/bin` (Rancher Desktop) |
| .zshrc 行102 | `$GOPATH/bin` |
| .zshrc 行112 | `$BUN_INSTALL/bin` |
| .zshrc 行124 | aqua PATH |
| .zshrc 行142 | `$HOME/.local/bin` (pipx) |
| .zshrc 行145 | `$HOME/.turso` |
| .zshrc 行148 | `$HOME/.lmstudio/bin` |

---

### Phase 8: setup.shの統合（中優先度）

#### 8.1 ghostty/setup.shをメインsetup.shに統合

現状、ghosttyのセットアップは別スクリプトで管理されている。

**修正対象ファイル**: `/Users/korosuke613/dotfiles/mac/setup.sh`

```bash
# SYMLINKS配列に追加
["ghostty/config"]="$HOME/.config/ghostty/config"
```

#### 8.2 ghostty/README.mdの更新

`rm`コマンドの記述を`trash`に修正。

---

### Phase 9: 細かな整理（低優先度）

#### 9.1 vim設定の矛盾修正

**修正対象ファイル**: `/Users/korosuke613/dotfiles/mac/vim/.vimrc`

```vim
" 行2-3で矛盾している
set cursorline
set cursorline!  " ← 直前の設定を無効化しているので削除
```

#### 9.2 .zshrc.pluginsに存在チェック追加

**修正対象ファイル**: `/Users/korosuke613/dotfiles/mac/zsh/.zshrc.plugins`

```zsh
# Before
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# After
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

#### 9.3 古いAnsibleバージョン参照の確認

**修正対象ファイル**: `/Users/korosuke613/dotfiles/mac/zsh/.zshrc.path`

`ansible@2.9`（2019年リリース）が参照されている。必要なければ削除。

---

## 実装しない項目（参考）

以下は今回のスコープ外として保留：

| 項目 | 理由 |
|------|------|
| 会社関連設定の分離 | 既存のincludeIf構造で対応済み |
| vim → neovim移行 | 大規模変更、別プロジェクトとして |
| ファイル命名規則の統一 | 既存リンクへの影響大 |
| starship.tomlの整理 | 動作に影響なし |

---

## 検証方法

各フェーズ完了後：

1. **新しいターミナルセッションを開く**
2. **エラーが出ないことを確認**
3. **`echo $PATH`でPATH設定を確認**
4. **主要エイリアスの動作確認**（`ll`, `gst`, `k`など）

---

## 実装順序

1. Phase 5（高優先度）- エラーハンドリング
2. Phase 6（高優先度）- 不要コード削除
3. Phase 7（中優先度）- PATH統合
4. Phase 8（中優先度）- setup.sh統合
5. Phase 9（低優先度）- 細かな整理
