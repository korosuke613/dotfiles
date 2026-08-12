export EDITOR=vim
export SBX_NO_TELEMETRY=1
export TF_CLI_ARGS_plan="--parallelism=50"
export TF_CLI_ARGS_apply="--parallelism=50"

setopt autocd
setopt interactive_comments

if [[ "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "kiro" ]]; then
  bindkey -e
fi
