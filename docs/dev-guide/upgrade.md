# Provider 升级指南

> 面向：开发者/维护者——qtcloud-course provider 如何升级（代码与内容两类）。

## 一句话

provider 升级分两类：**代码升级**（发版本重新部署）和**内容升级**（课程数据变更入库）——两条路互不替代。

## 升级分类

| 类型 | 触发 | 影响 |
|------|------|------|
| **代码升级** | 改 provider 代码/接口 | 服务逻辑变化——发版本部署 |
| **内容升级** | 课程内容变更（data/profile 创作源头） | 数据变化——导入 provider 存储 |

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
CLI import / seed → provider（OSS——QTCLOUD_COURSE_STORE=oss）
   │ ③ provider 持久化（每表一个对象：programs.json 等）
   ▼
线上数据更新
```

要点：

- **① 同步**：profile 是创作源头（md + json 双格式），provider 种子数据从 profile 同步（
  lesson 结构：scenes + criteria）。改内容先改 profile，再同步 provider 数据。
- **② 验证**：本地 seed/player 全绿后再上线（`src/provider` 本地运行 + 导入验证）。
- **③ 持久化**：provider 生产环境用 **对象存储（OSS）**——容器启动时先 seed（幂等）写入
  OSS 再起服务（`src/provider/Dockerfile`），数据落 OSS 桶、与容器生命周期解耦。

## ✅ 持久化方案：对象存储（OSS）

FC 3.0 容器只有 512MB 临时盘，**容器重建/实例回收后本地数据丢失**——SQLite 本地文件方案
不可靠。生产持久化改为**对象存储（OSS）**：FC 容器可读写对象存储、容器回收数据仍在。

### 存储设计

每表一个对象（`{table}.json`），保存该表的全量实体列表：

- `programs.json`：Program 列表
- `courses.json`：Course 列表
- `phases.json`：Phase 列表
- `lessons.json`：Lesson 列表
- `scenes.json`：Scene 列表

读：懒加载——首次操作时整体拉取对象到内存缓存，之后读写走内存（数据量小，教程级）；写：内存更新后全量覆盖回 OSS（按 ID 排序保证确定性，原子写）。对齐 qtcloud-crowd provider 的 OSS store 模式（阿里云官方 SDK、QTCLOUD_OSS_* 配置前缀）。

### 配置说明

| 环境变量 | 必填 | 说明 |
|---------|------|------|
| `QTCLOUD_COURSE_STORE` | 是 | `oss`（生产）或 `memory`（默认，测试/开发） |
| `QTCLOUD_OSS_ENDPOINT` | oss 时 | 如 `oss-cn-hangzhou.aliyuncs.com` |
| `QTCLOUD_OSS_BUCKET` | oss 时 | 课程数据桶（terraform 创建，私有） |
| `QTCLOUD_OSS_ACCESS_KEY_ID` | oss 时 | 访问 OSS 的 AK |
| `QTCLOUD_OSS_ACCESS_KEY_SECRET` | oss 时 | 访问 OSS 的 SK |

FC 环境变量由 `manifests/terraform/fc.tf` 注入（对齐 qtcloud-crowd）。注意 AK/SK 会明文落入
tfstate，生产建议后续改用 FC 密钥管理/配置中心注入。

### 部署（FC）

`src/provider/Dockerfile` 启动顺序（幂等，数据源固定在镜像内，发版即更新）：

```sh
QTCLOUD_COURSE_STORE=oss course-seed --dir /data/vibe-coding && \
QTCLOUD_COURSE_STORE=oss course-seed-catalog && \
QTCLOUD_COURSE_STORE=oss course-server
```

### 本地验证

- **seed 写入**：`go run ./cmd/seed --dir data/vibe-coding`（默认 local 模式，cwd 下生成
  `programs.json` 等；`QTCLOUD_COURSE_STORE=oss` 时写入真实 OSS）
- **server 验证**：默认 `memory` 模式（进程内数据）；`QTCLOUD_COURSE_STORE=oss` + OSS 配置时
  从 OSS 读取（懒加载）

## 升级检查清单

- [ ] 代码升级：CHANGELOG 更新？版本 tag 发布？部署 run success？健康检查 200？
- [ ] 内容升级：profile 已改？provider 种子数据同步？本地 seed/player 验证？import 执行成功？
- [ ] 持久化：`QTCLOUD_COURSE_STORE=oss` + `QTCLOUD_OSS_*` 已配置？（未配置则回退内存，生产内容升级不生效）
