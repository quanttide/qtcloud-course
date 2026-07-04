mod blueprint;

use std::path::PathBuf;

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "qtcloud-course", version)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// 生成课程蓝图
    Blueprint {
        /// 主题，例如 git、docker
        topic: String,

        /// 原始资料文件路径（可选）
        #[arg(long)]
        input_path: Option<PathBuf>,

        /// 输出文件路径（可选，默认 stdout）
        #[arg(long)]
        output_path: Option<PathBuf>,
    },
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Command::Blueprint { topic, input_path, output_path } => {
            blueprint::run(&topic, input_path, output_path);
        }
    }
}
