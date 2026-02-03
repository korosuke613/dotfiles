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

# sourceされているファイルを再帰的に収集
collect_source_files() {
    local file="$1"
    local base_dir="$(dirname "$file")"

    grep -E '^\s*(source|\.)' "$file" 2>/dev/null | grep -v '^#' | while IFS= read -r line; do
        # source または . の後のファイルパスを抽出
        local src_file=$(echo "$line" | sed -E 's/^\s*(source|\.)\s+//' | sed 's/["'\'']//g')

        # 変数展開を試みる（基本的なもののみ）
        src_file=$(eval echo "$src_file" 2>/dev/null || echo "$src_file")

        # 相対パスの場合は絶対パスに変換
        if [[ "$src_file" != /* ]]; then
            src_file="$base_dir/$src_file"
        fi

        if [ -f "$src_file" ]; then
            echo "$src_file"
            collect_source_files "$src_file"
        fi
    done
}

# sourceされているファイル一覧
echo -e "${BLUE}【sourceされているファイル】${NC}"
ALL_SOURCE_FILES=$(collect_source_files "$ZSHRC_FILE" | sort -u)
echo "$ALL_SOURCE_FILES" | while read -r file; do
    if [ -n "$file" ]; then
        echo "  $(basename "$file") ($file)"
    fi
done
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

# compinit（再帰的に検出）
echo -e "${YELLOW}2. compinit（source先を含む）${NC}"
COMPINIT_FOUND=0
echo "$ZSHRC_FILE" > /tmp/zsh_all_files.txt
echo "$ALL_SOURCE_FILES" >> /tmp/zsh_all_files.txt

while IFS= read -r file; do
    if [ -f "$file" ] && grep -q 'compinit' "$file" 2>/dev/null; then
        if [ "$COMPINIT_FOUND" -eq 0 ]; then
            echo -e "  ${RED}⚠${NC} 検出（複数ファイルで呼び出されている可能性あり）"
        fi
        COMPINIT_FOUND=$((COMPINIT_FOUND + 1))
        echo -e "    ${YELLOW}[$COMPINIT_FOUND]${NC} $(basename "$file"): $file"
        grep -n 'compinit' "$file" | sed 's/^/        /' | head -3 || true
    fi
done < /tmp/zsh_all_files.txt

if [ "$COMPINIT_FOUND" -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} 検出なし"
elif [ "$COMPINIT_FOUND" -gt 1 ]; then
    echo -e "  ${RED}✗ 警告: compinit が ${COMPINIT_FOUND} 箇所で呼ばれています（重複の可能性）${NC}"
fi

rm -f /tmp/zsh_all_files.txt
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

# 重複コード検出
echo -e "${YELLOW}5. 重複コード検出${NC}"
TEMP_ALL_FILES=$(mktemp)
echo "$ZSHRC_FILE" > "$TEMP_ALL_FILES"
echo "$ALL_SOURCE_FILES" >> "$TEMP_ALL_FILES"

# eval の重複検出
echo -e "  ${BLUE}eval コマンドの重複:${NC}"
TEMP_EVAL=$(mktemp)
while IFS= read -r file; do
    if [ -f "$file" ]; then
        grep -h 'eval' "$file" 2>/dev/null | sed 's/^[[:space:]]*//' >> "$TEMP_EVAL" || true
    fi
done < "$TEMP_ALL_FILES"

DUPLICATE_EVALS=$(sort "$TEMP_EVAL" | uniq -d)
if [ -n "$DUPLICATE_EVALS" ]; then
    echo "$DUPLICATE_EVALS" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            echo -e "    ${RED}⚠${NC} $line"
        fi
    done
else
    echo -e "    ${GREEN}✓${NC} 重複なし"
fi

# alias の重複検出
echo -e "  ${BLUE}alias 定義の重複:${NC}"
TEMP_ALIAS=$(mktemp)
while IFS= read -r file; do
    if [ -f "$file" ]; then
        grep -h '^[[:space:]]*alias' "$file" 2>/dev/null | sed 's/^[[:space:]]*//' >> "$TEMP_ALIAS" || true
    fi
done < "$TEMP_ALL_FILES"

DUPLICATE_ALIASES=$(sort "$TEMP_ALIAS" | uniq -d)
if [ -n "$DUPLICATE_ALIASES" ]; then
    echo "$DUPLICATE_ALIASES" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            echo -e "    ${RED}⚠${NC} $line"
        fi
    done
else
    echo -e "    ${GREEN}✓${NC} 重複なし"
fi

rm -f "$TEMP_ALL_FILES" "$TEMP_EVAL" "$TEMP_ALIAS"
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
