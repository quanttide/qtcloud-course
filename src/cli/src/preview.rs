use std::fs;
use std::path::Path;

pub fn run_course(from: &Path, to: &Path) {
    let content = fs::read_to_string(from).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", from.display(), e);
        std::process::exit(1);
    });
    let data: serde_json::Value = serde_json::from_str(&content).unwrap_or_else(|e| {
        eprintln!("错误：JSON 解析失败 - {}", e);
        std::process::exit(1);
    });

    let title = data["title"].as_str().unwrap_or("");
    let desc = data["description"].as_str().unwrap_or("");
    let courses = data["courses"].as_array().map(|a| a.len()).unwrap_or(0);

    let mut phases_html = String::new();
    if let Some(courses_arr) = data["courses"].as_array() {
        for (ci, course) in courses_arr.iter().enumerate() {
            phases_html.push_str(&format!(
                r#"<div class="course"><div class="course-header"><span class="course-num">课程 {}</span><span class="course-title">{}</span></div><div class="course-desc">{}</div>"#,
                ci + 1,
                esc(course["title"].as_str().unwrap_or("")),
                esc(course["description"].as_str().unwrap_or("")),
            ));
            if let Some(phases) = course["phases"].as_array() {
                for (pi, phase) in phases.iter().enumerate() {
                    phases_html.push_str(&format!(
                        r#"<div class="phase"><div class="phase-header"><span class="phase-num">阶段 {}</span><span class="phase-title">{}</span></div><div class="phase-desc">{}</div><div class="lessons">"#,
                        pi + 1,
                        esc(phase["title"].as_str().unwrap_or("")),
                        esc(phase["description"].as_str().unwrap_or("")),
                    ));
                    if let Some(lessons) = phase["lessons"].as_array() {
                        for (li, lesson) in lessons.iter().enumerate() {
                            phases_html.push_str(&format!(
                                r#"<div class="lesson"><span class="lesson-num">{}</span><span class="lesson-title">{}</span><span class="lesson-desc">{}</span></div>"#,
                                li + 1,
                                esc(lesson["title"].as_str().unwrap_or("")),
                                esc(lesson["description"].as_str().unwrap_or("")),
                            ));
                        }
                    }
                    phases_html.push_str("</div></div>");
                }
            }
            phases_html.push_str("</div>");
        }
    }

    let html = format!(
        r#"<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{} — 课程蓝图</title>
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; background:#0f172a; color:#e2e8f0; padding:20px; }}
.container {{ max-width:1000px; margin:0 auto; }}
h1 {{ text-align:center; font-size:22px; margin-bottom:4px; color:#f1f5f9; }}
.subtitle {{ text-align:center; font-size:13px; color:#94a3b8; margin-bottom:20px; }}
.course {{ background:#1e293b; border-radius:12px; padding:16px; margin-bottom:16px; border:1px solid #334155; }}
.course-header {{ display:flex; align-items:center; gap:8px; margin-bottom:6px; }}
.course-num {{ font-size:11px; background:#334155; padding:2px 8px; border-radius:4px; color:#38bdf8; font-weight:600; }}
.course-title {{ font-size:16px; font-weight:600; }}
.course-desc {{ font-size:12px; color:#94a3b8; margin-bottom:12px; }}
.phase {{ background:#0f172a; border-radius:8px; padding:12px; margin-bottom:10px; border-left:3px solid #22d3ee; }}
.phase-header {{ display:flex; align-items:center; gap:6px; margin-bottom:4px; }}
.phase-num {{ font-size:10px; background:#334155; padding:2px 6px; border-radius:4px; color:#67e8f9; }}
.phase-title {{ font-size:14px; font-weight:600; }}
.phase-desc {{ font-size:12px; color:#94a3b8; margin-bottom:8px; }}
.lessons {{ display:flex; flex-direction:column; gap:4px; }}
.lesson {{ display:flex; align-items:center; gap:8px; font-size:12px; padding:6px 10px; background:#1e293b; border-radius:6px; border-left:2px solid #34d399; }}
.lesson-num {{ font-size:10px; color:#6ee7b7; font-weight:600; min-width:16px; }}
.lesson-title {{ font-weight:500; color:#e2e8f0; }}
.lesson-desc {{ color:#64748b; margin-left:auto; font-size:11px; }}
</style>
</head>
<body><div class="container">
<h1>📚 {}</h1>
<div class="subtitle">{}</div>
<div class="stats" style="text-align:center;margin-bottom:20px;font-size:13px;color:#64748b;">{} 门课程</div>
{}
</div></body>
</html>"#,
        esc(title), esc(title), esc(desc), courses, phases_html
    );

    fs::write(to, &html).unwrap_or_else(|e| {
        eprintln!("错误：写入 {} 失败 - {}", to.display(), e);
        std::process::exit(1);
    });
    eprintln!("已写入：{}", to.display());
}

pub fn run_lesson(from: &Path, to: &Path) {
    let content = fs::read_to_string(from).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", from.display(), e);
        std::process::exit(1);
    });
    let data: serde_json::Value = serde_json::from_str(&content).unwrap_or_else(|e| {
        eprintln!("错误：JSON 解析失败 - {}", e);
        std::process::exit(1);
    });

    let title = data["title"].as_str().unwrap_or("");
    let desc = data["description"].as_str().unwrap_or("");
    let scenes = data["scenes"].as_array();

    let main_scenes: Vec<&serde_json::Value> = scenes
        .map(|s| s.iter().filter(|sc| !sc.get("exception").map_or(false, |e| e.is_object())).collect())
        .unwrap_or_default();

    let exc_scenes: Vec<&serde_json::Value> = scenes
        .map(|s| s.iter().filter(|sc| sc.get("exception").map_or(false, |e| e.is_object())).collect())
        .unwrap_or_default();

    let mut scene_cards = String::new();
    for (i, sc) in main_scenes.iter().enumerate() {
        scene_cards.push_str(&format!(
            r#"  <div class="dag-node-group"><div class="node"><div class="node-header"><span class="node-num">场景 {}</span><span class="node-title">{}</span></div><div class="node-desc">{}</div></div>"#,
            i + 1,
            esc(sc["title"].as_str().unwrap_or("")),
            esc(sc["description"].as_str().unwrap_or(""))[..100.min(sc["description"].as_str().map_or(0, |s| s.len()))].to_string(),
        ));
        if let Some(exc) = sc.get("exception") {
            if exc.is_object() && exc["title"].as_str().is_some() {
                scene_cards.push_str(&format!(
                    r#"<div class="exc-group"><div class="node exception"><div class="node-header"><span class="node-num">⚠️ 异常</span><span class="node-title">{}</span></div><div class="node-desc">{}</div></div></div>"#,
                    esc(exc["title"].as_str().unwrap_or("")),
                    esc(exc["description"].as_str().unwrap_or(""))[..100.min(exc["description"].as_str().map_or(0, |s| s.len()))].to_string(),
                ));
            }
        }
        scene_cards.push_str("  </div>\n");
        if i < main_scenes.len() - 1 {
            scene_cards.push_str("  <div class=\"arrow\">➜</div>\n");
        }
    }

    let html = format!(
        r#"<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{} — 课时蓝图</title>
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; background:#0f172a; color:#e2e8f0; min-height:100vh; padding:20px; overflow-x:auto; }}
.container {{ max-width:1600px; margin:0 auto; }}
h1 {{ text-align:center; font-size:22px; margin-bottom:4px; color:#f1f5f9; }}
.subtitle {{ text-align:center; font-size:13px; color:#94a3b8; margin-bottom:16px; }}
.stats {{ display:flex; justify-content:center; gap:20px; margin-bottom:24px; }}
.stat {{ text-align:center; }}
.stat-value {{ font-size:28px; font-weight:700; color:#38bdf8; }}
.stat-label {{ font-size:11px; color:#64748b; }}
.dag-row {{ display:flex; align-items:flex-start; gap:0; overflow-x:auto; padding:10px 0; justify-content:center; }}
.dag-node-group {{ display:flex; flex-direction:column; align-items:center; gap:8px; flex-shrink:0; }}
.node {{ background:#1e293b; border-radius:12px; padding:16px; min-width:200px; max-width:220px; border:1px solid #334155; flex-shrink:0; transition:all .2s; }}
.node:hover {{ border-color:#38bdf8; box-shadow:0 0 20px rgba(56,189,248,.1); }}
.node-header {{ display:flex; align-items:center; gap:6px; margin-bottom:4px; flex-wrap:wrap; }}
.node-num {{ font-size:10px; background:#334155; padding:2px 6px; border-radius:4px; color:#94a3b8; font-weight:600; white-space:nowrap; }}
.node-title {{ font-size:14px; font-weight:600; color:#f1f5f9; }}
.node-desc {{ font-size:12px; color:#94a3b8; line-height:1.5; }}
.node.exception {{ border-color:#7f1d1d; background:#1e0a0a; min-width:190px; }}
.node.exception .node-title {{ color:#fca5a5; }}
.node.exception:hover {{ border-color:#ef4444; box-shadow:0 0 20px rgba(239,68,68,.1); }}
.exc-group {{ display:flex; flex-direction:column; gap:6px; align-items:center; position:relative; padding-top:6px; }}
.exc-group::before {{ content:''; position:absolute; top:0; width:2px; height:6px; background:#7f1d1d; }}
.arrow {{ display:flex; align-items:center; font-size:22px; color:#475569; padding:0 6px; flex-shrink:0; align-self:center; user-select:none; }}
</style>
</head>
<body><div class="container">
<h1>📚 {}</h1>
<div class="subtitle">{}</div>
<div class="stats">
  <div class="stat"><div class="stat-value">{}</div><div class="stat-label">场景</div></div>
  <div class="stat"><div class="stat-value">{}</div><div class="stat-label">异常分支</div></div>
</div>
<div class="dag-row">
{}
</div>
</div></body>
</html>"#,
        esc(title), esc(title), esc(desc),
        main_scenes.len(), exc_scenes.len(),
        scene_cards
    );

    fs::write(to, &html).unwrap_or_else(|e| {
        eprintln!("错误：写入 {} 失败 - {}", to.display(), e);
        std::process::exit(1);
    });
    eprintln!("已写入：{}", to.display());
}

pub fn run_scene(from: &Path, to: &Path) {
    let content = fs::read_to_string(from).unwrap_or_else(|e| {
        eprintln!("错误：读取 {} 失败 - {}", from.display(), e);
        std::process::exit(1);
    });
    let data: serde_json::Value = serde_json::from_str(&content).unwrap_or_else(|e| {
        eprintln!("错误：JSON 解析失败 - {}", e);
        std::process::exit(1);
    });

    let title = data["title"].as_str().unwrap_or("");
    let desc = data["description"].as_str().unwrap_or("");
    let steps = data["steps"].as_array();

    let mut steps_html = String::new();
    if let Some(steps_arr) = steps {
        for (i, step) in steps_arr.iter().enumerate() {
            steps_html.push_str(&format!(
                r#"<div class="step"><div class="step-num">{}</div><div class="step-body"><div class="step-title">{}</div><div class="step-desc">{}</div></div></div>"#,
                i + 1,
                esc(step["title"].as_str().unwrap_or("")),
                esc(step["description"].as_str().unwrap_or("")),
            ));
        }
    }

    let html = format!(
        r#"<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{} — 场景蓝图</title>
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; background:#0f172a; color:#e2e8f0; padding:20px; }}
.container {{ max-width:700px; margin:0 auto; }}
h1 {{ text-align:center; font-size:22px; margin-bottom:4px; color:#f1f5f9; }}
.subtitle {{ text-align:center; font-size:13px; color:#94a3b8; margin-bottom:20px; }}
.scene-card {{ background:#1e293b; border-radius:12px; padding:20px; border:1px solid #334155; }}
.scene-title {{ font-size:18px; font-weight:600; margin-bottom:8px; }}
.scene-desc {{ font-size:13px; color:#94a3b8; line-height:1.5; margin-bottom:16px; padding-bottom:16px; border-bottom:1px solid #334155; }}
.steps {{ display:flex; flex-direction:column; gap:8px; }}
.step {{ display:flex; gap:12px; background:#0f172a; border-radius:8px; padding:12px; border-left:3px solid #38bdf8; }}
.step-num {{ font-size:12px; font-weight:700; color:#38bdf8; min-width:20px; }}
.step-body {{ flex:1; }}
.step-title {{ font-size:14px; font-weight:600; margin-bottom:2px; }}
.step-desc {{ font-size:12px; color:#94a3b8; line-height:1.5; }}
</style>
</head>
<body><div class="container">
<h1>📚 {}</h1>
<div class="subtitle">{}</div>
<div class="scene-card">
<div class="scene-title">{}</div>
<div class="scene-desc">{}</div>
<div class="steps">{}</div>
</div>
</div></body>
</html>"#,
        esc(title), esc(title), esc(desc),
        esc(title), esc(desc), steps_html
    );

    fs::write(to, &html).unwrap_or_else(|e| {
        eprintln!("错误：写入 {} 失败 - {}", to.display(), e);
        std::process::exit(1);
    });
    eprintln!("已写入：{}", to.display());
}

fn esc(s: &str) -> String {
    s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
}
