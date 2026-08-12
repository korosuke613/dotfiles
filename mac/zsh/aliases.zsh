echo_eval() {
  eval "$1"
}

echo_eval_arg() {
  eval "$1 ${*:2}"
}

echo_eval_arg_single() {
  eval "$1 \"$2\""
}

alias gs='echo_eval "git status"'
alias gcm='echo_eval_arg_single "git commit -m"'
alias gca='echo_eval "git commit --amend"'
alias gcan='echo_eval "git commit --amend --no-edit"'
alias gpl='echo_eval "git pull --rebase --set-upstream origin $(git branch --show-current)"'
alias gps='echo_eval "git push"'
alias gpsf='echo_eval "git push --force-with-lease --force-if-includes"'
alias gsw='git switch'
alias gswc='echo_eval_arg "git switch -c"'
alias gcv='echo_eval "EDITOR=\"code --wait\" git commit -v"'
alias gl='echo_eval "git log"'
alias wip='echo_eval "git commit --fixup $(git log -1 --pretty=format:\"%H\" --grep=\"^fixup!\" --invert-grep)"'
alias tf='terraform'
alias k='kubectl'
alias cdq='cd "$(ghq root)/$(ghq list | fzf)"'
alias python='python3'
alias cp='cp -i'
alias mv='mv -i'
alias vi='vim'
alias npx='echo "WARNING: npx は実行しないでください。代わりに pnpm exec を使ってください" && false'
alias npm='echo "WARNING: npm は実行しないでください。代わりに pnpm を使ってください" && false'
alias rm='echo "WARNING: rm は実行しないでください。代わりに trash を使ってください" && false'

if (( $+commands[eza] )); then
  alias ls='eza -G --color auto --icons -a -s type'
  alias ll='eza -l --color always --icons -a -s type'
fi

if (( $+commands[bat] )); then
  alias cat='bat -pp --theme="Nord"'
fi

cdf() {
  local target
  [[ "$PWD" == "$HOME"/* || "$PWD" == "$HOME" ]] || {
    print -u2 "cdf: current directory must be under $HOME"
    return 1
  }
  target=$(fd -t d | fzf --height 50% --layout=reverse --border \
    --preview 'eza -F -1 {}') || return
  [[ -n "$target" ]] && cd "$target"
}

_ghn() {
  gh run watch -i10 --exit-status &&
    osascript -e 'display alert "GitHub Actions workflow is done!" buttons {"OK"}'
}
alias ghn='_ghn'

zsh-cache-clear() {
  local files=("$HOME/.cache/zsh/"*.zsh(N))
  (( ${#files} )) && trash "${files[@]}"
  print "zsh cache cleared"
}
alias zsh-cache-rebuild='zsh-cache-clear && exec zsh'
