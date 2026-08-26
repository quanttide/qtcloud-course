# Provider 升级指南

> 面向：开发者/维护者——qtcloud-course provider 如何升级（代码与内容两类）。

## 一句话

provider 升级分两类：**代码升级**（发版本重新部署）和**内容升级**（课程数据变更入库）——两条路互不替代。

## 升级分类

| 类型 | 触发 | 影响 |
|------|------|------|
| **代码升级** | 改 provider 代码/接口 | 服务逻辑变化——发版本部署 |
| **内容升级** | 课程内容变更（data/profile 创作源头） | 数据变化——导入 provider 数据库 |

## 代码升级（标准流程）

```bash
# 1. 改代码 → 提交 → 更新 CHANGELOG（provider scope）
# 2. 发布版本（触发 deploy-provider.yml）
qtcloud-devops release publish -v provider/vX.Y.Z -y
# 3. 自动：ACR 镜像构建 → Terraform apply → FC 函数更新
# 4. 验证：provider 健康检查 + 关键 API
```

## 内容升级（课程数据）

内容源头是 **data/profile**（课程开发档案——单一创作源头）。provider 侧种子数据在
`src/provider/data/<course>/`（如 `vibe-coding/`——课时场景 JSON），升级链路：

```
data/profile（改课时/场景/验收标准）
   │ ① 同步/生成 provider 种子数据（src/provider/data/<course>/）
   ▼
provider 种子数据（课时 index.json + 场景 JSON）
   │ ② seed 导入（本地验证：seed/player 全绿）
   ▼
CLI import / seed → provider（SQLite——DB_PATH）
   │ ③ provider 持久化
   ▼
线上数据更新
```

要点：

- **① 同步**：profile 是创作源头（md + json 双格式），provider 种子数据从 profile 同步（
  lesson 结构：scenes + acceptance）。改内容先改 profile，再同步 provider 数据。
- **② 验证**：本地 seed/player 全绿后再上线（`src/provider` 本地运行 + 导入验证）。
- **③ 持久化**：provider 生产环境用 SQLite（DB_PATH）——导入的数据入库后持久。

## ⚠️ 当前缺口：FC 无持久化（内容升级不可靠）

- provider 部署在 **FC 3.0 容器**（disk 512MB 临时盘）——**容器重建/实例回收后 SQLite 数据丢失**
- 现状：内容升级在 FC 上**不可持久**（导入后数据在容器生命周期内有效）
- **需要解决**（二选一）：
  - **NAS 挂载**：FC 挂载 NAS——SQLite 文件放 NAS（推荐——数据独立于容器）
  - **导入即部署**：把内容导入做成部署流程的一步（每次部署时从种子数据导入）——适合内容随代码走的小规模场景

在持久化解决前：**内容升级仅适用于本地/内存环境**（开发验证），生产内容升级被阻塞。

## 升级检查清单

- [ ] 代码升级：CHANGELOG 更新？版本 tag 发布？部署 run success？健康检查 200？
- [ ] 内容升级：profile 已改？provider 种子数据同步？本地 seed/player 验证？import 执行成功？
- [ ] 持久化：DB_PATH 指向持久化位置（NAS）？（未配置则生产内容升级不生效）
