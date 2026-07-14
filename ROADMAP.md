# ROADMAP — qtcloud-course

量潮课程云产品级路线图。覆盖三个组件（Provider / Studio / CLI）及其集成。

## 版本策略

- 组件独立版本号、独立 CHANGELOG、独立发布
- 产品级里程碑（如 v0.1.0）表示三个组件达到可集成状态
- 当前所有组件处于 `0.MINOR.PATCH` 阶段，API 不稳定

| Scope | 版本 | 技术栈 | 状态 |
|-------|------|--------|------|
| provider | v0.0.2 | Go | ✅ REST API 完成，内存存储 |
| studio | v0.0.2 | Flutter | ✅ 六级编排树，GUI 测试框架 |
| cli | v0.1.0-alpha.3 | Rust | 🧪 AI 蓝图生成，功能单一 |

---

## v0.1.0 — 前后端联调可用（当前里程碑）

**目标**：Studio 可通过 Provider API 加载数据，替代本地 assets JSON，完成首次联调验证。

### Provider — v0.0.3

**API 重构**
- [ ] 资源嵌套路由：Scenes 嵌套到 Lessons，Phases 嵌套到 Courses
- [ ] 所有资源统一 `name`（URL slug）/ `title`（显示名）字段
- [ ] `Store.GetByName(name)` 方法及 `/name/{name}` 端点
- [ ] 环境变量 `DATA_DIR` 支持启动时加载 JSON 种子数据

**数据源**
- [ ] `data/profile/` 中的课程资料可导入为 provider 种子数据
- [ ] 启动脚本一键种子：`make seed`
- [ ] 提供 lesson1 的完整场景数据（含 Steps）

**测试**
- [ ] name 重复校验测试
- [ ] 嵌套路由 handler 测试
- [ ] `go test ./... -count=1` 保持 90%+ 覆盖率

### Studio — v0.0.3

**DataSource 策略模式**
- [ ] `CourseDataService` 支持 assets / API 双数据源
- [ ] `baseUrl` 为 null 时走 assets（本地开发不变），非 null 时走 Provider
- [ ] `--dart-define=API_BASE_URL` 编译期注入
- [ ] 添加 `http` 依赖

**试听预览页**
- [ ] PreviewScreen 从占位页改为真实内容：Scene → Step 逐步骤引导
- [ ] 视频播放占位（可展示 videoUrl）
- [ ] Choice 跳转支持（场景间跳转）

**GUI 测试**
- [ ] 补充更多交互测试（点击场景步骤、tab 内容断言）
- [ ] CI 集成（确保 runner 安装了 Xvfb、tesseract、ImageMagick）
- [ ] `smart_click` 模板管理（清除/更新缓存模板）

### CLI — v0.1.0

- [ ] 脱离 alpha：更名 `v0.1.0`
- [ ] 课程蓝图导出为 JSON，与 provider 种子格式兼容
- [ ] 输出可直接导入 provider：`qtcloud-course blueprint --output seed.json`

### E2E 联调验证

- [ ] make 一键启动：`make dev` = 启动 provider + 启动 studio
- [ ] Python 测试脚本验证：启动 provider → 启动 studio → 断言页面渲染
- [ ] 记录首次联调耗时、问题清单

### 交付标准

```
# 三组件各自通过
cd src/provider && go test ./... -count=1      # ✅
cd src/studio  && flutter test                  # ✅
cd src/cli     && cargo test                    # ✅

# 联调验证
cd ../..
make dev                                        # provider :8080 + studio API 模式
cd tests && pytest test_studio.py -v            # ✅
```

---

## v0.2.0 — 运营后台可用

### Provider

- [ ] 持久化存储（SQLite 起步，不引入外部数据库）
- [ ] 课程 CRUD 完整：添加/编辑/删除课程
- [ ] 班级管理 API：报名、进度跟踪
- [ ] 视频上传 API

### Studio

- [ ] 教学管理页：班级详情从 API 加载
- [ ] 仪表盘指标从 API 加载（取代本地统计）
- [ ] 试听页：真实场景播放（Steps 逐步骤展示 + 视频集成）
- [ ] Windows/macOS 构建验证

### CLI

- [ ] 蓝图导入：从 JSON 导入已有蓝图
- [ ] 批量操作：批量创建课程/课时

### 测试基础设施

- [ ] Provider 接口测试套件（Python pytest → HTTP）
- [ ] CI pipeline：push 自动跑三组件测试
- [ ] 截图对比测试（OpenCV 模板匹配）

---

## v0.3.0 — 课程交付闭环

### Provider

- [ ] 用户认证（飞书登录）
- [ ] 角色权限（管理员 / 讲师 / 学生）
- [ ] 课程发布流程（草稿 → 审核 → 发布）
- [ ] 学习进度追踪

### Studio

- [ ] 讲师端：课程编辑界面（拖拽排序、内容管理）
- [ ] 学生端：课程学习界面（视频播放、步骤引导）
- [ ] 课堂互动（提问、反馈）

### CLI

- [ ] 发布工具：一键将本地课程内容发布到生产环境
- [ ] 数据迁移：从旧系统导入课程数据

---

## 架构愿景（v1.0）

```
┌─────────────────────────────────────────────────────┐
│                    CLI (Rust)                        │
│   blueprint generation → seed.json → provider        │
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                 Provider (Go)                        │
│   REST API :8080 ──── 业务逻辑 ──── SQLite/Postgres  │
└─────────────────────────────────────────────────────┘
          ▲                           ▲
          │ HTTP JSON                  │ HTTP JSON
          ▼                           ▼
┌──────────────────┐    ┌──────────────────────────┐
│   Studio         │    │    Web (未来)              │
│   Flutter 桌面端   │    │    React / Vue             │
│   Linux/mac/win  │    │    浏览器端                  │
└──────────────────┘    └──────────────────────────┘
```

## 非功能目标

| 维度 | v0.1.0 | v0.2.0 | v1.0 |
|------|--------|--------|------|
| 开发环境启动 | 一键 `make dev` | 不变 | 不变 |
| Studio 离线可用 | ✅ assets 模式兜底 | ✅ assets 模式兜底 | ✅ assets 模式兜底 |
| provider 持久化 | 内存（重启丢失） | SQLite | Postgres |
| GUI 测试 | 手动运行 | CI 集成 | CI + 截图 diff |
| 跨平台桌面 | Linux only | Linux + macOS | Linux/mac/Windows |

## 组件间依赖关系

```
v0.1.0      Provider 0.0.3 ←── Studio 0.0.3（首次联调）
                │
                └── CLI 0.1.0（蓝图输出 → provider 种子）

v0.2.0      Provider 0.1.0 ←── Studio 0.1.0
                │
                └── CLI 0.2.0（蓝图导入）

v0.3.0      Provider 0.2.0 ←── Studio 0.2.0
                │
                └── CLI 0.3.0（发布工具）
```

组件版本独立递增。产品里程碑 v0.1.0 / v0.2.0 / v0.3.0 是**对齐标记**，表示各组件版本组合后达到该阶段目标。
