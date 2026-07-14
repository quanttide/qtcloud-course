# ROADMAP — qtcloud-course

量潮课程云产品级路线图。覆盖三个组件（Provider / Studio / CLI）及其集成。

## 版本策略

- 组件独立版本号、独立 CHANGELOG、独立发布
- 产品级里程碑按**可交付的产品能力**组织，内部 phase 是执行优先级不独立发布
- 当前所有组件处于 `0.MINOR.PATCH` 阶段，API 不稳定

| Scope | 版本 | 技术栈 | 状态 |
|-------|------|--------|------|
| provider | v0.0.2 | Go | ✅ REST API 完成，内存存储 |
| studio | v0.0.4 | Flutter | ✅ Sidebar 布局、PreviewScreen 场景播放 |
| cli | v0.1.0-alpha.3 | Rust | 🧪 AI 蓝图生成，功能单一 |

---

## v0.0.5 — 课程编辑可用

**目标**：打开 Studio 就能完成课程从搭建到发布的完整闭环——编排结构、调整顺序、安全保障、AI 互通。

### Phase 1（P0）：四级 CRUD + 拖拽排序

对应设计意图：原则 2（树形编辑）+ 原则 3（自下而上）+ 原则 7（拖拽排序）

#### Studio

- [ ] Program / Course / Phase / Lesson 四级新建对话框
- [ ] 四级编辑（名称/描述可修改）
- [ ] 四级删除确认对话框，提示子级数量
- [ ] 同名同级节点拖拽排序
- [ ] 发布/下架操作
- [ ] 发布 Course 时检查 Lesson 状态，有草稿则提示
- [ ] 已发布节点不可删除

#### Provider

- [ ] CRUD API 对齐 Studio 编辑操作
- [ ] 排序字段支持 PATCH

### Phase 2（P1）：资源独立 + 安全护栏

对应设计意图：原则 4（资源独立性）+ 原则 6（安全护栏）

#### Studio

- [ ] 软删除（deletedAt 标记，内容可恢复）
- [ ] 跨容器拖拽（Lesson 拖到其他 Phase）
- [ ] 独立课时池 + "归入阶段"操作（自下而上路径）
- [ ] 编辑未保存标记

#### Provider

- [ ] SQLite 持久化
- [ ] 软删除 API（标记而非物理删除）
- [ ] 课时独立端点（不依赖父级路径）

### Phase 3（P2）：双轨互通

对应设计意图：原则 1（双轨制）+ 原则 5（蓝图互通）

#### Studio

- [ ] 文件导入：选择本地 JSON 文件，解析后合并到课程树
- [ ] 文件导出：当前课程树导出为 JSON
- [ ] 冲突处理策略（覆盖/跳过/保留两者）

#### CLI

- [ ] 脱离 alpha
- [ ] `blueprint` 输出与 Studio 导入格式完全兼容
- [ ] 批量操作：批量创建课程/课时

#### E2E

- [ ] CLI → Studio 导入→编辑→导出闭环验证
- [ ] 冲突策略自动化测试

### 交付标准

```
cd src/provider && go test ./... -count=1      # ✅
cd src/studio  && flutter test                  # ✅
cd src/cli     && cargo test                    # ✅
# 验收：不依赖 CLI 的纯 Studio 操作路径
flutter run -d linux                             # 创建专业→添加课程→新建课时→发布→删除→恢复
# 验收：CLI ↔ Studio 互通
qtcloud-course blueprint ... --output course.json
flutter run -d linux                             # 打开 Studio → 导入 course.json
```

---

## 架构愿景（v1.0）

```
┌─────────────────────────────────────────────────────┐
│                    CLI (Rust)                        │
│   blueprint generation → JSON → Studio/Provider      │
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│                 Provider (Go)                        │
│   REST API :8080 ──── 业务逻辑 ──── SQLite/Postgres  │
└─────────────────────────────────────────────────────┘
          ▲
          │ HTTP JSON
          ▼
┌─────────────────────────────────────────────────────┐
│                    Studio                            │
│   Flutter 桌面端（Linux/mac/win）                     │
│   双数据源：assets / API                              │
└─────────────────────────────────────────────────────┘
```
