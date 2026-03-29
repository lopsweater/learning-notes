# 版本控制历史分析方案

## 目录
1. [SVN 提交记录分析](#1-svn-提交记录分析)
2. [Git 历史分析工具](#2-git-历史分析工具)
3. [变更历史文档化](#3-变更历史文档化)
4. [推荐工具链与工作流](#4-推荐工具链与工作流)

---

## 1. SVN 提交记录分析

### 1.1 svn log 解析方法

#### 基础命令解析

```bash
# 获取完整提交历史
svn log -v --xml > svn_log.xml

# 按时间范围过滤
svn log -v -r {2024-01-01}:{2024-12-31}

# 按作者过滤
svn log --search "author_name"

# 限制条数
svn log -l 100
```

#### XML 输出解析（推荐）

```xml
<!-- svn log -v --xml 输出格式 -->
<log>
  <logentry revision="12345">
    <author>username</author>
    <date>2024-06-15T10:30:00.000000Z</date>
    <msg>提交消息内容</msg>
    <paths>
      <path action="M" kind="file">/trunk/src/main.py</path>
      <path action="A" kind="file">/trunk/src/new_file.py</path>
      <path action="D" kind="file">/trunk/src/old_file.py</path>
    </paths>
  </logentry>
</log>
```

#### Python 解析脚本示例

```python
import xml.etree.ElementTree as ET
from datetime import datetime
from collections import defaultdict

def parse_svn_log(xml_file):
    """解析 SVN XML 日志文件"""
    tree = ET.parse(xml_file)
    root = tree.getroot()
    
    commits = []
    for logentry in root.findall('logentry'):
        commit = {
            'revision': int(logentry.get('revision')),
            'author': logentry.find('author').text,
            'date': datetime.fromisoformat(
                logentry.find('date').text.replace('Z', '+00:00')
            ),
            'message': logentry.find('msg').text or '',
            'paths': []
        }
        
        for path in logentry.findall('.//path'):
            commit['paths'].append({
                'action': path.get('action'),  # M=修改, A=添加, D=删除
                'kind': path.get('kind'),      # file/dir
                'path': path.text
            })
        
        commits.append(commit)
    
    return commits

def analyze_by_author(commits):
    """按作者统计"""
    stats = defaultdict(lambda: {'commits': 0, 'files_changed': 0})
    for commit in commits:
        stats[commit['author']]['commits'] += 1
        stats[commit['author']]['files_changed'] += len(commit['paths'])
    return dict(stats)

def analyze_by_module(commits, module_prefix='/trunk/'):
    """按模块统计"""
    modules = defaultdict(lambda: {'commits': set(), 'files': set()})
    for commit in commits:
        for path_info in commit['paths']:
            path = path_info['path']
            if path.startswith(module_prefix):
                # 提取模块名（如 /trunk/module1/src/ -> module1）
                parts = path[len(module_prefix):].split('/')
                if parts:
                    module = parts[0]
                    modules[module]['commits'].add(commit['revision'])
                    modules[module]['files'].add(path)
    
    # 转换为可序列化格式
    return {k: {
        'commit_count': len(v['commits']),
        'file_count': len(v['files'])
    } for k, v in modules.items()}
```

### 1.2 提交统计工具

#### StatSVN

**简介**：Java 编写的 SVN 统计工具，生成 HTML 报告

**安装**：
```bash
# 下载最新版本
wget https://downloads.sourceforge.net/project/statsvn/statsvn/0.7.0/statsvn-0.7.0.zip
unzip statsvn-0.7.0.zip

# 或使用包管理器
# macOS
brew install statsvn

# 需要Java运行时
sudo apt install default-jre  # Ubuntu/Debian
```

**使用**：
```bash
# 1. 导出 SVN 日志
svn log -v --xml > svn_log.xml

# 2. 检出代码（用于统计代码行数）
svn checkout https://svn.example.com/repo/trunk checkout_dir

# 3. 生成报告
java -jar statsvn.jar svn_log.xml checkout_dir -output-dir ./stats-report

# 高级选项
java -jar statsvn.jar svn_log.xml checkout_dir \
  -output-dir ./report \
  -include "*.java:*.py:*.js" \
  -exclude "*.min.js:*.generated.*" \
  -title "项目名称统计分析" \
  -viewsafe  # 只显示可访问的路径
```

**输出内容**：
- 提交者活动统计（LOC、提交次数）
- 文件/目录修改频率
- 代码行数变化趋势图
- 时间线视图
- 作者贡献比例饼图

#### svnplot

**简介**：Python 编写的 SVN 可视化工具，生成静态图表

**安装**：
```bash
pip install svnplot

# 或从源码安装
git clone https://github.com/thma/svnplot.git
cd svnplot
python setup.py install
```

**使用**：
```bash
# 生成 SQLite 数据库
svnlog2sqlite -u https://svn.example.com/repo svn_stats.db

# 生成 HTML 报告
svnplot -d svn_stats.db -o ./svnplot-report

# 可选参数
svnplot -d svn_stats.db -o ./report \
  --title "项目名称" \
  --startdate "2024-01-01" \
  --enddate "2024-12-31"
```

**特点**：
- 基于 SQLite 存储，便于二次分析
- 使用 matplotlib 生成图表
- 支持自定义时间范围
- 轻量级，无 Java 依赖

#### svn-stats（轻量级替代）

```bash
# 安装
npm install -g svn-stats

# 使用
svn-stats https://svn.example.com/repo --output ./report
```

### 1.3 按模块/作者/时间的变更统计

#### 综合分析脚本

```python
#!/usr/bin/env python3
"""
SVN 综合统计脚本
依赖: pip install pandas matplotlib
"""

import xml.etree.ElementTree as ET
from datetime import datetime, timedelta
from collections import defaultdict
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

class SVNAnalyzer:
    def __init__(self, xml_file):
        self.commits = self._parse_xml(xml_file)
    
    def _parse_xml(self, xml_file):
        """解析 SVN XML 日志"""
        tree = ET.parse(xml_file)
        root = tree.getroot()
        commits = []
        
        for entry in root.findall('logentry'):
            date_str = entry.find('date').text
            date = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
            
            paths = []
            for path in entry.findall('.//path'):
                paths.append({
                    'action': path.get('action'),
                    'path': path.text
                })
            
            commits.append({
                'revision': int(entry.get('revision')),
                'author': entry.find('author').text or 'unknown',
                'date': date,
                'message': (entry.find('msg').text or '').strip(),
                'paths': paths
            })
        
        return sorted(commits, key=lambda x: x['date'])
    
    def stats_by_author(self):
        """按作者统计"""
        stats = defaultdict(lambda: {
            'commits': 0, 'additions': 0, 
            'modifications': 0, 'deletions': 0
        })
        
        for c in self.commits:
            author = c['author']
            stats[author]['commits'] += 1
            for p in c['paths']:
                action = p['action']
                if action == 'A':
                    stats[author]['additions'] += 1
                elif action == 'M':
                    stats[author]['modifications'] += 1
                elif action == 'D':
                    stats[author]['deletions'] += 1
        
        return pd.DataFrame.from_dict(stats, orient='index')
    
    def stats_by_time(self, freq='M'):
        """按时间统计（D=日, W=周, M=月, Q=季度, Y=年）"""
        df = pd.DataFrame(self.commits)
        df['date'] = pd.to_datetime(df['date'])
        df.set_index('date', inplace=True)
        
        return df.resample(freq).agg({
            'revision': 'count',
            'paths': lambda x: sum(len(p) for p in x)
        }).rename(columns={
            'revision': 'commits',
            'paths': 'files_changed'
        })
    
    def stats_by_module(self, trunk_path='/trunk/'):
        """按模块统计"""
        modules = defaultdict(lambda: {
            'commits': set(), 'files': set(), 'authors': set()
        })
        
        for c in self.commits:
            for p in c['paths']:
                path = p['path']
                if trunk_path in path:
                    # 提取模块名
                    relative = path.split(trunk_path)[-1]
                    parts = relative.split('/')
                    module = parts[0] if parts else 'root'
                    
                    modules[module]['commits'].add(c['revision'])
                    modules[module]['files'].add(path)
                    modules[module]['authors'].add(c['author'])
        
        return pd.DataFrame({
            module: {
                'commit_count': len(data['commits']),
                'file_count': len(data['files']),
                'author_count': len(data['authors'])
            }
            for module, data in modules.items()
        }).T
    
    def activity_timeline(self, output_file='activity.png'):
        """生成活动时间线图"""
        df = pd.DataFrame(self.commits)
        df['date'] = pd.to_datetime(df['date'])
        df['date_only'] = df['date'].dt.date
        
        daily = df.groupby('date_only').size()
        
        fig, ax = plt.subplots(figsize=(14, 5))
        daily.plot(ax=ax, kind='line', linewidth=0.8)
        
        ax.set_title('SVN 提交活动时间线')
        ax.set_xlabel('日期')
        ax.set_ylabel('提交次数')
        ax.xaxis.set_major_locator(mdates.MonthLocator())
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig(output_file, dpi=150)
        plt.close()
        
        return output_file
    
    def author_contribution_pie(self, output_file='authors.png'):
        """生成作者贡献饼图"""
        author_stats = self.stats_by_author()
        
        fig, ax = plt.subplots(figsize=(10, 8))
        author_stats['commits'].sort_values(ascending=False).head(15).plot(
            ax=ax, kind='pie', autopct='%1.1f%%', startangle=90
        )
        
        ax.set_title('作者提交贡献比例 (Top 15)')
        ax.set_ylabel('')
        plt.tight_layout()
        plt.savefig(output_file, dpi=150)
        plt.close()
        
        return output_file


# 使用示例
if __name__ == '__main__':
    analyzer = SVNAnalyzer('svn_log.xml')
    
    print("=== 按作者统计 ===")
    print(analyzer.stats_by_author())
    
    print("\n=== 按时间统计（月度）===")
    print(analyzer.stats_by_time('M'))
    
    print("\n=== 按模块统计 ===")
    print(analyzer.stats_by_module())
    
    analyzer.activity_timeline('activity.png')
    analyzer.author_contribution_pie('authors.png')
```

---

## 2. Git 历史分析工具

### 2.1 git-quick-stats

**简介**：交互式 Git 统计工具，提供丰富的终端可视化

**安装**：
```bash
# Linux/macOS
git clone https://github.com/arzzen/git-quick-stats.git
cd git-quick-stats
sudo make install

# 或使用包管理器
# macOS
brew install git-quick-stats

# Ubuntu/Debian (需要添加 PPA)
sudo add-apt-repository ppa:git-quick-stats/releases
sudo apt update
sudo apt install git-quick-stats

# Arch Linux
yay -S git-quick-stats
```

**使用**：
```bash
cd /path/to/git/repo

# 交互式菜单
git-quick-stats

# 直接命令
git-quick-stats --suggest-reviewers      # 推荐代码审查者
git-quick-stats --detailed-git-stats     # 详细统计
git-quick-stats --commits-per-day        # 每日提交分布
git-quick-stats --commits-by-month       # 月度提交统计
git-quick-stats --commits-by-author      # 按作者统计
git-quick-stats --commits-by-timezone    # 按时区统计
git-quick-stats --emails-by-author       # 作者邮箱列表

# 时间范围过滤
git-quick-stats --commits-by-month --since="2024-01-01" --until="2024-12-31"
```

**输出示例**：
```
Git Quick Stats
===============
Project name: my-project
Total commits: 1,234
Total authors: 15
Project age: 2 years, 3 months

Commits by author:
  John Doe        : 456 (36.9%)
  Jane Smith      : 321 (26.0%)
  Bob Johnson     : 234 (19.0%)
  ...

Most active files:
  src/main.py     : 89 commits
  src/utils.py    : 67 commits
  README.md       : 45 commits
```

### 2.2 git-stats

**简介**：Node.js 编写的 Git 统计工具，生成 HTML 报告

**安装**：
```bash
npm install -g git-stats

# 或使用 yarn
yarn global add git-stats
```

**使用**：
```bash
# 当前仓库统计
git-stats

# 生成 HTML 报告
git-stats --output ./git-stats-report

# 指定仓库
git-stats --repo /path/to/repo --output ./report

# 指定时间范围
git-stats --since "2024-01-01" --until "2024-12-31"
```

**特点**：
- 生成美观的 HTML 报告
- 支持作者贡献日历视图（类似 GitHub 贡献图）
- 代码行数统计
- 提交频率分析

#### git-stats alternative: git-standup

```bash
# 安装
npm install -g git-standup

# 查看最近 N 天的提交
git standup -a "author_name" -d 7

# 团队周报
git standup -d 7 -D "yyyy-MM-dd"
```

### 2.3 Git 成熟度分析

#### 成熟度指标体系

```python
#!/usr/bin/env python3
"""
Git 仓库成熟度评估脚本
"""

import subprocess
import json
from datetime import datetime, timedelta
from collections import defaultdict

class GitMaturityAnalyzer:
    def __init__(self, repo_path='.'):
        self.repo_path = repo_path
    
    def run_git(self, *args):
        """执行 git 命令"""
        cmd = ['git', '-C', self.repo_path] + list(args)
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stdout.strip()
    
    def analyze_commit_frequency(self):
        """分析提交频率"""
        # 获取最近一年的提交
        log = self.run_git('log', '--since=1 year ago', '--pretty=format:%ad', '--date=short')
        if not log:
            return {'score': 0, 'avg_per_week': 0}
        
        dates = log.split('\n')
        weeks = len(set(dates)) / 52  # 活跃周数占比
        
        # 计算平均每周提交
        commits_per_week = len(dates) / 52
        
        # 评分：活跃周数 + 提交频率
        score = min(100, weeks * 50 + min(50, commits_per_week * 5))
        
        return {
            'score': score,
            'active_weeks': len(set(dates)),
            'total_commits': len(dates),
            'avg_per_week': round(commits_per_week, 2)
        }
    
    def analyze_author_diversity(self):
        """分析作者多样性"""
        log = self.run_git('log', '--pretty=format:%ae')
        if not log:
            return {'score': 0, 'author_count': 0}
        
        authors = set(log.split('\n'))
        author_count = len(authors)
        
        # 计算贡献集中度（基尼系数）
        commits_per_author = defaultdict(int)
        for author in log.split('\n'):
            commits_per_author[author] += 1
        
        # 理想状态：3-10 个活跃开发者
        score = min(100, author_count * 10)
        if author_count > 10:
            score = 100  # 已是大型团队
        
        return {
            'score': score,
            'author_count': author_count,
            'top_author_share': max(commits_per_author.values()) / len(log.split('\n'))
        }
    
    def analyze_branch_strategy(self):
        """分析分支策略"""
        branches = self.run_git('branch', '-a')
        branch_count = len([b for b in branches.split('\n') if b.strip()])
        
        # 检查是否有 main/master, develop, feature 分支模式
        has_main = 'main' in branches or 'master' in branches
        has_develop = 'develop' in branches
        has_feature = any('feature' in b for b in branches.split('\n'))
        
        # 评分
        score = 0
        if has_main:
            score += 40
        if has_develop:
            score += 30
        if has_feature:
            score += 30
        
        return {
            'score': score,
            'branch_count': branch_count,
            'has_main_branch': has_main,
            'has_develop_branch': has_develop,
            'has_feature_branches': has_feature
        }
    
    def analyze_commit_quality(self):
        """分析提交质量"""
        # 检查提交消息格式
        log = self.run_git('log', '--pretty=format:%s', '-100')
        messages = log.split('\n')
        
        # 检查是否有规范的提交消息（如 Conventional Commits）
        conventional_pattern = r'^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?:'
        import re
        
        conventional_count = sum(
            1 for msg in messages 
            if re.match(conventional_pattern, msg)
        )
        
        # 检查消息长度（合理范围 10-72 字符）
        good_length = sum(1 for msg in messages if 10 <= len(msg) <= 72)
        
        conventional_ratio = conventional_count / len(messages) if messages else 0
        length_ratio = good_length / len(messages) if messages else 0
        
        score = conventional_ratio * 50 + length_ratio * 50
        
        return {
            'score': round(score, 2),
            'conventional_commit_ratio': round(conventional_ratio, 2),
            'good_message_length_ratio': round(length_ratio, 2)
        }
    
    def analyze_file_changes(self):
        """分析文件变更模式"""
        # 获取最近 100 次提交的文件变更
        log = self.run_git('log', '--name-only', '--pretty=format:', '-100')
        files = [f for f in log.split('\n') if f.strip()]
        
        # 统计文件修改频率
        file_freq = defaultdict(int)
        for f in files:
            if f:
                file_freq[f] += 1
        
        # 检测热点文件（修改次数 > 10）
        hotspots = {f: c for f, c in file_freq.items() if c > 10}
        
        # 理想状态：热点文件 < 10%
        hotspot_ratio = len(hotspots) / len(file_freq) if file_freq else 0
        
        score = max(0, 100 - hotspot_ratio * 100)
        
        return {
            'score': round(score, 2),
            'unique_files': len(file_freq),
            'hotspot_count': len(hotspots),
            'top_files': dict(sorted(file_freq.items(), key=lambda x: x[1], reverse=True)[:5])
        }
    
    def calculate_maturity_score(self):
        """计算综合成熟度得分"""
        metrics = {
            'commit_frequency': self.analyze_commit_frequency(),
            'author_diversity': self.analyze_author_diversity(),
            'branch_strategy': self.analyze_branch_strategy(),
            'commit_quality': self.analyze_commit_quality(),
            'file_changes': self.analyze_file_changes()
        }
        
        # 加权平均
        weights = {
            'commit_frequency': 0.25,
            'author_diversity': 0.20,
            'branch_strategy': 0.20,
            'commit_quality': 0.20,
            'file_changes': 0.15
        }
        
        total_score = sum(
            metrics[k]['score'] * weights[k] 
            for k in weights
        )
        
        # 成熟度等级
        if total_score >= 80:
            level = "优秀 (Excellent)"
        elif total_score >= 60:
            level = "良好 (Good)"
        elif total_score >= 40:
            level = "一般 (Fair)"
        else:
            level = "需改进 (Needs Improvement)"
        
        return {
            'total_score': round(total_score, 2),
            'maturity_level': level,
            'metrics': metrics
        }


# 使用示例
if __name__ == '__main__':
    analyzer = GitMaturityAnalyzer('/path/to/repo')
    result = analyzer.calculate_maturity_score()
    
    print(json.dumps(result, indent=2, ensure_ascii=False))
```

### 2.4 代码演化可视化

#### Gource

**简介**：实时可视化代码演化，生成动态视频

**安装**：
```bash
# Ubuntu/Debian
sudo apt install gource

# macOS
brew install gource

# Windows (使用 Scoop)
scoop install gource

# FFmpeg（用于录制视频）
sudo apt install ffmpeg
# 或
brew install ffmpeg
```

**使用**：
```bash
# 实时预览
gource /path/to/git/repo

# 常用参数
gource /path/to/repo \
  --viewport 1920x1080 \
  --auto-skip-seconds 1 \
  --seconds-per-day 0.5 \
  --title "项目演化历程" \
  --logo logo.png \
  --background 000000 \
  --date-format "%Y-%m-%d" \
  --user-image-dir ./avatars/ \
  --hide filenames \
  --max-files 500

# 录制视频
gource /path/to/repo \
  -1920x1080 \
  --auto-skip-seconds 0.1 \
  --seconds-per-day 0.5 \
  --stop-at-end \
  --output-ppm-stream - \
  | ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - \
    -vcodec libx264 -preset medium -pix_fmt yuv420p \
    -crf 18 "project_evolution.mp4"

# SVN 仓库支持（需要先转换）
# 安装 svn2git 或使用 git-svn
git svn clone https://svn.example.com/repo svn-repo
gource svn-repo

# 高级选项
gource /path/to/repo \
  --start-date "2024-01-01" \
  --stop-date "2024-12-31" \
  --highlight-all-users \
  --key \
  --bloom-multiplier 0.75 \
  --elasticity 0.2
```

**Gource 配置文件**：

```ini
# gource.conf
[display]
viewport = 1920x1080
fullscreen = false
background = 0F0F23

[time]
auto-skip-seconds = 1
seconds-per-day = 0.5
stop-at-end = true

[visuals]
title = 项目代码演化历程
logo = assets/logo.png
date-format = %Y-%m-%d
hide = filenames,mouse

[users]
user-image-dir = ./avatars/
default-user-image = ./default-avatar.png

[files]
max-files = 500
bloom-multiplier = 0.75
elasticity = 0.2
```

#### code-orientation / code-forensics

**简介**：代码演化分析和可视化工具

**安装**：
```bash
# code-forensics (Node.js)
npm install -g code-forensics

# 或使用特定版本
git clone https://github.com/smontanari/code-forensics.git
cd code-forensics
npm install
```

**使用**：
```bash
# 分析仓库
code-forensics analyze /path/to/repo --output ./analysis

# 生成报告
code-forensics report ./analysis --output ./report.html

# 特定分析
code-forensics complexity /path/to/repo
code-forensics coupling /path/to/repo
code-forensics authors /path/to/repo
```

#### 其他可视化工具

**git-history**（Web 界面）：
```bash
npm install -g git-history

# 启动 Web 服务
git-history --port 8080 /path/to/repo

# 浏览器访问 http://localhost:8080
```

**codescene**（商业工具，有免费版）：
- 代码热点分析
- 知识传承度分析
- 技术债务可视化
- https://codescene.io/

---

## 3. 变更历史文档化

### 3.1 从提交记录生成变更日志

#### 使用 standard-version（推荐）

**安装**：
```bash
npm install -g standard-version

# 或在项目中安装
npm install --save-dev standard-version
```

**配置（.versionrc.json）**：
```json
{
  "types": [
    {"type": "feat", "section": "✨ 新功能"},
    {"type": "fix", "section": "🐛 Bug 修复"},
    {"type": "perf", "section": "⚡ 性能优化"},
    {"type": "refactor", "section": "♻️ 代码重构"},
    {"type": "docs", "section": "📝 文档更新"},
    {"type": "test", "section": "✅ 测试相关"},
    {"type": "build", "section": "构建系统"},
    {"type": "ci", "section": "CI/CD"},
    {"type": "chore", "hidden": true}
  ],
  "releaseCommitMessageFormat": "chore(release): {{currentTag}}",
  "skip": {
    "tag": false
  }
}
```

**使用**：
```bash
# 首次生成（如果已有提交历史）
standard-version --first-release

# 后续版本
standard-version

# 指定版本类型
standard-version --release-as major   # 主版本
standard-version --release-as minor   # 次版本
standard-version --release-as patch   # 补丁版本

# 手动指定版本号
standard-version --release-as 2.0.0

# 预发布版本
standard-version --prerelease beta
```

**输出示例（CHANGELOG.md）**：
```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [2.1.0] - 2024-06-15

### ✨ 新功能
- **api**: 添加用户认证接口 ([#123](link))
- **ui**: 实现深色主题支持 ([#124](link))
- 新增数据导出功能 ([#125](link))

### 🐛 Bug 修复
- 修复登录页面样式错位 ([#126](link))
- 解决文件上传内存泄漏问题 ([#127](link))

### ⚡ 性能优化
- 优化首页加载速度，提升 40% ([#128](link))

### ♻️ 代码重构
- 重构数据库连接模块 ([#129](link))

## [2.0.0] - 2024-05-01
...
```

#### 使用 conventional-changelog

```bash
# 安装
npm install -g conventional-changelog-cli

# 生成 CHANGELOG
conventional-changelog -p angular -i CHANGELOG.md -s

# 完整流程（生成所有历史）
conventional-changelog -p angular -i CHANGELOG.md -s -r 0
```

#### 使用 git-changelog

```bash
# 安装
pip install git-changelog

# 生成 CHANGELOG
git-changelog .

# 自定义模板
git-changelog . -t keepachangelog -o CHANGELOG.md

# 指定版本标签过滤
git-changelog . -b main -o CHANGELOG.md
```

#### 自定义脚本（支持 SVN/Git）

```python
#!/usr/bin/env python3
"""
通用变更日志生成器
支持 SVN 和 Git
"""

import subprocess
import re
from datetime import datetime
from collections import defaultdict

class ChangelogGenerator:
    def __init__(self, vcs='git', repo_path='.'):
        self.vcs = vcs
        self.repo_path = repo_path
    
    def get_git_commits(self, since_tag=None):
        """获取 Git 提交记录"""
        cmd = ['git', '-C', self.repo_path, 'log', '--pretty=format:%H|%ad|%an|%s']
        if since_tag:
            cmd.append(f'{since_tag}..HEAD')
        else:
            cmd.append('--all')
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        commits = []
        
        for line in result.stdout.strip().split('\n'):
            if not line:
                continue
            parts = line.split('|', 3)
            if len(parts) == 4:
                commits.append({
                    'hash': parts[0],
                    'date': parts[1],
                    'author': parts[2],
                    'message': parts[3]
                })
        
        return commits
    
    def get_svn_commits(self, start_rev=None, end_rev='HEAD'):
        """获取 SVN 提交记录"""
        cmd = ['svn', 'log', '-v']
        if start_rev:
            cmd.extend(['-r', f'{start_rev}:{end_rev}'])
        
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.repo_path)
        # 解析 SVN 日志...
        # 简化示例
        commits = []
        # TODO: 完整解析
        return commits
    
    def categorize_commits(self, commits):
        """按类型分类提交"""
        categories = {
            'feat': '新功能',
            'fix': 'Bug 修复',
            'perf': '性能优化',
            'refactor': '代码重构',
            'docs': '文档更新',
            'test': '测试',
            'chore': '其他',
            'other': '未分类'
        }
        
        categorized = defaultdict(list)
        pattern = r'^(feat|fix|perf|refactor|docs|test|chore)(\(.+\))?:\s*(.+)$'
        
        for commit in commits:
            msg = commit['message']
            match = re.match(pattern, msg)
            
            if match:
                category = match.group(1)
                scope = match.group(2) or ''
                description = match.group(3)
                
                categorized[category].append({
                    **commit,
                    'scope': scope.strip('()'),
                    'description': description
                })
            else:
                categorized['other'].append(commit)
        
        return categorized
    
    def generate_markdown(self, version, date, categorized_commits):
        """生成 Markdown 格式的变更日志"""
        lines = [f'## [{version}] - {date}', '']
        
        category_order = ['feat', 'fix', 'perf', 'refactor', 'docs', 'test', 'chore', 'other']
        category_names = {
            'feat': '✨ 新功能',
            'fix': '🐛 Bug 修复',
            'perf': '⚡ 性能优化',
            'refactor': '♻️ 代码重构',
            'docs': '📝 文档更新',
            'test': '✅ 测试',
            'chore': '🔧 其他',
            'other': '📌 其他变更'
        }
        
        for cat in category_order:
            if cat in categorized_commits and categorized_commits[cat]:
                lines.append(f'### {category_names[cat]}')
                for commit in categorized_commits[cat]:
                    scope = f'**{commit.get("scope")}**: ' if commit.get('scope') else ''
                    desc = commit.get('description', commit.get('message', ''))
                    lines.append(f'- {scope}{desc}')
                lines.append('')
        
        return '\n'.join(lines)
    
    def generate_changelog(self, output_file='CHANGELOG.md', version='Unreleased'):
        """生成完整变更日志"""
        if self.vcs == 'git':
            commits = self.get_git_commits()
        else:
            commits = self.get_svn_commits()
        
        categorized = self.categorize_commits(commits)
        content = self.generate_markdown(version, datetime.now().strftime('%Y-%m-%d'), categorized)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('# Changelog\n\n')
            f.write(content)
        
        return output_file


# 使用示例
if __name__ == '__main__':
    generator = ChangelogGenerator(vcs='git')
    generator.generate_changelog(version='2.1.0')
```

### 3.2 版本里程碑追溯

#### Git 标签分析

```bash
# 列出所有标签及日期
git tag -l | while read tag; do
  echo "$tag: $(git log -1 --format=%ad --date=short $tag)"
done | sort -k2

# 使用 git-for-each-ref
git for-each-ref --sort=creatordate --format '%(refname:short) %(creatordate:short)' refs/tags/

# 两个标签之间的变更
git log v1.0.0..v2.0.0 --oneline

# 标签详情
git show v1.0.0 --stat
```

#### 里程碑分析脚本

```python
#!/usr/bin/env python3
"""
Git 里程碑追溯脚本
"""

import subprocess
import json
from datetime import datetime
from collections import defaultdict

class MilestoneAnalyzer:
    def __init__(self, repo_path='.'):
        self.repo_path = repo_path
    
    def run_git(self, *args):
        cmd = ['git', '-C', self.repo_path] + list(args)
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stdout.strip()
    
    def get_tags(self):
        """获取所有标签及其信息"""
        output = self.run_git(
            'for-each-ref', '--sort=creatordate',
            '--format=%(refname:short)|%(creatordate:iso)|%(objectname)',
            'refs/tags/'
        )
        
        tags = []
        for line in output.split('\n'):
            if not line:
                continue
            parts = line.split('|')
            if len(parts) >= 3:
                tags.append({
                    'name': parts[0],
                    'date': parts[1],
                    'commit': parts[2]
                })
        
        return tags
    
    def get_changes_between_tags(self, tag1, tag2):
        """获取两个标签之间的变更"""
        if tag1 is None:
            # 从起始到 tag2
            output = self.run_git('log', '--oneline', tag2)
        else:
            output = self.run_git('log', '--oneline', f'{tag1}..{tag2}')
        
        commits = []
        for line in output.split('\n'):
            if line:
                parts = line.split(' ', 1)
                commits.append({
                    'hash': parts[0],
                    'message': parts[1] if len(parts) > 1 else ''
                })
        
        return commits
    
    def analyze_milestones(self):
        """分析所有里程碑"""
        tags = self.get_tags()
        milestones = []
        
        prev_tag = None
        for tag in tags:
            changes = self.get_changes_between_tags(prev_tag, tag['name'])
            
            milestone = {
                'tag': tag['name'],
                'date': tag['date'],
                'commit_count': len(changes),
                'top_contributors': self._get_contributors(prev_tag, tag['name']),
                'key_changes': [c for c in changes[:10]]  # 前10个关键变更
            }
            
            milestones.append(milestone)
            prev_tag = tag['name']
        
        return milestones
    
    def _get_contributors(self, tag1, tag2):
        """获取贡献者列表"""
        if tag1:
            output = self.run_git('shortlog', '-sn', f'{tag1}..{tag2}')
        else:
            output = self.run_git('shortlog', '-sn', tag2)
        
        contributors = []
        for line in output.split('\n'):
            if line:
                parts = line.strip().split('\t')
                if len(parts) == 2:
                    contributors.append({
                        'name': parts[1],
                        'commits': int(parts[0])
                    })
        
        return contributors[:5]  # Top 5
    
    def generate_timeline(self, output_file='milestones.json'):
        """生成里程碑时间线"""
        milestones = self.analyze_milestones()
        
        timeline = {
            'project': self.repo_path,
            'generated': datetime.now().isoformat(),
            'milestones': milestones
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(timeline, f, indent=2, ensure_ascii=False)
        
        return timeline


# 使用示例
if __name__ == '__main__':
    analyzer = MilestoneAnalyzer('/path/to/repo')
    timeline = analyzer.generate_timeline()
    print(json.dumps(timeline, indent=2, ensure_ascii=False))
```

### 3.3 关键功能演进时间线

#### 功能追踪方法

```bash
# 追踪特定文件/功能的变更历史
git log --follow --oneline src/features/auth.py

# 追踪特定功能的提交（关键词搜索）
git log --grep="认证" --oneline
git log --grep="auth\|authentication" --oneline

# 查看文件演化
git log -p --follow src/features/auth.py | head -500

# 使用 git bisect 查找引入问题的提交
git bisect start
git bisect bad HEAD
git bisect good v1.0.0
# Git 会自动二分查找，每次运行测试后标记
git bisect good/bad
```

#### 功能演进分析脚本

```python
#!/usr/bin/env python3
"""
关键功能演进时间线分析
"""

import subprocess
import re
from datetime import datetime
from collections import defaultdict

class FeatureEvolutionAnalyzer:
    def __init__(self, repo_path='.'):
        self.repo_path = repo_path
    
    def run_git(self, *args):
        cmd = ['git', '-C', self.repo_path] + list(args)
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stdout.strip()
    
    def track_feature(self, feature_pattern, path_pattern=None):
        """追踪特定功能的演进"""
        cmd = ['log', '--all', '--oneline', '--date=short', 
               '--pretty=format:%H|%ad|%an|%s']
        
        if path_pattern:
            cmd.extend(['--', path_pattern])
        
        # 按关键词过滤
        output = self.run_git(*cmd)
        
        commits = []
        for line in output.split('\n'):
            if not line:
                continue
            parts = line.split('|', 3)
            if len(parts) == 4:
                msg = parts[3]
                if re.search(feature_pattern, msg, re.IGNORECASE):
                    commits.append({
                        'hash': parts[0],
                        'date': parts[1],
                        'author': parts[2],
                        'message': msg
                    })
        
        return commits
    
    def analyze_feature_introduction(self, file_pattern):
        """分析功能引入时间"""
        output = self.run_git(
            'log', '--diff-filter=A', '--date=short',
            '--pretty=format:%ad|%an|%s', '--', file_pattern
        )
        
        introductions = []
        for line in output.split('\n'):
            if line:
                parts = line.split('|', 2)
                if len(parts) == 3:
                    introductions.append({
                        'date': parts[0],
                        'author': parts[1],
                        'message': parts[2]
                    })
        
        return introductions
    
    def get_feature_maturity_timeline(self, feature_keywords):
        """获取功能成熟度时间线"""
        timeline = []
        
        for keyword in feature_keywords:
            commits = self.track_feature(keyword)
            
            if commits:
                timeline.append({
                    'feature': keyword,
                    'first_commit': commits[-1]['date'] if commits else None,
                    'last_commit': commits[0]['date'] if commits else None,
                    'commit_count': len(commits),
                    'contributors': list(set(c['author'] for c in commits)),
                    'key_milestones': commits[:5]  # 最近5个关键提交
                })
        
        # 按首次提交时间排序
        timeline.sort(key=lambda x: x['first_commit'] or '9999-99-99')
        
        return timeline
    
    def generate_feature_report(self, features, output_file='features.md'):
        """生成功能演进报告"""
        timeline = self.get_feature_maturity_timeline(features)
        
        lines = ['# 功能演进时间线\n']
        lines.append('生成时间: {}\n'.format(datetime.now().strftime('%Y-%m-%d %H:%M')))
        lines.append('---\n')
        
        for feature in timeline:
            lines.append(f'\n## {feature["feature"]}\n')
            lines.append(f'- **首次引入**: {feature["first_commit"]}\n')
            lines.append(f'- **最近更新**: {feature["last_commit"]}\n')
            lines.append(f'- **提交次数**: {feature["commit_count"]}\n')
            lines.append(f'- **贡献者**: {", ".join(feature["contributors"])}\n')
            lines.append('\n### 关键里程碑\n')
            
            for commit in feature['key_milestones']:
                lines.append(f'- {commit["date"]}: {commit["message"]} ({commit["author"]})\n')
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        
        return output_file


# 使用示例
if __name__ == '__main__':
    analyzer = FeatureEvolutionAnalyzer('/path/to/repo')
    
    # 追踪关键功能
    features = [
        '用户认证',
        'API',
        '性能优化',
        '安全',
        '日志'
    ]
    
    analyzer.generate_feature_report(features)
```

---

## 4. 推荐工具链与工作流

### 4.1 SVN 项目工具链

```
┌─────────────────────────────────────────────────────────────┐
│                    SVN 历史分析工具链                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  数据采集层                                                   │
│  ├── svn log --xml          (原始日志导出)                    │
│  ├── svn diff               (变更详情)                        │
│  └── svn blame              (代码归属)                        │
│                                                              │
│  分析处理层                                                   │
│  ├── Python 脚本            (自定义统计)                      │
│  ├── StatSVN               (HTML 报告)                        │
│  └── svnplot               (可视化图表)                       │
│                                                              │
│  输出呈现层                                                   │
│  ├── HTML 报告              (StatSVN/svnplot)                │
│  ├── Markdown 文档          (自定义脚本)                      │
│  └── PNG/PDF 图表           (matplotlib)                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**推荐工作流**：

```bash
# 1. 导出完整日志
svn log -v --xml > logs/svn_log.xml

# 2. 生成 StatSVN 报告（适合管理层汇报）
java -jar statsvn.jar logs/svn_log.xml checkout_dir \
  -output-dir ./reports/statsvn

# 3. 自定义分析（适合技术分析）
python scripts/svn_analyzer.py logs/svn_log.xml \
  --output ./reports/custom

# 4. 定期自动化（cron）
0 2 * * 0 cd /project && svn log -v --xml > logs/svn_log_$(date +\%Y\%m\%d).xml
```

### 4.2 Git 项目工具链

```
┌─────────────────────────────────────────────────────────────┐
│                    Git 历史分析工具链                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  快速分析                                                     │
│  ├── git-quick-stats       (终端交互式)                      │
│  ├── git-stats             (HTML 报告)                        │
│  └── tig                   (终端浏览器)                       │
│                                                              │
│  可视化展示                                                   │
│  ├── Gource                (动态视频)                         │
│  ├── git-history           (Web 界面)                         │
│  └── GitKraken/GitLens     (GUI 工具)                         │
│                                                              │
│  变更日志                                                     │
│  ├── standard-version      (推荐)                             │
│  ├── conventional-changelog                                    │
│  └── git-changelog         (Python)                           │
│                                                              │
│  深度分析                                                     │
│  ├── Git 成熟度分析脚本                                        │
│  ├── code-forensics        (代码演化)                         │
│  └── CodeScene             (商业工具)                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**推荐工作流**：

```bash
# 日常快速查看
git-quick-stats

# 周期性报告生成
# setup-cron.sh
cat > /etc/cron.weekly/git-stats << 'EOF'
#!/bin/bash
cd /path/to/repo
git-stats --output /var/www/reports/git-stats-$(date +\%Y\%m\%d).html
EOF
chmod +x /etc/cron.weekly/git-stats

# 发布前生成 CHANGELOG
npm run release  # 触发 standard-version

# 项目演示视频
gource . --title "项目演化" -o - | ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libx264 project.mp4
```

### 4.3 混合环境（SVN + Git）

如果项目同时使用 SVN 和 Git（如 git-svn 同步）：

```bash
# 使用 git-svn 克隆 SVN 仓库
git svn clone https://svn.example.com/repo/trunk --stdlayout repo-git

# 后续同步
cd repo-git
git svn fetch
git svn rebase

# 此时可以使用所有 Git 工具进行分析
git-quick-stats
gource .
```

### 4.4 自动化集成建议

#### CI/CD 集成

```yaml
# .github/workflows/changelog.yml
name: Generate Changelog

on:
  push:
    tags:
      - 'v*'

jobs:
  changelog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm install -g standard-version
      
      - name: Generate Changelog
        run: |
          standard-version --skip.commit --skip.tag
          git push --follow-tags origin main
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          body_path: CHANGELOG.md
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### 定期报告脚本

```bash
#!/bin/bash
# weekly-report.sh - 每周生成统计报告

REPO_PATH="/path/to/repo"
REPORT_DIR="/var/www/reports"
DATE=$(date +%Y%m%d)

cd $REPO_PATH

# Git 拉取最新代码
git pull

# 生成统计报告
mkdir -p $REPORT_DIR/$DATE

# 1. 快速统计
git-quick-stats --detailed-git-stats > $REPORT_DIR/$DATE/quick-stats.txt

# 2. HTML 报告
git-stats --output $REPORT_DIR/$DATE/git-stats.html

# 3. 提交分析
python scripts/git_analyzer.py --output $REPORT_DIR/$DATE/analysis.json

# 4. 成熟度评估
python scripts/maturity_analyzer.py --output $REPORT_DIR/$DATE/maturity.json

# 5. 发送邮件通知（可选）
# mail -s "Weekly Git Report - $DATE" team@example.com < $REPORT_DIR/$DATE/quick-stats.txt

echo "Report generated at $REPORT_DIR/$DATE"
```

### 4.5 工具对比总结

| 功能 | SVN 工具 | Git 工具 | 推荐选择 |
|------|----------|----------|----------|
| 基础统计 | StatSVN | git-quick-stats | Git 工具更易用 |
| HTML 报告 | StatSVN/svnplot | git-stats | 两者各有优势 |
| 可视化 | svnplot | Gource | Gource 效果更佳 |
| 变更日志 | 自定义脚本 | standard-version | standard-version 更规范 |
| 成熟度分析 | 自定义 | 自定义脚本 | 都需要定制 |
| 团队协作 | StatSVN | git-quick-stats | Git 工具生态更完善 |

---

## 5. 快速上手指南

### 5.1 SVN 项目快速开始

```bash
# 1. 安装必要工具
sudo apt install default-jre python3-pip
pip install pandas matplotlib

# 2. 下载 StatSVN
wget https://downloads.sourceforge.net/project/statsvn/statsvn/0.7.0/statsvn-0.7.0.zip
unzip statsvn-0.7.0.zip

# 3. 导出 SVN 日志
svn log -v --xml > svn_log.xml

# 4. 生成报告
java -jar statsvn-0.7.0/statsvn.jar svn_log.xml . -output-dir ./report

# 5. 查看报告
open ./report/index.html
```

### 5.2 Git 项目快速开始

```bash
# 1. 安装工具
brew install git-quick-stats gource ffmpeg
npm install -g standard-version git-stats

# 2. 生成快速统计
cd /path/to/repo
git-quick-stats

# 3. 生成 HTML 报告
git-stats --output ./git-stats.html

# 4. 生成变更日志
standard-version --first-release

# 5. 生成演化视频
gource . --output-ppm-stream - | ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libx264 evolution.mp4
```

---

## 6. 参考资料

- [StatSVN 官方文档](http://www.statsvn.org/)
- [git-quick-stats GitHub](https://github.com/arzzen/git-quick-stats)
- [Gource 官方网站](https://gource.io/)
- [Conventional Commits 规范](https://www.conventionalcommits.org/)
- [standard-version 文档](https://github.com/conventional-changelog/standard-version)
- [Git 成熟度模型](https://matthewskala.net/blog/2013-10-22-git-maturity-model/)
