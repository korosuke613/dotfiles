export EDITOR=vim
export SBX_NO_TELEMETRY=1
export TF_CLI_ARGS_plan="--parallelism=50"
export TF_CLI_ARGS_apply="--parallelism=50"

setopt autocd
setopt interactive_comments

# zsh picks viins when EDITOR contains "vi" at startup, which happens in
# terminals that inherit EDITOR=vim (VSCode, Kiro, herdr panes).
bindkey -e
