fpath=(/opt/homebrew/share/zsh/site-functions "$HOME/.zsh" $fpath)

if [[ -f "$HOME/.zsh/git-completion.bash" ]]; then
  zstyle ':completion:*:*:git:*' script "$HOME/.zsh/git-completion.bash"
fi

autoload -Uz compinit
compdump="$HOME/.zcompdump"
if [[ -n ${compdump}(#qN.mh+24) ]]; then
  compinit -i -d "$compdump"
else
  compinit -C -d "$compdump"
fi

[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
