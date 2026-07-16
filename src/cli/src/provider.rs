use serde_json::Value;
use std::process;

/// Provider API 客户端，用于 import/export 与后端交互
pub struct ProviderClient {
    base_url: String,
    client: ureq::Agent,
}

impl ProviderClient {
    pub fn new(base_url: &str) -> Self {
        Self {
            base_url: base_url.trim_end_matches('/').to_string(),
            client: ureq::Agent::new(),
        }
    }

    /// 导入课程结构到 Provider API
    pub fn import(&self, program: &Value) -> Result<Value, String> {
        let url = format!("{}/api/v1/programs", self.base_url);
        let resp = self
            .client
            .post(&url)
            .set("Content-Type", "application/json")
            .send_json(program)
            .map_err(|e| format!("导入失败: {}", e))?;

        resp.into_json()
            .map_err(|e| format!("解析响应失败: {}", e))
    }

    /// 从 Provider API 导出课程数据
    pub fn export(&self, program_id: &str) -> Result<Value, String> {
        let url = format!("{}/api/v1/programs/{}", self.base_url, program_id);
        let resp = self
            .client
            .get(&url)
            .call()
            .map_err(|e| format!("导出失败: {}", e))?;

        resp.into_json()
            .map_err(|e| format!("解析响应失败: {}", e))
    }

    /// 列出所有课程
    pub fn list_programs(&self) -> Result<Value, String> {
        let url = format!("{}/api/v1/programs", self.base_url);
        let resp = self
            .client
            .get(&url)
            .call()
            .map_err(|e| format!("查询失败: {}", e))?;

        resp.into_json()
            .map_err(|e| format!("解析响应失败: {}", e))
    }
}

/// 运行 import 子命令
pub fn run_import(path: &str, api_base_url: &str) {
    let content = std::fs::read_to_string(path).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", path, e);
        process::exit(1);
    });

    let program: Value = serde_json::from_str(&content).unwrap_or_else(|e| {
        eprintln!("错误：JSON 解析失败 - {}", e);
        process::exit(1);
    });

    let client = ProviderClient::new(api_base_url);
    match client.import(&program) {
        Ok(result) => {
            println!("{}", serde_json::to_string_pretty(&result).unwrap());
        }
        Err(e) => {
            eprintln!("错误：{}", e);
            process::exit(1);
        }
    }
}

/// 运行 export 子命令
pub fn run_export(program_id: &str, output_path: Option<&str>, api_base_url: &str) {
    let client = ProviderClient::new(api_base_url);
    match client.export(program_id) {
        Ok(data) => {
            let json = serde_json::to_string_pretty(&data).unwrap();
            match output_path {
                Some(path) => {
                    std::fs::write(path, &json).unwrap_or_else(|e| {
                        eprintln!("错误：写入 {} 失败 - {}", path, e);
                        process::exit(1);
                    });
                    eprintln!("已写入：{}", path);
                }
                None => println!("{}", json),
            }
        }
        Err(e) => {
            eprintln!("错误：{}", e);
            process::exit(1);
        }
    }
}
