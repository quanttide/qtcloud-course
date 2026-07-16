use std::path::PathBuf;
use std::process;

use clap::{Parser, Subcommand};

use qtcloud_course_cli::config::AppConfig;

#[derive(Parser)]
#[command(name = "qtcloud-course", version)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// 生成课程蓝图
    Course {
        /// 主题，例如 git、docker
        topic: String,

        /// 原始资料文件路径（可选）
        #[arg(long)]
        input_path: Option<PathBuf>,

        /// 输出文件路径（可选，默认 stdout）
        #[arg(long)]
        output_path: Option<PathBuf>,

        /// 输出结构化 JSON（兼容 Studio 导入格式）
        #[arg(long)]
        format: bool,
    },
    /// 校验课程 JSON 数据结构完整性
    Validate {
        /// 课程 JSON 文件路径
        path: String,
    },
    /// 从蓝图 JSON 导入课程结构到 Provider API
    Import {
        /// 课程 JSON 文件路径
        path: String,
    },
    /// 从 Provider API 导出课程数据为 JSON
    Export {
        /// Program ID
        program_id: String,

        /// 输出文件路径（可选，默认 stdout）
        #[arg(long)]
        output_path: Option<String>,
    },
}

fn main() {
    let cli = Cli::parse();
    let config = AppConfig::from_env();

    match cli.command {
        Command::Course {
            topic,
            input_path,
            output_path,
            format,
        } => {
            qtcloud_course_cli::course::run(&topic, input_path, output_path, format, None);
        }
        Command::Validate { path } => {
            run_validate(&path);
        }
        Command::Import { path } => {
            qtcloud_course_cli::provider::run_import(&path, &config.api_base_url);
        }
        Command::Export {
            program_id,
            output_path,
        } => {
            qtcloud_course_cli::provider::run_export(
                &program_id,
                output_path.as_deref(),
                &config.api_base_url,
            );
        }
    }
}

fn run_validate(path: &str) {
    let content = std::fs::read_to_string(path).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", path, e);
        process::exit(1);
    });

    let json: serde_json::Value = serde_json::from_str(&content).unwrap_or_else(|e| {
        eprintln!("错误：JSON 解析失败 - {}", e);
        process::exit(1);
    });

    let result = qtcloud_course_cli::types::validate_course_json(&json);
    if result.valid {
        println!("校验通过：课程数据结构完整 ✓");
    } else {
        eprintln!("校验失败：发现 {} 个问题", result.errors.len());
        for err in &result.errors {
            eprintln!("  - {}", err);
        }
        process::exit(1);
    }
}

#[cfg(test)]
mod tests {

    #[test]
    fn test_validate_valid_json() {
        let json = serde_json::json!({
            "title": "学习Rust",
            "description": "Rust入门课程",
            "courses": [{
                "title": "基础",
                "description": "基础部分",
                "phases": [{
                    "title": "入门",
                    "description": "入门阶段",
                    "lessons": [{
                        "title": "第一课",
                        "description": "学会基础",
                        "duration_minutes": 45,
                        "scenes": [{
                            "title": "介绍",
                            "type": "lecture",
                            "description": "课程介绍",
                            "duration_minutes": 15
                        }]
                    }]
                }]
            }]
        });
        let result = qtcloud_course_cli::types::validate_course_json(&json);
        assert!(result.valid);
        assert!(result.errors.is_empty());
    }

    #[test]
    fn test_validate_missing_title() {
        let json = serde_json::json!({
            "description": "无标题课程",
            "courses": []
        });
        let result = qtcloud_course_cli::types::validate_course_json(&json);
        assert!(!result.valid);
        assert!(result.errors.iter().any(|e| e.contains("title")));
    }

    #[test]
    fn test_validate_missing_courses() {
        let json = serde_json::json!({
            "title": "Test"
        });
        let result = qtcloud_course_cli::types::validate_course_json(&json);
        assert!(!result.valid);
        assert!(result.errors.iter().any(|e| e.contains("courses")));
    }
}
