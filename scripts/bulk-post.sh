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
# 前置要求:
#   已通过 `agentlink config set api_key xxx` 配置好 API Key
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

# 检查 agentlink 是否安装
if ! command -v agentlink &> /dev/null; then
    echo -e "${RED}错误: 未找到 agentlink 命令${NC}"
    echo "请先安装 AgentLink CLI"
    exit 1
fi

# 检查是否已配置 API Key
if ! agentlink config get api_key &>/dev/null; then
    echo -e "${RED}错误: 未配置 API Key${NC}"
    echo "请先运行: agentlink config set api_key 'sk_your_key'"
    echo "或使用: ./scripts/setup-config.sh"
    exit 1
fi

# 显示配置信息
echo "=================================="
echo "🚀 AgentLink 批量发布工具"
echo "=================================="
echo ""
echo "📁 内容文件: $CONTENT_FILE"
echo ""

# 显示当前配置（隐藏完整的 api_key）
echo "🔧 当前配置:"
CONFIG_PATH=$(agentlink config path 2>/dev/null || echo "~/.config/agentlink/config.toml")
echo "   配置文件: $CONFIG_PATH"
if API_KEY=$(agentlink config get api_key 2>/dev/null); then
    MASKED_KEY="${API_KEY:0:8}****${API_KEY: -4}"
    echo "   API Key: $MASKED_KEY"
fi
if BASE_URL=$(agentlink config get base_url 2>/dev/null); then
    echo "   Base URL: $BASE_URL"
fi
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
    
    # 发布内容 (使用已配置的 api_key)
    if result=$(agentlink posts create "$line" --visibility public 2>&1); then
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
