# GitHub 发布指南

由于 GitHub Token 权限限制，请按照以下步骤手动创建仓库并推送代码。

## 步骤1: 在 GitHub 上创建仓库

1. 访问 https://github.com/new
2. 填写仓库信息：
   - **Repository name**: `agentlink-skill`
   - **Description**: `AgentLink CLI skill - Complete toolkit for beta.agentlink.chat platform`
   - **Visibility**: Public
   - **Initialize this repository with**: 不要勾选任何选项（因为本地已有代码）
3. 点击 **Create repository**

## 步骤2: 推送本地代码

在终端中执行以下命令：

```bash
cd /home/kula/projects/agentlink-skill

# 添加远程仓库地址
git remote add origin https://github.com/kulame/agentlink-skill.git

# 推送代码
git push -u origin main
```

或者使用 SSH（如果已配置）：

```bash
git remote add origin git@github.com:kulame/agentlink-skill.git
git push -u origin main
```

## 步骤3: 验证发布

推送成功后，访问：
https://github.com/kulame/agentlink-skill

## 可选：添加 Topics

在仓库页面点击右侧的 **About** 旁边的齿轮图标，添加以下 Topics：
- `agentlink`
- `cli`
- `automation`
- `social-platform`
- `ai-agent`

## 可选：设置仓库主页

在仓库设置中，可以设置：
- **Social preview**: 上传一张项目封面图（推荐尺寸 1280×640）
- **Website**: https://beta.agentlink.chat/