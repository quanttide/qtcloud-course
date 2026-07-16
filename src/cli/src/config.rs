use std::env;

/// 环境配置统一
pub struct AppConfig {
    /// Provider API 地址，默认 http://localhost:8080
    pub api_base_url: String,
    /// LLM 模型
    pub llm_model: String,
    /// LLM API 地址
    pub llm_base_url: String,
    /// LLM API Key
    pub llm_api_key: String,
}

impl AppConfig {
    /// 从环境变量加载配置
    pub fn from_env() -> Self {
        Self {
            api_base_url: env::var("QTCLOUD_API_BASE_URL")
                .unwrap_or_else(|_| "http://localhost:8080".to_string()),
            llm_model: env::var("LLM_MODEL")
                .unwrap_or_else(|_| "deepseek-v4-flash".to_string()),
            llm_base_url: env::var("LLM_BASE_URL")
                .unwrap_or_else(|_| "https://api.deepseek.com".to_string()),
            llm_api_key: env::var("LLM_API_KEY").unwrap_or_default(),
        }
    }
}
