mod blueprint;

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
    },
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Command::Blueprint { topic } => blueprint::run(&topic),
    }
}
