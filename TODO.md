# TODO

跨组件任务，按产品里程碑组织。

## v0.0.5 — 双向编辑

### 原则 2 补齐：树编辑

- [ ] Provider CRUD API 对齐 Studio 编辑操作（排序字段支持 PATCH）
- [ ] Studio 四级（Program/Course/Phase/Lesson）新建对话框
- [ ] Studio 四级编辑（名称/描述可修改）
- [ ] Studio 四级删除确认对话框，提示子级数量

### 原则 7：拖拽排序

- [ ] Studio 同级节点拖拽排序（Course / Phase / Lesson）
- [ ] 拖拽时更新 sortOrder 并 notifyListeners
- [ ] Provider 排序字段支持 PATCH

### 原则 6 前置：发布

- [ ] Studio 发布/下架操作
- [ ] 发布 Course 时检查 Lesson 状态，有草稿则提示
- [ ] 已发布节点不可删除

---

## v0.0.6 — 资源独立 + 安全护栏

### 原则 4：资源独立性

- [ ] Provider SQLite 持久化
- [ ] Studio 软删除（deletedAt 标记）
- [ ] Studio 跨容器拖拽（Lesson 拖到其他 Phase）
- [ ] Studio 独立课时池 + "归入阶段"操作（自下而上路径）

### 原则 6：安全护栏

- [ ] Studio 编辑未保存标记
- [ ] Studio 删除/发布全路径安全校验
- [ ] CLI 输出格式与 Provider 种子对齐

---

## v0.0.7 — 双轨互通

### 原则 1 + 5：蓝图互通

- [ ] CLI `blueprint` 输出与 Studio 导入格式兼容
- [ ] Studio 文件导入（选择本地 JSON）
- [ ] Studio 文件导出（当前树导出为 JSON）
- [ ] 冲突处理策略（覆盖/跳过/保留两者）
- [ ] CLI 脱离 alpha

### 测试

- [ ] CLI → Studio 导入全链路验证
- [ ] Studio → CLI 导出→导入闭环
- [ ] 冲突策略自动化测试
- [ ] GUI 截图对比测试（OpenCV 模板匹配）
