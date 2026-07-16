# qtcloud-course CLI

课程开发命令行工具。CLI 是 Studio 的验证层（Verification Layer）——每个 Studio 功能进入 Flutter UI 开发前，先用 CLI 验证生产流程是否跑通。

## 安装

```bash
cargo install --path .
```

## 用法

### 生成课程蓝图

```bash
# 输出 Markdown 格式
qtcloud-course course <topic>

# 输出结构化 JSON（兼容 Studio 导入格式）
qtcloud-course course <topic> --format json --output-path blueprint.json

# 传入原始资料作为上下文
qtcloud-course course <topic> --input-path /path/to/materials.md
```

### 校验课程 JSON

```bash
qtcloud-course validate blueprint.json
```

### 导入/导出课程数据

```bash
# 导入课程结构到 Provider API
qtcloud-course import blueprint.json

# 从 Provider API 导出课程数据
qtcloud-course export <program-id> --output-path exported.json
```

### 快速验证管线

```bash
# 一键走通 CLI ↔ Provider 数据管线
qtcloud-course course "Git 入门" --format json --output-path blueprint.json
qtcloud-course validate blueprint.json
qtcloud-course import blueprint.json
qtcloud-course export <program-id> --output-path roundtrip.json
```

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `QTCLOUD_API_BASE_URL` | Provider API 地址 | `http://localhost:8080` |
| `LLM_API_KEY` | DeepSeek API 密钥 | 必填（course 子命令） |
| `LLM_MODEL` | LLM 模型名 | `deepseek-v4-flash` |
| `LLM_BASE_URL` | LLM API 地址 | `https://api.deepseek.com` |

## 开发

### 运行测试

```bash
# Rust 单元测试 + 集成测试（mock TCP server）
cargo test

# 配合 Provider 的 Python 集成测试（从项目根目录）
cd ../../..
uv run pytest tests/test_cli.py -v
```
