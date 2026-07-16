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
    /// 从 Markdown 原始资料生成课程蓝图
    Blueprint {
        #[arg(long)]
        from: PathBuf,
        #[arg(long)]
        to: PathBuf,
    },
    /// 基于已有课程蓝图迭代设计
    Design {
        #[arg(long)]
        file: PathBuf,
        #[arg(long)]
        instruction: String,
        #[arg(long)]
        to: PathBuf,
    },
    /// 将课程蓝图 JSON 渲染为 HTML 预览
    Preview {
        #[arg(long)]
        from: PathBuf,
        #[arg(long)]
        to: PathBuf,
        /// 自定义 HTML 模板文件（含 {{TITLE}} {{DESCRIPTION}} {{CONTENT}} 占位符）
        #[arg(long)]
        template: Option<PathBuf>,
    },
}

#[derive(Subcommand)]
enum LessonAction {
    /// 从 Markdown 原始资料生成课时蓝图
    Blueprint {
        #[arg(long)]
        from: PathBuf,
        #[arg(long)]
        to: PathBuf,
    },
    /// 基于已有课时蓝图迭代设计
    Design {
        #[arg(long)]
        file: PathBuf,
        #[arg(long)]
        instruction: String,
        #[arg(long)]
        to: PathBuf,
    },
    /// 将课时蓝图 JSON 渲染为 DAG HTML 预览
    Preview {
        #[arg(long)]
        from: PathBuf,
        #[arg(long)]
        to: PathBuf,
        /// 自定义 HTML 模板文件（含 {{TITLE}} {{DESCRIPTION}} {{CONTENT}} 占位符）
        #[arg(long)]
        template: Option<PathBuf>,
    },
}

#[derive(Subcommand)]
enum SceneAction {
    /// 从 Markdown 原始资料生成场景蓝图
    Blueprint {
        #[arg(long)]
        from: PathBuf,
        #[arg(long)]
        to: PathBuf,
    },
    /// 基于已有场景蓝图迭代设计
    Design {
        #[arg(long)]
        file: PathBuf,
        #[arg(long)]
        instruction: String,
        #[arg(long)]
        to: PathBuf,
    },
    /// 将场景蓝图 JSON 渲染为 HTML 预览
    Preview {
        #[arg(long)]
        from: PathBuf,
        #[arg(long)]
        to: PathBuf,
        /// 自定义 HTML 模板文件（含 {{TITLE}} {{DESCRIPTION}} {{CONTENT}} 占位符）
        #[arg(long)]
        template: Option<PathBuf>,
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
            CourseAction::Preview { from, to, template } => {
                qtcloud_course_cli::preview::run_course(&from, &to, template.as_deref());
            }
        },
        Commands::Lesson { action } => match action {
            LessonAction::Blueprint { from, to } => {
                qtcloud_course_cli::lesson::run_blueprint(&from, &to, None);
            }
            LessonAction::Design { file, instruction, to } => {
                qtcloud_course_cli::lesson::run_design(&file, &instruction, &to, None);
            }
            LessonAction::Preview { from, to, template } => {
                qtcloud_course_cli::preview::run_lesson(&from, &to, template.as_deref());
            }
        },
        Commands::Scene { action } => match action {
            SceneAction::Blueprint { from, to } => {
                qtcloud_course_cli::scene::run_blueprint(&from, &to, None);
            }
            SceneAction::Design { file, instruction, to } => {
                qtcloud_course_cli::scene::run_design(&file, &instruction, &to, None);
            }
            SceneAction::Preview { from, to, template } => {
                qtcloud_course_cli::preview::run_scene(&from, &to, template.as_deref());
            }
        },
    }
}
