#!/usr/bin/env bash
# zsh起動時間計測スクリプト
# 基本計測とzprofを使った詳細計測を実行

set -euo pipefail

# 色定義
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== zsh起動時間計測 ===${NC}\n"

# OS検出
OS="$(uname -s)"
echo -e "${CYAN}検出OS: $OS${NC}\n"

# 基本計測（10回）
echo -e "${BLUE}【基本計測】${NC}"
echo "10回計測して平均を算出します..."
echo ""

TOTAL_TIME=0
MEASUREMENTS=()

for i in {1..10}; do
    # GNU timeとBSD timeで出力形式が異なるため、zshの組み込み機能を使用
    if [ "$OS" = "Darwin" ]; then
        # macOS
        TIME_OUTPUT=$( (time zsh -i -c exit) 2>&1 )
        REAL_TIME=$(echo "$TIME_OUTPUT" | grep real | awk '{print $2}')
        # 秒に変換（0m0.123s → 0.123）
        ELAPSED_SECS=$(echo "$REAL_TIME" | sed 's/0m\([0-9.]*\)s/\1/')
    else
        # Linux
        TIME_OUTPUT=$( (time zsh -i -c exit) 2>&1 )
        REAL_TIME=$(echo "$TIME_OUTPUT" | grep real | awk '{print $2}')
        ELAPSED_SECS=$(echo "$REAL_TIME" | sed 's/0m\([0-9.]*\)s/\1/')
    fi

    MEASUREMENTS+=("$ELAPSED_SECS")
    TOTAL_TIME=$(echo "$TOTAL_TIME + $ELAPSED_SECS" | bc)
    echo -e "  試行 $i: ${ELAPSED_SECS}秒"
done

AVG_TIME=$(echo "scale=3; $TOTAL_TIME / 10" | bc)
echo ""
echo -e "${GREEN}平均起動時間: ${AVG_TIME}秒${NC}"
echo ""

# パフォーマンス評価
AVG_MS=$(echo "$AVG_TIME * 1000" | bc | cut -d. -f1)
if [ "$AVG_MS" -lt 100 ]; then
    echo -e "${GREEN}✓ 優秀${NC} (100ms未満)"
elif [ "$AVG_MS" -lt 200 ]; then
    echo -e "${YELLOW}△ 良好${NC} (100-200ms)"
elif [ "$AVG_MS" -lt 500 ]; then
    echo -e "${YELLOW}⚠ 改善推奨${NC} (200-500ms)"
else
    echo -e "${RED}✗ 要改善${NC} (500ms以上)"
fi
echo ""

# zprof詳細計測
echo -e "${BLUE}【zprof詳細計測】${NC}"
echo "zprofを使用して関数ごとの実行時間を計測します..."
echo ""

# zprofを有効化した一時zshrcを作成
ZDOTDIR="${ZDOTDIR:-$HOME}"
TEMP_ZSHRC=$(mktemp)
cat > "$TEMP_ZSHRC" << 'EOF'
zmodload zsh/zprof
source ~/.zshrc
zprof
EOF

echo "実行中..."
ZPROF_OUTPUT=$(ZDOTDIR="$ZDOTDIR" zsh -i -c "zmodload zsh/zprof; source $ZDOTDIR/.zshrc; zprof" 2>&1 | grep -A 50 "seconds" || true)

if [ -n "$ZPROF_OUTPUT" ]; then
    echo "$ZPROF_OUTPUT" | head -20
    echo ""
    echo -e "${CYAN}上位の時間消費関数が表示されました${NC}"
else
    echo -e "${YELLOW}⚠ zprof出力を取得できませんでした${NC}"
fi

rm -f "$TEMP_ZSHRC"

echo ""
echo -e "${BLUE}=== 計測完了 ===${NC}"
