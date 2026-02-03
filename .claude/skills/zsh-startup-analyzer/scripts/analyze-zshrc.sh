#!/usr/bin/env bash
# zshrc構造解析スクリプト
# zshrcファイルの場所を自動検出し、sourceされているファイルやボトルネック候補を検出する

set -euo pipefail

# 色定義
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== zshrc構造解析 ===${NC}\n"

# ZDOTDIR の確認
if [ -n "${ZDOTDIR:-}" ]; then
    ZSHRC_DIR="$ZDOTDIR"
    echo -e "${GREEN}✓${NC} ZDOTDIR検出: $ZDOTDIR"
else
    ZSHRC_DIR="$HOME"
    echo -e "${YELLOW}ℹ${NC} ZDOTDIR未設定、ホームディレクトリを使用: $HOME"
fi

ZSHRC_FILE="$ZSHRC_DIR/.zshrc"

if [ ! -f "$ZSHRC_FILE" ]; then
    echo -e "${RED}✗${NC} .zshrcが見つかりません: $ZSHRC_FILE"
    exit 1
fi

echo -e "${GREEN}✓${NC} .zshrc検出: $ZSHRC_FILE\n"

# sourceされているファイル一覧
echo -e "${BLUE}【sourceされているファイル】${NC}"
grep -E '^\s*(source|\.)' "$ZSHRC_FILE" | grep -v '^#' | sed 's/^/  /' || echo "  (なし)"
echo ""

# ボトルネック候補の検出
echo -e "${BLUE}【ボトルネック候補】${NC}\n"

# evalコマンド
echo -e "${YELLOW}1. evalコマンド${NC}"
EVAL_COUNT=$(grep -c 'eval' "$ZSHRC_FILE" 2>/dev/null || echo "0")
if [ "$EVAL_COUNT" -gt 0 ]; then
    echo -e "  ${RED}⚠${NC} 検出数: $EVAL_COUNT"
    grep -n 'eval' "$ZSHRC_FILE" | sed 's/^/    /' || true
else
    echo -e "  ${GREEN}✓${NC} 検出なし"
fi
echo ""

# compinit
echo -e "${YELLOW}2. compinit${NC}"
if grep -q 'compinit' "$ZSHRC_FILE"; then
    echo -e "  ${RED}⚠${NC} 検出"
    grep -n 'compinit' "$ZSHRC_FILE" | sed 's/^/    /' || true
else
    echo -e "  ${GREEN}✓${NC} 検出なし"
fi
echo ""

# サブシェル（コマンド置換）
echo -e "${YELLOW}3. サブシェル/コマンド置換${NC}"
SUBSHELL_COUNT=$(grep -c '\$(' "$ZSHRC_FILE" 2>/dev/null || echo "0")
if [ "$SUBSHELL_COUNT" -gt 0 ]; then
    echo -e "  ${RED}⚠${NC} 検出数: $SUBSHELL_COUNT"
    grep -n '\$(' "$ZSHRC_FILE" | head -10 | sed 's/^/    /' || true
    if [ "$SUBSHELL_COUNT" -gt 10 ]; then
        echo "    ... 他 $((SUBSHELL_COUNT - 10))件"
    fi
else
    echo -e "  ${GREEN}✓${NC} 検出なし"
fi
echo ""

# 外部コマンド呼び出し
echo -e "${YELLOW}4. 重い可能性のある外部コマンド${NC}"
HEAVY_COMMANDS=("brew" "direnv" "mise" "asdf" "starship" "atuin" "zoxide")
FOUND=0
for cmd in "${HEAVY_COMMANDS[@]}"; do
    if grep -q "$cmd" "$ZSHRC_FILE"; then
        echo -e "  ${RED}⚠${NC} $cmd"
        FOUND=1
    fi
done
if [ "$FOUND" -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} 検出なし"
fi
echo ""

# 分割ファイルの検出
echo -e "${BLUE}【分割設定ファイル】${NC}"
SPLIT_FILES=(
    ".zshrc.setting"
    ".zshrc.alias"
    ".zshrc.history"
    ".zshrc.cd_fzf"
    ".zshrc.local"
)

for file in "${SPLIT_FILES[@]}"; do
    filepath="$ZSHRC_DIR/$file"
    if [ -f "$filepath" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    fi
done
echo ""

echo -e "${BLUE}=== 解析完了 ===${NC}"
