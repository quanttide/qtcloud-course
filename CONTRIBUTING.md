# Contributing

## 测试

### 测试分层

| 层 | 工具 | 位置 | 职责 |
|---|------|------|------|
| **单元测试** | `go test` | `src/provider/` | 数据模型、存储层、Handler，覆盖率 ≥95% |
| **集成测试** | `pytest` | `tests/` | 服务端启动、API 端到端、数据 fixture 校验、视频可播放性 |

### 运行

```bash
# 单元测试
cd src/provider && go test ./... -count=1 -cover

# 全部集成测试
uv run pytest -v
```

视频可播放性测试需要 `ffmpeg` 和 `ffprobe`。缺失时自动跳过，不影响其他测试。

### 目录约定

```
tests/
├── conftest.py          # 共享 fixture
├── test_fixtures.py     # fixture 数据模型校验
├── test_provider.py     # 服务端 API 端到端
└── fixtures/            # JSON 模拟数据
    ├── programs.json
    ├── courses.json
    ├── phases.json
    ├── lessons.json
    ├── scenes.json
    └── classes.json
```

### 集成测试要求

1. **资源隔离** — 每个测试方法创建自己的数据，不依赖执行顺序。视频测试用 `tmp_path_factory` 创建临时目录
2. **服务端管理** — 通过 `_start_server` / `_stop_server` 管理服务实例。使用 `DEVNULL` 重定向子进程输出。端口用 `_free_port()` 动态分配
3. **断言** — 每个 HTTP 请求后必须断言状态码。404 测试用 `@pytest.mark.parametrize` 批量覆盖
4. **数据 fixture** — 所有 JSON 必须通过 `test_fixtures.py` 的 schema 校验。跨文件引用必须可解析（Scene → Lesson、Phase → Course）
5. **清理** — fixture 在 `finally` 块中终止进程。不使用 `setup_class` / `teardown_class` 操作磁盘文件

### 命名规范

| 类型 | 格式 | 示例 |
|------|------|------|
| Go 测试文件 | `*_test.go` | `store_test.go` |
| Python 测试文件 | `test_*.py` | `test_provider.py` |
| 测试类 | `Test<Name>` | `TestProgramCRUD` |
| 测试方法 | `test_<场景>` | `test_serve_existing_file` |
| fixture JSON | `<资源>s.json` | `phases.json` |

---

## 实验

实验（Experiments）放在 [`examples/default/`](examples/default/) 下，用于验证部署、集成和端到端可用性。

### 目录约定

```
examples/default/
├── ROADMAP.md           # 实验方案
├── .gitignore
└── lab/                 # 实验现场
    ├── bin/             ← gitignore
    ├── videos/          ← gitignore
    ├── deploy.sh        ← 跟踪
    ├── seed-demo.sh     ← 跟踪
    └── video-test.html  ← 跟踪
```

### 规则

1. **所有操作在 `lab/` 内完成** — 不涉及系统目录（如 `~/course-lab/`），不污染仓库其他位置
2. **脚本和配置文件可跟踪** — `lab/` 下的 `.sh`、`.html`、`.yaml` 等代码文件正常进版本控制
3. **构建产物和视频数据必须过滤** — 编译的二进制、生成的视频文件放在 `lab/bin/` 和 `lab/videos/` 下，已加入 `.gitignore`
4. **视频自包含** — 实验所需的视频通过 `ffmpeg` 自动生成，不依赖外部视频文件

---

## 发布

组件发布使用 `qtcloud-devops`。详情见 [`src/provider/CONTRIBUTING.md`](src/provider/CONTRIBUTING.md)。

### 前置条件

- 已安装 [qtcloud-devops](https://github.com/quanttide/qtcloud-devops)
- 拥有仓库推送权限

### 快速参考

```bash
# 更新版本号 → 提交 → 发布
qtcloud-devops release publish --version <scope>/<version> --yes
```

`scope` 列表（`.quanttide/devops/contract.yaml`）：

| scope | 组件 | 目录 |
|-------|------|------|
| `cli` | CLI 工具 | `src/cli` |
| `provider` | API 服务端 | `src/provider` |
