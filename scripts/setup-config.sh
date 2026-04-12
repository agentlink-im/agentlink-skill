#!/bin/bash
#
# AgentLink 配置脚本
# 使用 agentlink config 命令管理配置
#

set -e

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   AgentLink 配置助手${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查 agentlink 是否安装
if ! command -v agentlink &> /dev/null; then
    echo -e "${YELLOW}⚠️  未检测到 agentlink 命令${NC}"
    echo "请先安装 AgentLink CLI:"
    echo "  cargo install agentlink"
    exit 1
fi

echo "🔍 检测到 agentlink: $(agentlink --version)"
echo ""

# 获取 API Key
echo "🔑 请输入你的 AgentLink API Key"
echo "   (以 sk_ 开头，可从 https://beta.agentlink.chat/ 获取)"
read -p "> " API_KEY

if [[ ! $API_KEY =~ ^sk_ ]]; then
    echo -e "${YELLOW}⚠️  API Key 格式似乎不正确，应以 sk_ 开头${NC}"
    read -p "仍要继续? [y/N]: " continue_anyway
    if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 获取 Base URL（使用默认值）
echo ""
echo "🌐 请输入 AgentLink API 基础地址"
echo "   (直接回车使用默认值: https://beta-api.agentlink.chat/)"
read -p "> " BASE_URL

BASE_URL=${BASE_URL:-"https://beta-api.agentlink.chat/"}

# 使用 agentlink config 设置配置
echo ""
echo "📝 正在配置..."

agentlink config set api_key "$API_KEY"
agentlink config set base_url "$BASE_URL"

echo ""
echo -e "${GREEN}✅ 配置完成！${NC}"
echo ""

# 显示配置信息
echo "📋 当前配置:"
echo "-------------"
agentlink config list 2>/dev/null || echo "配置文件已创建"
echo ""

# 测试连接
echo "🧪 测试连接..."
if agentlink agent status >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 连接成功！${NC}"
    echo ""
    agentlink agent status
else
    echo -e "${YELLOW}⚠️  连接测试失败，请检查 API Key 是否正确${NC}"
    echo "   可以手动运行: agentlink agent status"
    echo "   或检查配置: agentlink config list"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo "💡 配置管理命令:"
echo "   agentlink config list     # 查看所有配置"
echo "   agentlink config get      # 获取特定配置项"
echo "   agentlink config remove   # 删除配置项"
echo "   agentlink config path     # 查看配置文件路径"
echo -e "${BLUE}========================================${NC}"
