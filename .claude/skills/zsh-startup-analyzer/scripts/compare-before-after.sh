#!/usr/bin/env bash
# zsh起動時間 Before/After 比較スクリプト

set -euo pipefail

# 色定義
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

STATE_DIR="$HOME/.cache/zsh"
STATE_FILE="$STATE_DIR/startup-benchmark.txt"

mkdir -p "$STATE_DIR"

# 起動時間を計測する関数
measure_startup_time() {
    local total=0
    local measurements=()

    echo "10回計測中..."
    for i in {1..10}; do
        local time_output=$( (time zsh -i -c exit) 2>&1 )
        local real_time=$(echo "$time_output" | grep real | awk '{print $2}')
        local elapsed_secs=$(echo "$real_time" | sed 's/0m\([0-9.]*\)s/\1/')

        measurements+=("$elapsed_secs")
        total=$(echo "$total + $elapsed_secs" | bc)
        echo -ne "  試行 $i/10\r"
    done
    echo ""

    local avg=$(echo "scale=3; $total / 10" | bc)
    echo "$avg"
}

# 計測結果を保存
save_result() {
    local label="$1"
    local time="$2"

    if [ -f "$STATE_FILE" ]; then
        # 既存の結果があれば、該当行を更新
        sed -i.bak "/^$label:/d" "$STATE_FILE"
    fi

    echo "$label:$time" >> "$STATE_FILE"
    echo -e "${GREEN}✓${NC} $label の結果を保存しました: ${time}秒"
}

# 比較表示
show_comparison() {
    if [ ! -f "$STATE_FILE" ]; then
        echo -e "${RED}✗${NC} 計測結果が見つかりません"
        echo "  まず '$0 before' を実行してください"
        exit 1
    fi

    local before=$(grep '^before:' "$STATE_FILE" 2>/dev/null | cut -d: -f2 || echo "")
    local after=$(grep '^after:' "$STATE_FILE" 2>/dev/null | cut -d: -f2 || echo "")

    if [ -z "$before" ]; then
        echo -e "${RED}✗${NC} 'before' の計測結果がありません"
        exit 1
    fi

    if [ -z "$after" ]; then
        echo -e "${RED}✗${NC} 'after' の計測結果がありません"
        exit 1
    fi

    echo ""
    echo -e "${BLUE}=== Before/After 比較 ===${NC}"
    echo ""

    # 計測結果
    echo -e "${CYAN}計測結果:${NC}"
    echo -e "  Before: ${RED}${before}秒${NC}"
    echo -e "  After:  ${GREEN}${after}秒${NC}"
    echo ""

    # 差分計算
    local diff=$(echo "scale=3; $before - $after" | bc)
    local diff_ms=$(echo "scale=0; $diff * 1000 / 1" | bc)

    # 改善率計算
    local improvement=$(echo "scale=1; ($before - $after) / $before * 100" | bc)

    echo -e "${CYAN}改善効果:${NC}"
    echo -e "  削減時間: ${GREEN}${diff}秒 (${diff_ms}ms)${NC}"
    echo -e "  改善率:   ${GREEN}${improvement}%${NC}"
    echo ""

    # 評価
    local after_ms=$(echo "scale=0; $after * 1000 / 1" | bc)
    echo -e "${CYAN}評価:${NC}"
    if [ "$after_ms" -lt 100 ]; then
        echo -e "  ${GREEN}✓ 優秀${NC} (100ms未満) - 目標達成！"
    elif [ "$after_ms" -lt 200 ]; then
        echo -e "  ${GREEN}✓ 良好${NC} (100-200ms) - 目標達成！"
    elif [ "$after_ms" -lt 500 ]; then
        echo -e "  ${YELLOW}△ 改善推奨${NC} (200-500ms) - さらなる最適化が可能"
    else
        echo -e "  ${RED}✗ 要改善${NC} (500ms以上) - 追加の最適化が必要"
    fi
    echo ""

    # 倍速表示
    local speedup=$(echo "scale=1; $before / $after" | bc)
    echo -e "${CYAN}高速化:${NC}"
    echo -e "  ${GREEN}約${speedup}倍高速化${NC}"
    echo ""
}

# メイン処理
case "${1:-}" in
    before)
        echo -e "${BLUE}=== Before 計測 ===${NC}"
        echo ""
        echo "最適化前の起動時間を計測します..."
        echo ""

        avg_time=$(measure_startup_time)
        save_result "before" "$avg_time"

        echo ""
        echo -e "${CYAN}次のステップ:${NC}"
        echo "  1. zsh設定ファイルの最適化を実施"
        echo "  2. '$0 after' を実行して効果を測定"
        ;;

    after)
        echo -e "${BLUE}=== After 計測 ===${NC}"
        echo ""
        echo "最適化後の起動時間を計測します..."
        echo ""

        avg_time=$(measure_startup_time)
        save_result "after" "$avg_time"

        echo ""
        show_comparison
        ;;

    compare)
        show_comparison
        ;;

    reset)
        if [ -f "$STATE_FILE" ]; then
            rm "$STATE_FILE"
            echo -e "${GREEN}✓${NC} 計測結果をリセットしました"
        else
            echo -e "${YELLOW}⚠${NC} 計測結果がありません"
        fi
        ;;

    *)
        echo "zsh起動時間 Before/After 比較ツール"
        echo ""
        echo "使い方:"
        echo "  $0 before   - 最適化前の起動時間を計測"
        echo "  $0 after    - 最適化後の起動時間を計測し、比較表示"
        echo "  $0 compare  - 保存済みの結果を比較表示"
        echo "  $0 reset    - 計測結果をリセット"
        echo ""
        echo "ワークフロー:"
        echo "  1. $0 before      # 最適化前を記録"
        echo "  2. [最適化を実施]"
        echo "  3. $0 after       # 最適化後を記録して比較"
        exit 1
        ;;
esac
