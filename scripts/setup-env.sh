#!/bin/bash
#
# AgentLink 环境配置脚本
# 自动检测 shell 并配置环境变量
#

set -e

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   AgentLink 环境配置助手${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检测 shell
SHELL_TYPE=$(basename "$SHELL")
echo "🔍 检测到 Shell: $SHELL_TYPE"

# 确定配置文件
if [ "$SHELL_TYPE" = "zsh" ]; then
    CONFIG_FILE="$HOME/.zshrc"
elif [ "$SHELL_TYPE" = "bash" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        CONFIG_FILE="$HOME/.bashrc"
    else
        CONFIG_FILE="$HOME/.bash_profile"
    fi
else
    CONFIG_FILE="$HOME/.profile"
fi

echo "📝 将配置写入: $CONFIG_FILE"
echo ""

# 检查是否已配置
if grep -q "AGENTLINK_API_KEY" "$CONFIG_FILE" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  检测到已有 AgentLink 配置${NC}"
    read -p "是否覆盖? [y/N]: " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 0
    fi
    # 删除旧配置
    sed -i '/# AgentLink Config/d' "$CONFIG_FILE" 2>/dev/null || true
    sed -i '/AGENTLINK_API_KEY/d' "$CONFIG_FILE" 2>/dev/null || true
    sed -i '/AGENTLINK_BASE_URL/d' "$CONFIG_FILE" 2>/dev/null || true
fi

# 获取 API Key
echo ""
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

# 写入配置
echo "" >> "$CONFIG_FILE"
echo "# AgentLink Config" >> "$CONFIG_FILE"
echo "export AGENTLINK_API_KEY=\"$API_KEY\"" >> "$CONFIG_FILE"
echo "export AGENTLINK_BASE_URL=\"$BASE_URL\"" >> "$CONFIG_FILE"

echo ""
echo -e "${GREEN}✅ 配置已写入 $CONFIG_FILE${NC}"
echo ""

# 立即生效
echo "🔄 正在加载配置..."
export AGENTLINK_API_KEY="$API_KEY"
export AGENTLINK_BASE_URL="$BASE_URL"

# 测试连接
echo ""
echo "🧪 测试连接..."
if agentlink agent status >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 连接成功！${NC}"
    echo ""
    agentlink agent status
else
    echo -e "${YELLOW}⚠️  连接测试失败，请检查 API Key 是否正确${NC}"
    echo "   可以手动运行: agentlink agent status"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo "💡 提示: 运行以下命令使配置永久生效:"
echo "   source $CONFIG_FILE"
echo -e "${BLUE}========================================${NC}"