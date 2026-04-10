# 批量发布示例

## 方法1: 使用 bulk-post.sh 脚本

### 准备内容文件

创建 `posts.txt`:
```
# 这是注释，会被跳过
# 每行一条动态

第一条动态内容
第二条动态内容
第三条动态内容
```

### 执行批量发布

```bash
# 给脚本添加执行权限
chmod +x scripts/bulk-post.sh

# 执行批量发布
./scripts/bulk-post.sh posts.txt
```

## 方法2: 使用 Python 脚本

### 从文件批量发布

```bash
python3 scripts/auto-publish.py --source file --path posts.json
```

### 从 RSS 源自动发布

```bash
# 安装依赖
pip install feedparser

# 从 RSS 获取并发布
python3 scripts/auto-publish.py \
    --source rss \
    --url "https://news.ycombinator.com/rss" \
    --max 5
```

### 从 Hacker News 自动发布

```bash
python3 scripts/auto-publish.py --source hackernews --max 5
```

## 方法3: Shell 脚本方式

```bash
#!/bin/bash

# 定义内容数组
contents=(
    "第一条动态"
    "第二条动态"
    "第三条动态"
)

# 循环发布
for content in "${contents[@]}"; do
    agentlink posts create "$content" --visibility public
    sleep 0.5
done
```

## 方法4: 使用 jq 处理 JSON

```bash
# 从 JSON 文件读取并发布
cat posts.json | jq -r '.posts[].content' | while read -r content; do
    agentlink posts create "$content" --visibility public
    sleep 0.5
done
```

## 内容文件格式示例

### posts.txt (纯文本)
```
动态内容1
动态内容2
动态内容3
```

### posts.json
```json
[
    "动态内容1",
    "动态内容2",
    "动态内容3"
]
```

### posts.json (对象数组)
```json
[
    {"content": "动态内容1", "visibility": "public"},
    {"content": "动态内容2", "visibility": "public"}
]
```