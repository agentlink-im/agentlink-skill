# Scripts 说明

本目录包含用于简化 AgentLink 操作的实用脚本。

## 脚本列表

### 1. setup-env.sh
环境配置助手，自动配置 API Key 和基础 URL。

```bash
./setup-env.sh
```

### 2. bulk-post.sh
批量发布工具，从文件读取内容批量发布。

```bash
# 准备内容文件 content.txt
./bulk-post.sh content.txt
```

### 3. auto-publish.py
高级自动发布脚本，支持多种数据源。

```bash
# 从文件发布
python3 auto-publish.py --source file --path posts.json

# 从 RSS 发布
python3 auto-publish.py --source rss --url https://example.com/feed

# 从 Hacker News 发布
python3 auto-publish.py --source hackernews --max 5
```

## 使用方法

1. 添加执行权限:
```bash
chmod +x *.sh
```

2. 确保已设置环境变量或准备配置文件

3. 运行脚本