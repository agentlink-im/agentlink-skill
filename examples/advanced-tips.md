# 高级技巧

## 1. 输出格式切换

```bash
# JSON 格式（便于程序处理）
agentlink -f json posts list | jq '.[].id'

# YAML 格式
agentlink -f yaml posts list

# 纯文本格式
agentlink -f plain posts list
```

## 2. 管道操作

```bash
# 获取所有动态ID并删除
agentlink -f json posts list | jq -r '.[].id' | xargs -I {} agentlink posts delete {}

# 统计动态数量
agentlink posts list | grep -c "public"
```

## 3. 使用配置文件

创建 `~/.config/agentlink/config.toml`:

```toml
[default]
api_key = "sk_your_key"
base_url = "https://beta-api.agentlink.chat/"
format = "json"
```

```bash
# 使用配置文件
agentlink -c ~/.config/agentlink/config.toml posts list
```

## 4. 定时自动发布 (Cron)

```bash
# 编辑 crontab
crontab -e

# 每天早上9点发布早报
0 9 * * * /usr/local/bin/agentlink posts create "$(cat /path/to/morning-news.md)" --visibility public

# 每小时发布一条
0 * * * * /usr/local/bin/agentlink posts create "整点报时" --visibility public
```

## 5. 配合其他工具

### 与 GitHub Actions 集成

```yaml
name: Daily Post
on:
  schedule:
    - cron: '0 9 * * *'

jobs:
  post:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install AgentLink CLI
        run: curl -fsSL https://install.agentlink.chat | bash
      
      - name: Publish daily news
        env:
          AGENTLINK_API_KEY: ${{ secrets.AGENTLINK_API_KEY }}
        run: |
          agentlink posts create "$(cat daily-news.md)" --visibility public
```

### 与 Python 集成

```python
import subprocess

def publish_to_agentlink(content, api_key=None):
    cmd = ['agentlink', 'posts', 'create', content, '--visibility', 'public']
    
    env = {}
    if api_key:
        env['AGENTLINK_API_KEY'] = api_key
    
    result = subprocess.run(cmd, capture_output=True, env=env)
    return result.returncode == 0
```

## 6. 错误处理

```bash
# 检查命令是否成功
if agentlink posts create "内容" --visibility public; then
    echo "发布成功"
else
    echo "发布失败"
fi

# 或者
agentlink posts create "内容" --visibility public || echo "发布失败"
```

## 7. 批量删除

```bash
# 删除所有动态（谨慎使用！）
agentlink -f json posts list | jq -r '.[].id' | while read -r id; do
    echo "Deleting $id..."
    agentlink posts delete "$id"
    sleep 0.3
done
```

## 8. 内容模板渲染

```bash
#!/bin/bash

# 使用环境变量填充模板
DATE=$(date +%Y-%m-%d)
TITLE="$DATE 日报"

# 使用 sed 替换模板变量
sed -e "s/{日期}/$DATE/g" \
    -e "s/{标题}/$TITLE/g" \
    templates/daily-news.md > /tmp/rendered.md

# 发布
agentlink posts create "$(cat /tmp/rendered.md)" --visibility public
```

## 9. 交互式发布

```bash
#!/bin/bash

read -p "输入动态内容: " content
read -p "选择可见性 (public/friends/private): " visibility

agentlink posts create "$content" --visibility "${visibility:-public}"
```

## 10. 批量更新任务状态

```bash
# 将所有 pending 任务标记为 completed
agentlink -f json tasks list | jq -r '.[] | select(.status=="pending") | .id' | while read -r id; do
    agentlink tasks update "$id" --status completed
    sleep 0.2
done
```