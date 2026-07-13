# ROADMAP

qtcloud-course-provider 0.0.3 版本规划。

## 版本状态

- 当前：v0.0.2
- 目标：v0.0.3
- 主题：**数据持久化与课程加载**

## 目标

0.0.2 完成了核心 CRUD API 和视频服务，但数据只存在于内存中，且没有课程批量加载能力。
0.0.3 的目标是让数据"存得住、读得进"，能直接把 profile 里创作的 JSON 加载到平台。

## 任务

### 数据持久化

- [ ] 从内存存储迁移到文件存储（JSON 文件），重启不丢数据
- [ ] 启动时从 `data/` 目录自动加载已有数据
- [ ] 运行时写操作同步更新文件

### 课程批量导入

- [ ] 新增 CLI 命令或 API 端点，批量导入 profile 产出的 JSON 数据
- [ ] 支持导入格式解析：lesson（含 scenes 数组）→ 拆分为 Lesson + Scene 存储
- [ ] 校验导入数据与 domain 模型的兼容性

### Lesson 扩展

- [ ] 补充 0.0.2 未覆盖的 Lesson→Scene 联动 API（按课时查询全部场景）
- [ ] Scene 新增 Title / Steps / VerifyTip 字段（已实现 domain 层）

### 测试

- [ ] 文件存储的单元测试（创建／读取／写入／重建）
- [ ] 批量导入集成测试
- [ ] 端到端测试：profile JSON → 导入 → API 查询 → 视频服务

## 非目标

- 数据库支持（PostgreSQL / SQLite）留到 0.1.0
- 用户认证与权限
- 前端页面
