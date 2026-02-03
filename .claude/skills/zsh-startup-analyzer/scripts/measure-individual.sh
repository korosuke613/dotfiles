#!/usr/bin/env bash
# 個別処理時間計測スクリプト
# eval、外部コマンド、compinit等の個別実行時間を計測

set -euo pipefail

# 色定義
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 個別処理時間計測 ===${NC}\n"

# OS検出
OS="$(uname -s)"
echo -e "${CYAN}検出OS: $OS${NC}\n"

# 時間計測用関数
measure_command() {
    local name="$1"
    local command="$2"
    local iterations="${3:-3}"

    local total=0
    local measurements=()

    for ((i=1; i<=iterations; i++)); do
        local start=$(date +%s%N)
        eval "$command" > /dev/null 2>&1 || true
        local end=$(date +%s%N)
        local elapsed=$((end - start))
        local ms=$((elapsed / 1000000))
        measurements+=($ms)
        total=$((total + ms))
    done

    local avg=$((total / iterations))
    echo -e "  ${name}: ${avg}ms"

    # 警告レベル判定
    if [ $avg -gt 50 ]; then
        echo -e "    ${RED}⚠ 高負荷${NC} - 最適化を推奨"
    elif [ $avg -gt 20 ]; then
        echo -e "    ${YELLOW}△ 中程度${NC} - 改善の余地あり"
    fi
}

# macOS固有の計測
if [ "$OS" = "Darwin" ]; then
    echo -e "${BLUE}【macOS固有の処理】${NC}"

    # brew shellenv
    if command -v brew &> /dev/null; then
        measure_command "brew shellenv" "brew shellenv"
    fi

    # mise
    if command -v mise &> /dev/null; then
        measure_command "mise activate zsh" "mise activate zsh"
    fi

    # atuin
    if command -v atuin &> /dev/null; then
        measure_command "atuin init zsh" "atuin init zsh"
    fi

    echo ""
fi

# Linux固有の計測
if [ "$OS" = "Linux" ]; then
    echo -e "${BLUE}【Linux固有の処理】${NC}"

    # asdf
    if [ -f "$HOME/.asdf/asdf.sh" ]; then
        measure_command "asdf init" "source $HOME/.asdf/asdf.sh"
    fi

    # dircolors
    if command -v dircolors &> /dev/null; then
        measure_command "dircolors" "dircolors -b"
    fi

    echo ""
fi

# 共通の計測
echo -e "${BLUE}【共通処理】${NC}"

# direnv
if command -v direnv &> /dev/null; then
    measure_command "direnv hook zsh" "direnv hook zsh"
fi

# starship
if command -v starship &> /dev/null; then
    measure_command "starship init zsh" "starship init zsh"
fi

# compinit（3回は時間がかかるので1回のみ）
echo -e "  compinit: (計測中...)"
COMPINIT_START=$(date +%s%N)
zsh -i -c "autoload -Uz compinit; compinit" > /dev/null 2>&1
COMPINIT_END=$(date +%s%N)
COMPINIT_MS=$(( (COMPINIT_END - COMPINIT_START) / 1000000 ))
echo -e "  compinit: ${COMPINIT_MS}ms"
if [ $COMPINIT_MS -gt 100 ]; then
    echo -e "    ${RED}⚠ 高負荷${NC} - compdumpキャッシュの活用を推奨"
elif [ $COMPINIT_MS -gt 50 ]; then
    echo -e "    ${YELLOW}△ 中程度${NC} - 1日1回の実行に制限することを推奨"
fi

echo ""

# サマリー
echo -e "${BLUE}【最適化提案】${NC}"
echo ""
echo -e "${YELLOW}高負荷処理（50ms以上）:${NC}"
echo "  - evalのキャッシュ化を検討"
echo "  - 遅延読み込み（lazy load）の導入"
echo "  - compinit実行を1日1回に制限"
echo ""
echo -e "${YELLOW}中程度負荷（20-50ms）:${NC}"
echo "  - 非同期初期化の検討"
echo "  - 条件付き読み込み（必要な時のみ）"
echo ""

echo -e "${BLUE}=== 計測完了 ===${NC}"
echo ""
echo "詳細な最適化テクニックは references/optimization-techniques.md を参照してください"
