# TODO — v0.0.5 课程编辑可用

三个 Phase 按优先级排列，全部完成后统一发布 v0.0.5。

---

## Phase 1（P0）：四级 CRUD + 拖拽排序

### Studio

- [ ] Program / Course / Phase / Lesson 四级新建对话框
- [ ] 四级编辑（名称/描述可修改）
- [ ] 四级删除确认对话框，提示子级数量
- [ ] 同级节点拖拽排序（更新 sortOrder）
- [ ] 发布/下架操作
- [ ] 发布 Course 时检查 Lesson 状态，有草稿则提示
- [ ] 已发布节点不可删除

### Provider

- [ ] CRUD API 对齐 Studio 编辑操作
- [ ] 排序字段支持 PATCH

---

## Phase 2（P1）：资源独立 + 安全护栏

### Studio

- [ ] 软删除（deletedAt 标记，内容可恢复）
- [ ] 跨容器拖拽（Lesson 拖到其他 Phase）
- [ ] 独立课时池 + "归入阶段"操作（自下而上路径）
- [ ] 编辑未保存标记

### Provider

- [ ] SQLite 持久化
- [ ] 软删除 API
- [ ] 课时独立端点（不依赖父级路径）

---

## Phase 3（P2）：双轨互通

### Studio

- [ ] 文件导入（选择本地 JSON）
- [ ] 文件导出（当前树导出为 JSON）
- [ ] 冲突处理策略（覆盖/跳过/保留两者）

### CLI

- [ ] 脱离 alpha
- [ ] `blueprint` 输出与 Studio 导入格式兼容
- [ ] 批量操作

### E2E

- [ ] CLI → Studio → 导出闭环验证
- [ ] 冲突策略自动化测试
