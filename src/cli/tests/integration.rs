use std::io::{BufRead, BufReader, Read, Write};
use std::net::{TcpListener, TcpStream};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

use serde_json::Value;

use qtcloud_course_cli::provider::ProviderClient;
use qtcloud_course_cli::types::validate_course_json;

// ── Helper: Mock Provider 服务器 ──────────────────────────────

/// 启动一个 mock Provider HTTP 服务器，返回 (base_url, stored_data)
fn start_mock_provider() -> (String, Arc<Mutex<Option<Value>>>) {
    let listener = TcpListener::bind("127.0.0.1:0").unwrap();
    let port = listener.local_addr().unwrap().port();
    let base_url = format!("http://127.0.0.1:{}", port);

    let stored: Arc<Mutex<Option<Value>>> = Arc::new(Mutex::new(None));
    let stored_clone = Arc::clone(&stored);

    thread::spawn(move || {
        for stream in listener.incoming().flatten() {
            handle_connection(stream, &stored_clone);
        }
    });

    // 等待服务器启动
    thread::sleep(Duration::from_millis(50));

    (base_url, stored)
}

fn handle_connection(stream: TcpStream, stored: &Mutex<Option<Value>>) {
    let mut reader = BufReader::new(stream);

    // 读取请求行
    let mut request_line = String::new();
    if reader.read_line(&mut request_line).unwrap_or(0) == 0 {
        return;
    }
    let request_line = request_line.trim_end().to_string();

    // 读取请求头，解析 Content-Length
    let mut content_length = 0usize;
    loop {
        let mut header = String::new();
        if reader.read_line(&mut header).unwrap_or(0) == 0 {
            break;
        }
        let header = header.trim_end();
        if header.is_empty() {
            break;
        }
        if let Some(len_str) = header
            .strip_prefix("Content-Length:")
            .or_else(|| header.strip_prefix("content-length:"))
        {
            content_length = len_str.trim().parse().unwrap_or(0);
        }
    }

    // 读取请求体
    let body_str = if content_length > 0 {
        let mut body = vec![0u8; content_length];
        let _ = reader.read_exact(&mut body);
        String::from_utf8(body).unwrap_or_default()
    } else {
        String::new()
    };

    // 构造响应
    let response = if request_line.starts_with("POST /api/v1/programs") {
        let trimmed = body_str.trim();
        if !trimmed.is_empty() {
            if let Ok(value) = serde_json::from_str::<Value>(trimmed) {
                *stored.lock().unwrap() = Some(value);
            }
        }
        let resp_body = "{\"id\": \"test-program-id\"}";
        format!(
            "HTTP/1.1 201 Created\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
            resp_body.len(),
            resp_body
        )
    } else if request_line.starts_with("GET /api/v1/programs/") {
        let data = stored.lock().unwrap();
        match data.as_ref() {
            Some(value) => {
                let resp_body = serde_json::to_string(value).unwrap();
                format!(
                    "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                    resp_body.len(),
                    resp_body
                )
            }
            None => {
                "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".to_string()
            }
        }
    } else {
        "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".to_string()
    };

    // 写入响应
    let _ = reader.into_inner().write_all(response.as_bytes());
}

// ── Fixture 辅助 ─────────────────────────────────────────────

fn fixture_path(name: &str) -> String {
    format!(
        "{}/tests/fixtures/{}",
        env!("CARGO_MANIFEST_DIR"),
        name
    )
}

fn load_fixture(name: &str) -> Value {
    let path = fixture_path(name);
    let content = std::fs::read_to_string(&path).unwrap_or_else(|e| {
        panic!("无法读取 fixture {}: {}", path, e);
    });
    serde_json::from_str(&content).unwrap()
}

// ── 场景 1：validate 边界情况 ────────────────────────────────

#[test]
fn test_validate_valid_fixture() {
    let json = load_fixture("valid_blueprint.json");
    let result = validate_course_json(&json);
    assert!(result.valid, "合法的蓝图应通过校验: {:?}", result.errors);
}

#[test]
fn test_validate_invalid_fixture() {
    let json = load_fixture("invalid_blueprint.json");
    let result = validate_course_json(&json);
    assert!(!result.valid, "非法的蓝图应校验失败");
    assert!(
        result.errors.iter().any(|e| e.contains("title")),
        "应有关于 title 的错误: {:?}",
        result.errors
    );
}

#[test]
fn test_validate_empty_courses_array() {
    let json = serde_json::json!({
        "title": "空课程项目",
        "description": "还没有课程",
        "courses": []
    });
    let result = validate_course_json(&json);
    assert!(result.valid, "空 courses 数组应合法: {:?}", result.errors);
}

#[test]
fn test_validate_deeply_nested_structure() {
    let json = serde_json::json!({
        "title": "深度学习课程",
        "description": "多层嵌套验证",
        "courses": (0..3).map(|i| serde_json::json!({
            "title": format!("课程 {}", i),
            "description": format!("课程 {} 描述", i),
            "phases": (0..2).map(|j| serde_json::json!({
                "title": format!("阶段 {}-{}", i, j),
                "description": format!("阶段描述"),
                "lessons": (0..2).map(|k| serde_json::json!({
                    "title": format!("第 {} 课", k),
                    "description": format!("课程描述"),
                    "scenes": (0..2).map(|l| serde_json::json!({
                        "title": format!("场景 {}", l),
                        "type": if l == 0 { "lecture" } else { "exercise" },
                        "description": "场景描述",
                    })).collect::<Vec<_>>()
                })).collect::<Vec<_>>()
            })).collect::<Vec<_>>()
        })).collect::<Vec<_>>()
    });
    let result = validate_course_json(&json);
    assert!(result.valid, "深层嵌套应合法: {:?}", result.errors);
}

#[test]
fn test_validate_missing_scenes() {
    let json = serde_json::json!({
        "title": "测试",
        "description": "测试",
        "courses": [{
            "title": "课程",
            "description": "课程",
            "phases": [{
                "title": "阶段",
                "description": "阶段",
                "lessons": [{
                    "title": "课",
                    "description": "课"
                }]
            }]
        }]
    });
    let result = validate_course_json(&json);
    assert!(result.valid, "缺少 scenes 应合法（场景层可选）: {:?}", result.errors);
}

// ── 场景 2：import/export 与 Provider 交互 ───────────────────

#[test]
fn test_import_sends_correct_request() {
    let (base_url, stored) = start_mock_provider();
    let client = ProviderClient::new(&base_url);

    let program = load_fixture("valid_blueprint.json");
    let result = client.import(&program);

    assert!(result.is_ok(), "import 应成功: {:?}", result.err());

    let stored_data = stored.lock().unwrap();
    assert!(stored_data.is_some(), "mock server 应收到数据");
    if let Some(ref data) = *stored_data {
        assert_eq!(
            data["title"].as_str().unwrap(),
            "Git 入门与协作",
            "mock server 收到的数据应包含正确 title"
        );
    }
}

#[test]
fn test_import_export_roundtrip() {
    let (base_url, _stored) = start_mock_provider();
    let client = ProviderClient::new(&base_url);

    // 导入
    let program = load_fixture("valid_blueprint.json");
    let import_result = client.import(&program);
    assert!(import_result.is_ok(), "import 应成功");

    // 导出
    let export_result = client.export("test-program-id");
    assert!(export_result.is_ok(), "export 应成功: {:?}", export_result.err());

    // 验证 roundtrip 一致
    let exported = export_result.unwrap();
    assert_eq!(
        exported["title"].as_str().unwrap(),
        "Git 入门与协作",
        "roundtrip 后 title 应一致"
    );
    assert_eq!(
        exported["description"].as_str().unwrap(),
        "从零掌握 Git 版本控制，理解核心概念并能在团队中协作",
        "roundtrip 后 description 应一致"
    );
    assert!(
        exported["courses"].is_array(),
        "roundtrip 后应包含 courses 数组"
    );
}

#[test]
fn test_import_connection_refused() {
    let client = ProviderClient::new("http://127.0.0.1:1");

    let program = load_fixture("valid_blueprint.json");
    let result = client.import(&program);

    assert!(result.is_err(), "连接被拒绝时应返回错误");
    let err = result.err().unwrap();
    assert!(
        err.contains("导入失败") || err.contains("Connection refused"),
        "错误信息应包含连接失败提示: {}",
        err
    );
}

#[test]
fn test_export_nonexistent_program() {
    let (base_url, _stored) = start_mock_provider();
    let client = ProviderClient::new(&base_url);

    let result = client.export("nonexistent-id");
    assert!(result.is_err(), "导出不存在的 program 应失败");
}

// ── 场景 3：验证 CLI 核心逻辑可处理 fixture ─────────────────

#[test]
fn test_validate_via_cli_entrypoint() {
    let json = load_fixture("valid_blueprint.json");
    let result = validate_course_json(&json);
    assert!(result.valid, "合法 fixture 校验应通过");

    let invalid = load_fixture("invalid_blueprint.json");
    let result2 = validate_course_json(&invalid);
    assert!(!result2.valid, "非法 fixture 校验应失败");
}
