# Contributing

## 发布流程

### 前置条件

- 已安装 [qtcloud-devops](https://github.com/quanttide/qtcloud-devops)
- 拥有仓库的推送权限

### 步骤

1. **更新版本号**

   ```bash
   # 编辑 version.go，修改 Version 常量
   vim version.go
   ```

2. **检查变更**

   ```bash
   git --no-pager log --oneline <上次标签>..HEAD
   ```

3. **提交版本号变更**

   ```bash
   git add version.go
   git commit -m "chore(provider): bump version to x.y.z"
   git push
   ```

4. **发布**

   ```bash
   # 从子模块根目录运行
   cd ../..
   qtcloud-devops release publish --version provider/x.y.z --yes
   ```

   命令会自动：
   - 更新 `CHANGELOG.md`
   - 创建并推送 Git 标签 `provider/x.y.z`
   - 创建 GitHub Release

### 版本号规则

- 遵循语义化版本 `MAJOR.MINOR.PATCH`
- 初始开发阶段使用 `0.MINOR.PATCH`
- 查看已有版本：
  ```bash
  git tag -l 'provider/*'
  ```
