use std::process::Command;

fn cli_binary() -> Command {
    Command::new(env!("CARGO_BIN_EXE_qtcloud-course"))
}

#[test]
fn test_help_contains_all_commands() {
    let output = cli_binary().arg("--help").output().unwrap();
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("course"), "help 应包含 course");
    assert!(stdout.contains("lesson"), "help 应包含 lesson");
    assert!(stdout.contains("scene"), "help 应包含 scene");
}

#[test]
fn test_course_help_has_subcommands() {
    let output = cli_binary().args(["course", "--help"]).output().unwrap();
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("blueprint"), "course help 应包含 blueprint");
    assert!(stdout.contains("design"), "course help 应包含 design");
    assert!(stdout.contains("preview"), "course help 应包含 preview");
}

#[test]
fn test_lesson_help_has_subcommands() {
    let output = cli_binary().args(["lesson", "--help"]).output().unwrap();
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("blueprint"));
    assert!(stdout.contains("design"));
    assert!(stdout.contains("preview"));
}

#[test]
fn test_scene_help_has_subcommands() {
    let output = cli_binary().args(["scene", "--help"]).output().unwrap();
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("blueprint"));
    assert!(stdout.contains("design"));
    assert!(stdout.contains("preview"));
}

#[test]
fn test_course_preview_missing_args_fails() {
    let output = cli_binary().args(["course", "preview"]).output().unwrap();
    assert!(!output.status.success());
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("--from") || stderr.contains("required"), "应提示缺少 --from");
}

#[test]
fn test_lesson_preview_with_template_flag() {
    let output = cli_binary().args(["lesson", "preview", "--help"]).output().unwrap();
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("--template"), "lesson preview help 应包含 --template");
}

#[test]
fn test_scene_preview_has_from_to() {
    let output = cli_binary().args(["scene", "preview", "--help"]).output().unwrap();
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("--from"));
    assert!(stdout.contains("--to"));
}
