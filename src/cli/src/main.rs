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
    /// 场景相关操作
    Scene {
        #[command(subcommand)]
        action: SceneAction,
    },
}

#[derive(Subcommand)]
enum CourseAction {
    /// 从 Markdown 原始资料生成课程蓝图（Program → Course → Phase → Lesson）
    Blueprint {
        #[arg(long)]
        from: PathBuf,
        #[arg(long)]
        to: PathBuf,
    },
    /// 基于已有课程蓝图 + 人类指示迭代设计
    Design {
        #[arg(long)]
        file: PathBuf,
        #[arg(long)]
        instruction: String,
        #[arg(long)]
        to: PathBuf,
    },
}

#[derive(Subcommand)]
enum LessonAction {
    /// 从 Markdown 原始资料生成课时蓝图（Lesson → Scene，两遍 LLM）
    Blueprint {
        #[arg(long)]
        from: PathBuf,
        #[arg(long)]
        to: PathBuf,
    },
    /// 基于已有课时蓝图 + 人类指示迭代设计
    Design {
        #[arg(long)]
        file: PathBuf,
        #[arg(long)]
        instruction: String,
        #[arg(long)]
        to: PathBuf,
    },
}

#[derive(Subcommand)]
enum SceneAction {
    /// 从 Markdown 原始资料生成场景蓝图（Scene → Steps，顺序无分支）
    Blueprint {
        #[arg(long)]
        from: PathBuf,
        #[arg(long)]
        to: PathBuf,
    },
    /// 基于已有场景蓝图 + 人类指示迭代设计
    Design {
        #[arg(long)]
        file: PathBuf,
        #[arg(long)]
        instruction: String,
        #[arg(long)]
        to: PathBuf,
    },
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Course { action } => match action {
            CourseAction::Blueprint { from, to } => {
                qtcloud_course_cli::course::run_blueprint(&from, &to, None);
            }
            CourseAction::Design { file, instruction, to } => {
                qtcloud_course_cli::course::run_design(&file, &instruction, &to, None);
            }
        },
        Commands::Lesson { action } => match action {
            LessonAction::Blueprint { from, to } => {
                qtcloud_course_cli::lesson::run_blueprint(&from, &to, None);
            }
            LessonAction::Design { file, instruction, to } => {
                qtcloud_course_cli::lesson::run_design(&file, &instruction, &to, None);
            }
        },
        Commands::Scene { action } => match action {
            SceneAction::Blueprint { from, to } => {
                qtcloud_course_cli::scene::run_blueprint(&from, &to, None);
            }
            SceneAction::Design { file, instruction, to } => {
                qtcloud_course_cli::scene::run_design(&file, &instruction, &to, None);
            }
        },
    }
}
