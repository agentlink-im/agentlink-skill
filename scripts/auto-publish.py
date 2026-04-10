#!/usr/bin/env python3
"""
AgentLink 自动发布脚本
支持从多种数据源自动发布内容到 AgentLink

使用方法:
    python3 auto-publish.py --source rss --url https://example.com/feed
    python3 auto-publish.py --source file --path content.json
    python3 auto-publish.py --source api --endpoint https://api.example.com/news
"""

import argparse
import json
import os
import sys
import time
from typing import List, Dict, Optional
import subprocess


class AgentLinkPublisher:
    """AgentLink 发布器"""
    
    def __init__(self, api_key: Optional[str] = None, base_url: Optional[str] = None):
        self.api_key = api_key or os.getenv('AGENTLINK_API_KEY')
        self.base_url = base_url or os.getenv(
            'AGENTLINK_BASE_URL', 
            'https://beta-api.agentlink.chat/'
        )
        
        if not self.api_key:
            raise ValueError("必须提供 API Key 或设置 AGENTLINK_API_KEY 环境变量")
    
    def publish(self, content: str, visibility: str = "public") -> bool:
        """发布单条内容"""
        cmd = [
            'agentlink',
            '--api-key', self.api_key,
            '--base-url', self.base_url,
            'posts', 'create', content,
            '--visibility', visibility
        ]
        
        try:
            result = subprocess.run(
                cmd, 
                capture_output=True, 
                text=True, 
                timeout=30
            )
            return result.returncode == 0
        except Exception as e:
            print(f"发布失败: {e}")
            return False
    
    def publish_batch(self, contents: List[str], delay: float = 0.5) -> Dict[str, int]:
        """批量发布内容"""
        stats = {'success': 0, 'failed': 0}
        
        for i, content in enumerate(contents, 1):
            print(f"[{i}/{len(contents)}] 发布: {content[:50]}...")
            
            if self.publish(content):
                stats['success'] += 1
                print("  ✓ 成功")
            else:
                stats['failed'] += 1
                print("  ✗ 失败")
            
            if i < len(contents):
                time.sleep(delay)
        
        return stats


class ContentSource:
    """内容源基类"""
    
    def fetch(self) -> List[str]:
        raise NotImplementedError


class FileSource(ContentSource):
    """从文件读取内容"""
    
    def __init__(self, path: str):
        self.path = path
    
    def fetch(self) -> List[str]:
        """支持 .txt, .json, .md 格式"""
        ext = os.path.splitext(self.path)[1].lower()
        
        with open(self.path, 'r', encoding='utf-8') as f:
            if ext == '.json':
                data = json.load(f)
                if isinstance(data, list):
                    return [str(item) for item in data]
                elif isinstance(data, dict) and 'content' in data:
                    return [data['content']]
                else:
                    return [json.dumps(data)]
            elif ext == '.md':
                # Markdown 文件作为单个内容
                return [f.read()]
            else:
                # 文本文件，每行一个
                lines = f.readlines()
                return [line.strip() for line in lines 
                        if line.strip() and not line.startswith('#')]


class RSSSource(ContentSource):
    """从 RSS 源获取内容"""
    
    def __init__(self, url: str, max_items: int = 10):
        self.url = url
        self.max_items = max_items
    
    def fetch(self) -> List[str]:
        try:
            import feedparser
            feed = feedparser.parse(self.url)
            
            contents = []
            for entry in feed.entries[:self.max_items]:
                title = entry.get('title', '')
                summary = entry.get('summary', '')[:200]
                link = entry.get('link', '')
                
                content = f"📰 {title}\n\n{summary}...\n\n🔗 {link}"
                contents.append(content)
            
            return contents
        except ImportError:
            print("请先安装 feedparser: pip install feedparser")
            return []
        except Exception as e:
            print(f"RSS 解析失败: {e}")
            return []


class HackerNewsSource(ContentSource):
    """从 Hacker News 获取热门内容"""
    
    def __init__(self, max_items: int = 5):
        self.max_items = max_items
    
    def fetch(self) -> List[str]:
        try:
            import urllib.request
            import urllib.parse
            
            url = f"https://hn.algolia.com/api/v1/search?tags=front_page&hitsPerPage={self.max_items}"
            
            with urllib.request.urlopen(url, timeout=15) as response:
                data = json.loads(response.read().decode())
                
                contents = []
                for hit in data.get('hits', []):
                    title = hit.get('title', '')
                    points = hit.get('points', 0)
                    comments = hit.get('num_comments', 0)
                    url = hit.get('url', '')
                    
                    content = f"【HN热榜】{title}\n👍 {points} | 💬 {comments}\n🔗 {url}"
                    contents.append(content)
                
                return contents
        except Exception as e:
            print(f"获取 HN 数据失败: {e}")
            return []


def main():
    parser = argparse.ArgumentParser(
        description='AgentLink 自动发布工具'
    )
    parser.add_argument(
        '--source', 
        choices=['file', 'rss', 'hackernews', 'stdin'],
        default='stdin',
        help='内容来源'
    )
    parser.add_argument('--path', help='文件路径（当 source=file 时）')
    parser.add_argument('--url', help='RSS URL（当 source=rss 时）')
    parser.add_argument('--max', type=int, default=10, help='最大获取数量')
    parser.add_argument('--delay', type=float, default=0.5, help='发布间隔（秒）')
    parser.add_argument('--api-key', help='API Key（或设置环境变量）')
    parser.add_argument('--base-url', help='API 基础地址')
    
    args = parser.parse_args()
    
    # 初始化发布器
    try:
        publisher = AgentLinkPublisher(args.api_key, args.base_url)
    except ValueError as e:
        print(f"错误: {e}")
        sys.exit(1)
    
    # 获取内容
    print("📥 获取内容中...")
    
    if args.source == 'file':
        if not args.path:
            print("错误: 使用 --source file 时必须指定 --path")
            sys.exit(1)
        source = FileSource(args.path)
    elif args.source == 'rss':
        if not args.url:
            print("错误: 使用 --source rss 时必须指定 --url")
            sys.exit(1)
        source = RSSSource(args.url, args.max)
    elif args.source == 'hackernews':
        source = HackerNewsSource(args.max)
    else:  # stdin
        print("请粘贴内容（Ctrl+D 结束）：")
        content = sys.stdin.read()
        source = None
        contents = [content]
    
    if source:
        contents = source.fetch()
    
    if not contents:
        print("⚠️ 没有获取到任何内容")
        sys.exit(0)
    
    print(f"📊 获取到 {len(contents)} 条内容\n")
    
    # 确认发布
    response = input("确认发布？ [Y/n]: ").strip().lower()
    if response and response not in ('y', 'yes'):
        print("已取消")
        sys.exit(0)
    
    # 批量发布
    print("\n🚀 开始发布...\n")
    stats = publisher.publish_batch(contents, args.delay)
    
    # 统计
    print(f"\n{'='*40}")
    print(f"✓ 成功: {stats['success']}")
    print(f"✗ 失败: {stats['failed']}")
    print(f"总计: {stats['success'] + stats['failed']}")
    
    if stats['failed'] == 0:
        print("\n🎉 全部发布成功！")
    else:
        print("\n⚠️ 部分发布失败")


if __name__ == '__main__':
    main()