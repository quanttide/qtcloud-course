use std::path::PathBuf;

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "qtcloud-course", version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// 课程相关操作
    Course {
        #[command(subcommand)]
        action: CourseAction,
    },
    /// 课时相关操作
    Lesson {
        #[command(subcommand)]
        action: LessonAction,
    },
}

#[derive(Subcommand)]
enum CourseAction {
    /// 从 Markdown 原始资料生成课程蓝图（Program → Course → Phase → Lesson）
    Blueprint {
        /// 原始资料 Markdown 文件路径
        #[arg(long)]
        from: PathBuf,

        /// 输出课程蓝图 JSON 文件路径
        #[arg(long)]
        to: PathBuf,
    },
}

#[derive(Subcommand)]
enum LessonAction {
    /// 从 Markdown 原始资料生成课时蓝图（Lesson → Scene）
    Blueprint {
        /// 原始资料 Markdown 文件路径
        #[arg(long)]
        from: PathBuf,

        /// 输出课时蓝图 JSON 文件路径
        #[arg(long)]
        to: PathBuf,
    },
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Course { action } => match action {
            CourseAction::Blueprint { from, to } => {
                qtcloud_course_cli::course::run(&from, &to, None);
            }
        },
        Commands::Lesson { action } => match action {
            LessonAction::Blueprint { from, to } => {
                qtcloud_course_cli::lesson::run(&from, &to, None);
            }
        },
    }
}
