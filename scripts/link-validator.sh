#!/bin/bash
# Link Validator Script
# 批量验证链接可访问性

set -e

# 配置
TIMEOUT=5
MAX_CONCURRENT=10

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔗 开始链接验证..."

# 读取链接列表 (从文件或参数)
if [ $# -eq 0 ]; then
    echo "用法：link-validator.sh <link_file>"
    echo "link_file: 包含链接列表的文件，每行一个链接"
    exit 1
fi

LINK_FILE=$1

if [ ! -f "$LINK_FILE" ]; then
    echo -e "${RED}❌ 文件不存在：$LINK_FILE${NC}"
    exit 1
fi

# 统计
TOTAL=0
VALID=0
INVALID=0
TIMEOUT_COUNT=0

# 验证函数
validate_link() {
    local link=$1
    TOTAL=$((TOTAL + 1))
    
    # 使用 curl 检查链接
    if curl -s --max-time $TIMEOUT --head "$link" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} $link"
        VALID=$((VALID + 1))
    else
        # 尝试使用 GET 请求
        if curl -s --max-time $TIMEOUT "$link" > /dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} $link (GET)"
            VALID=$((VALID + 1))
        else
            echo -e "${RED}❌${NC} $link"
            INVALID=$((INVALID + 1))
        fi
    fi
}

# 读取并验证链接
while IFS= read -r link || [ -n "$link" ]; do
    # 跳过空行和注释
    [[ -z "$link" || "$link" =~ ^# ]] && continue
    
    validate_link "$link"
    
    # 限制并发 (简单实现)
    if [ $((TOTAL % MAX_CONCURRENT)) -eq 0 ]; then
        sleep 1
    fi
done < "$LINK_FILE"

# 生成报告
REPORT_FILE="/tmp/web-automation/link-validation-$(date +%Y%m%d-%H%M%S).md"

cat > "$REPORT_FILE" << EOF
# 链接验证报告

**验证时间**: $(date '+%Y-%m-%d %H:%M:%S')
**链接文件**: $LINK_FILE

## 统计结果

| 指标 | 数值 |
|------|------|
| 总链接数 | $TOTAL |
| 有效链接 | $VALID |
| 无效链接 | $INVALID |
| 超时链接 | $TIMEOUT_COUNT |
| 成功率 | $(echo "scale=2; $VALID * 100 / $TOTAL" | bc)% |

## 建议

EOF

if [ $VALID -eq $TOTAL ]; then
    echo "✅ 所有链接均可访问！" >> "$REPORT_FILE"
else
    echo "⚠️ 发现 $INVALID 个无效链接，建议检查或更新。" >> "$REPORT_FILE"
fi

echo ""
echo "================================"
echo -e "${GREEN}✅ 验证完成！${NC}"
echo "总链接数：$TOTAL"
echo -e "${GREEN}有效链接：$VALID${NC}"
echo -e "${RED}无效链接：$INVALID${NC}"
echo "报告已保存到：$REPORT_FILE"
