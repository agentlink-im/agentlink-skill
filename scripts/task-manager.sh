#!/bin/bash
#
# 任务批量管理脚本
# 用于快速查看、完成、清理 AgentLink 任务
#
# 使用方法:
#   ./task-manager.sh list              # 查看所有任务
#   ./task-manager.sh complete-all      # 批量完成 pending 任务
#   ./task-manager.sh clear-completed   # 清理已完成的任务
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
    exit 1
fi

# 获取任务列表
get_tasks() {
    agentlink -f json tasks list 2>/dev/null || echo "[]"
}

# 显示任务列表
list_tasks() {
    echo ""
    echo "╔════════════════════════════════╗"
    echo "║      📋 任务状态看板            ║"
    echo "╚════════════════════════════════╝"
    echo ""
    
    TASKS=$(get_tasks)
    
    # 待处理任务
    PENDING_COUNT=$(echo "$TASKS" | jq '[.[] | select(.status=="pending")] | length')
    if [ "$PENDING_COUNT" -gt 0 ]; then
        echo -e "🔴 待处理 (pending): ${YELLOW}$PENDING_COUNT${NC}"
        echo "$TASKS" | jq -r '.[] | select(.status=="pending") | "  • \(.title)"'
        echo ""
    fi
    
    # 进行中任务
    PROGRESS_COUNT=$(echo "$TASKS" | jq '[.[] | select(.status=="in_progress")] | length')
    if [ "$PROGRESS_COUNT" -gt 0 ]; then
        echo -e "🟡 进行中 (in_progress): ${YELLOW}$PROGRESS_COUNT${NC}"
        echo "$TASKS" | jq -r '.[] | select(.status=="in_progress") | "  • \(.title)"'
        echo ""
    fi
    
    # 已完成任务
    COMPLETED_COUNT=$(echo "$TASKS" | jq '[.[] | select(.status=="completed")] | length')
    if [ "$COMPLETED_COUNT" -gt 0 ]; then
        echo -e "🟢 已完成 (completed): ${GREEN}$COMPLETED_COUNT${NC}"
        echo "$TASKS" | jq -r '.[] | select(.status=="completed") | "  • \(.title)"'
        echo ""
    fi
    
    # 总计
    TOTAL=$(echo "$TASKS" | jq 'length')
    echo "═══════════════════════════════════"
    echo -e "总计: ${BLUE}$TOTAL${NC} | 待处理: ${YELLOW}$PENDING_COUNT${NC} | 进行中: ${YELLOW}$PROGRESS_COUNT${NC} | 已完成: ${GREEN}$COMPLETED_COUNT${NC}"
    echo ""
}

# 批量完成 pending 任务
complete_all_pending() {
    echo -e "${BLUE}正在获取 pending 任务列表...${NC}"
    
    TASKS=$(get_tasks)
    PENDING_IDS=$(echo "$TASKS" | jq -r '.[] | select(.status=="pending") | .id')
    
    if [ -z "$PENDING_IDS" ]; then
        echo -e "${YELLOW}没有 pending 状态的任务${NC}"
        return 0
    fi
    
    COUNT=$(echo "$PENDING_IDS" | wc -l)
    echo -e "发现 ${YELLOW}$COUNT${NC} 个 pending 任务"
    echo ""
    
    CONFIRM=""
    read -p "确认全部标记为 completed? [y/N]: " CONFIRM
    
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        echo "已取消"
        return 0
    fi
    
    echo ""
    echo "开始更新任务状态..."
    
    SUCCESS=0
    FAILED=0
    
    for id in $PENDING_IDS; do
        echo -n "更新任务 $id... "
        if agentlink tasks update "$id" --status completed >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
            SUCCESS=$((SUCCESS + 1))
        else
            echo -e "${RED}✗${NC}"
            FAILED=$((FAILED + 1))
        fi
        sleep 0.3
    done
    
    echo ""
    echo -e "${GREEN}✓ 成功: $SUCCESS${NC}"
    if [ $FAILED -gt 0 ]; then
        echo -e "${RED}✗ 失败: $FAILED${NC}"
    fi
}

# 清理已完成的任务
clear_completed() {
    echo -e "${BLUE}正在获取 completed 任务列表...${NC}"
    
    TASKS=$(get_tasks)
    COMPLETED_IDS=$(echo "$TASKS" | jq -r '.[] | select(.status=="completed") | .id')
    
    if [ -z "$COMPLETED_IDS" ]; then
        echo -e "${YELLOW}没有 completed 状态的任务${NC}"
        return 0
    fi
    
    COUNT=$(echo "$COMPLETED_IDS" | wc -l)
    echo -e "发现 ${GREEN}$COUNT${NC} 个 completed 任务"
    echo ""
    
    CONFIRM=""
    read -p "确认删除这些任务? [y/N]: " CONFIRM
    
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        echo "已取消"
        return 0
    fi
    
    echo ""
    echo "开始删除任务..."
    
    SUCCESS=0
    FAILED=0
    
    for id in $COMPLETED_IDS; do
        echo -n "删除任务 $id... "
        if agentlink tasks delete "$id" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
            SUCCESS=$((SUCCESS + 1))
        else
            echo -e "${RED}✗${NC}"
            FAILED=$((FAILED + 1))
        fi
        sleep 0.3
    done
    
    echo ""
    echo -e "${GREEN}✓ 成功删除: $SUCCESS${NC}"
    if [ $FAILED -gt 0 ]; then
        echo -e "${RED}✗ 失败: $FAILED${NC}"
    fi
}

# 主命令处理
case "${1:-}" in
    list|ls|"")
        list_tasks
        ;;
    complete-all|done)
        complete_all_pending
        ;;
    clear-completed|clean)
        clear_completed
        ;;
    help|-h|--help)
        echo "任务批量管理脚本"
        echo ""
        echo "用法: $0 [命令]"
        echo ""
        echo "命令:"
        echo "  list              查看所有任务（默认）"
        echo "  complete-all      批量完成 pending 任务"
        echo "  clear-completed   清理已完成的任务"
        echo "  help              显示帮助信息"
        echo ""
        echo "任务状态: pending → in_progress → completed"
        ;;
    *)
        echo -e "${RED}未知命令: $1${NC}"
        echo "运行 '$0 help' 查看用法"
        exit 1
        ;;
esac
