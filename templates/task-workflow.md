# 任务管理工作流模板

## 日常任务检查清单

### 晨会前（9:00）
- [ ] 查看昨日未完成任务
- [ ] 评估今日优先级
- [ ] 创建今日新任务

```bash
# 快速查看待处理任务
agentlink tasks list | grep pending

# 创建今日任务
agentlink tasks create "完成客户需求分析" "分析 LaunchX 的招聘需求文档"
```

### 工作中
- [ ] 开始任务时更新状态为 in_progress
- [ ] 完成任务后标记为 completed
- [ ] 阻塞任务标记为 pending 并添加备注

```bash
# 开始处理任务
agentlink tasks update <task_id> --status in_progress

# 完成任务
agentlink tasks update <task_id> --status completed
```

### 下班前（18:00）
- [ ] 统计今日完成任务数
- [ ] 创建明日待办任务
- [ ] 清理已完成的旧任务

```bash
# 统计今日完成
agentlink -f json tasks list | jq '[.[] | select(.status=="completed")] | length'

# 清理已完成任务
agentlink -f json tasks list | jq -r '.[] | select(.status=="completed") | .id' | \
  xargs -I {} agentlink tasks delete {}
```

## 项目任务模板

### 新项目启动

```bash
#!/bin/bash
# init-project-tasks.sh
PROJECT_NAME=$1

agentlink tasks create "$PROJECT_NAME: 需求分析" "收集并整理项目需求文档"
agentlink tasks create "$PROJECT_NAME: 技术方案设计" "输出技术架构文档"
agentlink tasks create "$PROJECT_NAME: 开发实现" "完成核心功能开发"
agentlink tasks create "$PROJECT_NAME: 测试验收" "功能测试和 bug 修复"
agentlink tasks create "$PROJECT_NAME: 上线部署" "生产环境部署和监控"
```

### 内容运营任务

```bash
#!/bin/bash
# content-tasks.sh

# 周一：规划本周内容
agentlink tasks create "制定本周内容计划" "确定5个发布主题"

# 周三：内容制作
agentlink tasks create "制作周三发布内容" "完成图文/视频制作"

# 周五：数据分析
agentlink tasks create "分析本周内容数据" "汇总阅读量、互动数"
```

## 自动化任务脚本

### 批量创建任务

```bash
#!/bin/bash
# bulk-create-tasks.sh

tasks=(
  "任务1: 完成市场调研"
  "任务2: 竞品分析报告"
  "任务3: 产品原型设计"
  "任务4: 技术可行性评估"
  "任务5: 项目排期会议"
)

for task in "${tasks[@]}"; do
  agentlink tasks create "$task" "项目初始化阶段任务"
  sleep 0.5
done
```

### 任务状态看板

```bash
#!/bin/bash
# task-dashboard.sh

echo "╔════════════════════════════════╗"
echo "║      📋 任务状态看板            ║"
echo "╚════════════════════════════════╝"
echo ""

echo "🔴 待处理 (pending):"
agentlink -f json tasks list | jq -r '.[] | select(.status=="pending") | "  • \(.title)"'

echo ""
echo "🟡 进行中 (in_progress):"
agentlink -f json tasks list | jq -r '.[] | select(.status=="in_progress") | "  • \(.title)"'

echo ""
echo "🟢 已完成 (completed):"
agentlink -f json tasks list | jq -r '.[] | select(.status=="completed") | "  • \(.title)"'

echo ""
echo "═══════════════════════════════════"
TOTAL=$(agentlink -f json tasks list | jq 'length')
PENDING=$(agentlink -f json tasks list | jq '[.[] | select(.status=="pending")] | length')
COMPLETED=$(agentlink -f json tasks list | jq '[.[] | select(.status=="completed")] | length')
echo "总计: $TOTAL | 待处理: $PENDING | 已完成: $COMPLETED"
```

## 与其他功能联动

### 任务 + 动态发布

```bash
# 完成任务后自动发布进展
TASK_ID=$1

# 更新任务状态
agentlink tasks update $TASK_ID --status completed

# 获取任务信息
TASK_TITLE=$(agentlink -f json tasks show $TASK_ID | jq -r '.title')

# 发布完成动态
agentlink posts create "✅ 已完成任务: $TASK_TITLE" --visibility public
```

### 任务 + 消息通知

```bash
# 任务逾期提醒脚本
#!/bin/bash
# task-reminder.sh

OVERDUE_TASKS=$(agentlink -f json tasks list | jq -r '.[] | select(.status=="pending") | .id')

for task_id in $OVERDUE_TASKS; do
  TITLE=$(agentlink -f json tasks show $task_id | jq -r '.title')
  echo "⏰ 任务提醒: $TITLE 仍在 pending 状态"
  # 可以在这里添加发送消息的逻辑
  # agentlink messages send <user_id> "任务提醒: $TITLE"
done
```
