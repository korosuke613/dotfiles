# tmux デフォルト mouse on 設定

## 背景
`claude --worktree --tmux` で起動した tmux セッション内でスクロールができない。
原因: tmux のデフォルトが `mouse off` であり、`~/.tmux.conf` が存在しない。

## やること

1. `~/dotfiles/mac/tmux/.tmux.conf` を作成し、以下を記述:
   ```
   set -g mouse on
   ```
2. `~/dotfiles/mac/setup.sh` に `~/.tmux.conf` へのシンボリックリンク作成処理を追加（他の設定ファイルと同じパターンに合わせる）
3. シンボリックリンクを貼る: `ln -sf ~/dotfiles/mac/tmux/.tmux.conf ~/.tmux.conf`

## 注意
- 既存の dotfiles ディレクトリ構成（`mac/<app>/` パターン）に従うこと
- `setup.sh` の既存パターンを確認してからシンボリックリンク処理を追加すること
- `mouse on` にすると iTerm2 等でテキスト選択が tmux に奪われる。ネイティブ選択は `Option` キーを押しながらドラッグで可能
