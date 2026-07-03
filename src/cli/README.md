# qtcloud-course CLI

课程开发命令行工具。

## 安装

```bash
cargo install --path .
```

需要设置 `LLM_API_KEY` 环境变量。

## 用法

```bash
# 生成课程蓝图
qtcloud-course blueprint <topic>
```

### 示例

```bash
qtcloud-course blueprint git
qtcloud-course blueprint docker
```

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `LLM_API_KEY` | DeepSeek API 密钥 | 必填 |
| `LLM_MODEL` | 模型名 | `deepseek-v4-flash` |
| `LLM_BASE_URL` | API 地址 | `https://api.deepseek.com` |
