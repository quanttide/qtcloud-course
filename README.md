# 量潮课程云

AI原生课程研发与授课中心。

## 技术栈

- `src/studio`：Flutter 客户端（课程制作 Studio，四级 CRUD + 发布 + JSON 导入导出）
- `src/provider`：Go provider 服务端（课程内容 API，Program/Course/Phase/Lesson/Scene）
- `src/cli`：CLI 工具（blueprint 子命令等）

## Provider 存储

- 内存（默认，测试/开发）：`QTCLOUD_COURSE_STORE=memory`
- 对象存储 OSS（生产，FC 可读写、容器回收数据仍在）：`QTCLOUD_COURSE_STORE=oss` +
  `QTCLOUD_OSS_ENDPOINT` / `QTCLOUD_OSS_BUCKET` / `QTCLOUD_OSS_ACCESS_KEY_ID` /
  `QTCLOUD_OSS_ACCESS_KEY_SECRET`——每表一个对象（`programs.json` 等，全量实体列表），
  懒加载 + 写时全量覆盖原子写

> 持久化方案由 SQLite 本地文件更换为 OSS（解决 FC 无持久化问题），详见
> [docs/dev-guide/upgrade.md](docs/dev-guide/upgrade.md)。
