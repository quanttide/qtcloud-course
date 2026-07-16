use std::fs;
use std::path::Path;

pub fn run_course(from: &Path, to: &Path, template: Option<&Path>) {
    let data = load_json(from);
    let title = data["title"].as_str().unwrap_or("");
    let desc = data["description"].as_str().unwrap_or("");
    let content = render_course_content(&data);
    let html = wrap_html(title, desc, &content, template);
    write_html(to, &html);
}

pub fn run_lesson(from: &Path, to: &Path, template: Option<&Path>) {
    let data = load_json(from);
    let title = data["title"].as_str().unwrap_or("");
    let desc = data["description"].as_str().unwrap_or("");
    let content = render_lesson_content(&data);
    let html = wrap_html(title, desc, &content, template);
    write_html(to, &html);
}

pub fn run_scene(from: &Path, to: &Path, template: Option<&Path>) {
    let data = load_json(from);
    let title = data["title"].as_str().unwrap_or("");
    let desc = data["description"].as_str().unwrap_or("");
    let content = render_scene_content(&data);
    let html = wrap_html(title, desc, &content, template);
    write_html(to, &html);
}

fn load_json(from: &Path) -> serde_json::Value {
    let content = fs::read_to_string(from).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", from.display(), e);
        std::process::exit(1);
    });
    serde_json::from_str(&content).unwrap_or_else(|e| {
        eprintln!("错误：JSON 解析失败 - {}", e);
        std::process::exit(1);
    })
}

fn write_html(to: &Path, html: &str) {
    fs::write(to, html).unwrap_or_else(|e| {
        eprintln!("错误：写入 {} 失败 - {}", to.display(), e);
        std::process::exit(1);
    });
    eprintln!("已写入：{}", to.display());
}

// ── Template ──

fn wrap_html(title: &str, desc: &str, content: &str, template: Option<&Path>) -> String {
    let full = match template {
        Some(path) => {
            let tpl = fs::read_to_string(path).unwrap_or_else(|e| {
                eprintln!("错误：读取模板 {} 失败 - {}", path.display(), e);
                std::process::exit(1);
            });
            tpl.replace("{{TITLE}}", title)
                .replace("{{DESCRIPTION}}", desc)
                .replace("{{CONTENT}}", content)
        }
        None => format!(
            r#"<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{} — 蓝图预览</title>
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; background:#0f172a; color:#e2e8f0; min-height:100vh; padding:20px; overflow-x:auto; }}
.container {{ max-width:1200px; margin:0 auto; }}
h1 {{ text-align:center; font-size:22px; margin-bottom:4px; color:#f1f5f9; }}
.subtitle {{ text-align:center; font-size:13px; color:#94a3b8; margin-bottom:20px; }}
</style>
</head>
<body><div class="container">
<h1>📚 {}</h1>
<div class="subtitle">{}</div>
{}
</div></body>
</html>"#,
            esc(title), esc(title), esc(desc), content
        ),
    };
    full
}

// ── Course ──

fn render_course_content(data: &serde_json::Value) -> String {
    let mut html = String::new();
    if let Some(courses) = data["courses"].as_array() {
        html.push_str(&format!(
            r#"<div style="text-align:center;margin-bottom:20px;font-size:13px;color:#64748b;">{} 门课程</div>"#,
            courses.len()
        ));
        for (ci, course) in courses.iter().enumerate() {
            html.push_str(&format!(
                r#"<div class="course" style="background:#1e293b;border-radius:12px;padding:16px;margin-bottom:16px;border:1px solid #334155;">
<div class="course-header" style="display:flex;align-items:center;gap:8px;margin-bottom:6px;">
<span style="font-size:11px;background:#334155;padding:2px 8px;border-radius:4px;color:#38bdf8;font-weight:600;">课程 {}</span>
<span style="font-size:16px;font-weight:600;">{}</span></div>
<div style="font-size:12px;color:#94a3b8;margin-bottom:12px;">{}</div>"#,
                ci + 1, esc(course["title"].as_str().unwrap_or("")),
                esc(course["description"].as_str().unwrap_or("")),
            ));
            if let Some(phases) = course["phases"].as_array() {
                for (pi, phase) in phases.iter().enumerate() {
                    html.push_str(&format!(
                        r#"<div class="phase" style="background:#0f172a;border-radius:8px;padding:12px;margin-bottom:10px;border-left:3px solid #22d3ee;">
<div style="display:flex;align-items:center;gap:6px;margin-bottom:4px;">
<span style="font-size:10px;background:#334155;padding:2px 6px;border-radius:4px;color:#67e8f9;">阶段 {}</span>
<span style="font-size:14px;font-weight:600;">{}</span></div>
<div style="font-size:12px;color:#94a3b8;margin-bottom:8px;">{}</div>
<div class="lessons" style="display:flex;flex-direction:column;gap:4px;">"#,
                        pi + 1, esc(phase["title"].as_str().unwrap_or("")),
                        esc(phase["description"].as_str().unwrap_or("")),
                    ));
                    if let Some(lessons) = phase["lessons"].as_array() {
                        for (li, lesson) in lessons.iter().enumerate() {
                            html.push_str(&format!(
                                r#"<div style="display:flex;align-items:center;gap:8px;font-size:12px;padding:6px 10px;background:#1e293b;border-radius:6px;border-left:2px solid #34d399;">
<span style="font-size:10px;color:#6ee7b7;font-weight:600;min-width:16px;">{}</span>
<span style="font-weight:500;">{}</span>
<span style="color:#64748b;margin-left:auto;font-size:11px;">{}</span></div>"#,
                                li + 1, esc(lesson["title"].as_str().unwrap_or("")),
                                esc(lesson["description"].as_str().unwrap_or("")),
                            ));
                        }
                    }
                    html.push_str("</div></div>");
                }
            }
            html.push_str("</div>");
        }
    }
    html
}

// ── Lesson ──

fn render_lesson_content(data: &serde_json::Value) -> String {
    let scenes = data["scenes"].as_array().cloned().unwrap_or_default();
    let total_exc = scenes.iter().filter(|sc| {
        sc.get("exception").map_or(false, |e| e.is_object() && e["title"].as_str().is_some())
    }).count();

    let mut html = format!(
        r#"<div style="display:flex;justify-content:center;gap:20px;margin-bottom:24px;">
<div style="text-align:center;"><div style="font-size:28px;font-weight:700;color:#38bdf8;">{}</div><div style="font-size:11px;color:#64748b;">场景</div></div>
<div style="text-align:center;"><div style="font-size:28px;font-weight:700;color:#38bdf8;">{}</div><div style="font-size:11px;color:#64748b;">异常分支</div></div>
</div>
<div style="display:flex;align-items:flex-start;gap:0;overflow-x:auto;padding:10px 0;justify-content:center;">"#,
        scenes.len(), total_exc,
    );

    for (i, sc) in scenes.iter().enumerate() {
        html.push_str(&format!(
            r#"<div style="display:flex;flex-direction:column;align-items:center;gap:8px;flex-shrink:0;">
<div class="node" style="background:#1e293b;border-radius:12px;padding:16px;min-width:200px;max-width:220px;border:1px solid #334155;flex-shrink:0;">
<div style="display:flex;align-items:center;gap:6px;margin-bottom:4px;flex-wrap:wrap;">
<span style="font-size:10px;background:#334155;padding:2px 6px;border-radius:4px;color:#94a3b8;font-weight:600;">场景 {}</span>
<span style="font-size:14px;font-weight:600;color:#f1f5f9;">{}</span></div>
<div style="font-size:12px;color:#94a3b8;line-height:1.5;">{}</div>
</div>"#,
            i + 1,
            esc(sc["title"].as_str().unwrap_or("")),
            truncate(sc["description"].as_str().unwrap_or(""), 100),
        ));
        if let Some(exc) = sc.get("exception") {
            if exc.is_object() && exc["title"].as_str().is_some() {
                html.push_str(&format!(
                    r#"<div style="display:flex;flex-direction:column;gap:6px;align-items:center;padding-top:6px;position:relative;">
<div style="position:absolute;top:0;width:2px;height:6px;background:#7f1d1d;"></div>
<div class="node exception" style="background:#1e0a0a;border-radius:12px;padding:14px;min-width:190px;border:1px solid #7f1d1d;">
<div style="display:flex;align-items:center;gap:6px;margin-bottom:4px;">
<span style="font-size:10px;padding:2px 6px;border-radius:4px;color:#fca5a5;font-weight:600;">⚠️ 异常</span>
<span style="font-size:13px;font-weight:600;color:#fca5a5;">{}</span></div>
<div style="font-size:11px;color:#94a3b8;line-height:1.4;">{}</div>
</div></div>"#,
                    esc(exc["title"].as_str().unwrap_or("")),
                    truncate(exc["description"].as_str().unwrap_or(""), 100),
                ));
            }
        }
        html.push_str("</div>");
        if i < scenes.len() - 1 {
            html.push_str(r#"<div style="display:flex;align-items:center;font-size:22px;color:#475569;padding:0 6px;flex-shrink:0;align-self:center;">➜</div>"#);
        }
    }
    html.push_str("</div>");
    html
}

// ── Scene ──

fn render_scene_content(data: &serde_json::Value) -> String {
    let title = data["title"].as_str().unwrap_or("");
    let desc = data["description"].as_str().unwrap_or("");
    let mut html = format!(
        r#"<div style="max-width:700px;margin:0 auto;">
<div class="scene-card" style="background:#1e293b;border-radius:12px;padding:20px;border:1px solid #334155;">
<div style="font-size:18px;font-weight:600;margin-bottom:8px;">{}</div>
<div style="font-size:13px;color:#94a3b8;line-height:1.5;margin-bottom:16px;padding-bottom:16px;border-bottom:1px solid #334155;">{}</div>
<div class="steps" style="display:flex;flex-direction:column;gap:8px;">"#,
        esc(title), esc(desc),
    );
    if let Some(steps) = data["steps"].as_array() {
        for (i, step) in steps.iter().enumerate() {
            html.push_str(&format!(
                r#"<div style="display:flex;gap:12px;background:#0f172a;border-radius:8px;padding:12px;border-left:3px solid #38bdf8;">
<div style="font-size:12px;font-weight:700;color:#38bdf8;min-width:20px;">{}</div>
<div style="flex:1;"><div style="font-size:14px;font-weight:600;margin-bottom:2px;">{}</div>
<div style="font-size:12px;color:#94a3b8;line-height:1.5;">{}</div></div>
</div>"#,
                i + 1,
                esc(step["title"].as_str().unwrap_or("")),
                esc(step["description"].as_str().unwrap_or("")),
            ));
        }
    }
    html.push_str("</div></div></div>");
    html
}

// ── Helpers ──

fn esc(s: &str) -> String {
    s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
}
fn truncate(s: &str, max: usize) -> String {
    if s.len() <= max {
        s.to_string()
    } else {
        let mut end = max;
        while !s.is_char_boundary(end) {
            end -= 1;
        }
        format!("{}...", &s[..end])
    }
}
