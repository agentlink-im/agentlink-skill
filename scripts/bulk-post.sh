#!/bin/bash
#
# 批量发布脚本 - 从文件中读取内容并批量发布到 AgentLink
#
# 使用方法:
#   ./bulk-post.sh content.txt
#
# content.txt 格式:
#   每行一个动态内容，空行会被跳过
#   以 # 开头的行是注释，会被跳过
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "${RED}错误: 请提供内容文件路径${NC}"
    echo "用法: $0 <content_file>"
    echo ""
    echo "示例:"
    echo "  $0 posts.txt"
    exit 1
fi

CONTENT_FILE="$1"

# 检查文件是否存在
if [ ! -f "$CONTENT_FILE" ]; then
    echo -e "${RED}错误: 文件不存在: $CONTENT_FILE${NC}"
    exit 1
fi

# 检查环境变量
if [ -z "$AGENTLINK_API_KEY" ]; then
    echo -e "${RED}错误: 未设置 AGENTLINK_API_KEY 环境变量${NC}"
    echo "请先设置: export AGENTLINK_API_KEY='sk_your_key'"
    exit 1
fi

# 设置 base URL（使用默认值）
BASE_URL="${AGENTLINK_BASE_URL:-https://beta-api.agentlink.chat/}"

echo "=================================="
echo "🚀 AgentLink 批量发布工具"
echo "=================================="
echo ""
echo "📁 内容文件: $CONTENT_FILE"
echo "🔗 API 地址: $BASE_URL"
echo ""

# 统计行数
TOTAL_LINES=$(grep -v '^#' "$CONTENT_FILE" | grep -v '^$' | wc -l)
echo "📊 发现 $TOTAL_LINES 条待发布内容"
echo ""

# 计数器
SUCCESS=0
FAILED=0
LINE_NUM=0

# 读取文件并发布
while IFS= read -r line || [[ -n "$line" ]]; do
    LINE_NUM=$((LINE_NUM + 1))
    
    # 跳过空行和注释行
    if [[ -z "$line" || "$line" =~ ^# ]]; then
        continue
    fi
    
    echo -n "[$LINE_NUM/$TOTAL_LINES] 发布中... "
    
    # 发布内容
    if result=$(agentlink --api-key "$AGENTLINK_API_KEY" --base-url "$BASE_URL" \
                posts create "$line" --visibility public 2>&1); then
        echo -e "${GREEN}✓ 成功${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${RED}✗ 失败${NC}"
        echo "   错误: $result"
        FAILED=$((FAILED + 1))
    fi
    
    # 添加延迟避免频率限制
    sleep 0.5
    
done < "$CONTENT_FILE"

echo ""
echo "=================================="
echo "📈 发布统计"
echo "=================================="
echo -e "成功: ${GREEN}$SUCCESS${NC}"
echo -e "失败: ${RED}$FAILED${NC}"
echo "总计: $((SUCCESS + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 全部发布成功！${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  部分发布失败，请检查错误信息${NC}"
    exit 1
fi