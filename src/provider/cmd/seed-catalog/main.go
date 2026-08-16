// 种子命令：量潮大数据微专业 5 门课目录（生产实习 5 模块 mock，赵数据到后替换）。
//
// 用法：DB_PATH=<sqlite文件> go run ./cmd/seed-catalog
// 幂等：已存在 Program("quanttide-micro") 时跳过；同时把旧 vibe-coding Program 置为 draft
// （不进入学员端公开列表——公开列表只遍历 published Program，5 门课统一挂在 quanttide-micro 下）。

package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "modernc.org/sqlite"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

type courseSpec struct {
	id, name, description, status string
}

// 5 门课（①-⑤ 阶梯）。生产实习（prod）为唯一 published（可学习），其余 locked（暂未开放）。
var courseSpecs = []courseSpec{
	{"knowledge-work", "知识工作", "高效知识工作的方法与工具", "draft"},
	{"vibe-coding", "氛围编程", "AI 辅助编程实战（Vibe Coding）", "draft"},
	{"big-data-intro", "大数据导论", "大数据基础概念与行业全景", "draft"},
	{"data-engineering", "数据工程", "数据采集、清洗与建模工程实践", "draft"},
	{"prod", "生产实习", "走进真实业务，从发现盲区到微型创业", "published"},
}

// 生产实习 5 模块（Phase）。每模块 3 课时（阅读型）。
var prodModules = []struct {
	name    string
	lessons []string
}{
	{"量潮是谁", []string{"量潮的创立故事", "组织架构与团队分工", "量潮云与量潮课堂"}},
	{"业务与市场", []string{"产品矩阵概览", "目标客户与场景", "商业模式与增长"}},
	{"方法论与工具", []string{"知识工作方法", "数据思维入门", "常用效率工具"}},
	{"项目实战", []string{"发现业务盲区", "选题与快速验证", "最小方案设计"}},
	{"微型创业", []string{"立项申请书填写", "个人独立还是搭档", "提交立项与后续"}},
}

// 其余 4 门课每门 1 阶段 × 2 课时（占位，暂未开放）。
var otherLessons = map[string][]string{
	"knowledge-work":   {"高效阅读与信息整理", "知识管理工具实践"},
	"vibe-coding":      {"AI 编程基础", "从提示词到完整项目"},
	"big-data-intro":   {"大数据全景", "大数据技术栈导览"},
	"data-engineering": {"数据管线入门", "数据质量与治理"},
}

func main() {
	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		log.Fatal("用法: DB_PATH=<db> go run ./cmd/seed-catalog")
	}
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		log.Fatalf("open db: %v", err)
	}
	defer db.Close()

	programs, _ := store.NewSQLiteProgramStore(db)
	courses, _ := store.NewSQLiteCourseStore(db)
	phases, _ := store.NewSQLitePhaseStore(db)
	lessons, _ := store.NewSQLiteLessonStore(db)
	scenes, _ := store.NewSQLiteSceneStore(db)

	// 幂等：已存在则跳过
	for _, p := range programs.List() {
		if p.Name == "quanttide-micro" {
			log.Println("quanttide-micro 已存在，跳过")
			return
		}
	}

	// 旧 vibe-coding Program 置 draft（不进入公开列表；数据保留管理端可见）
	for _, p := range programs.List() {
		if p.Name == "vibe-coding" {
			p.Status = "draft"
			programs.Update(p)
			log.Println("vibe-coding program → draft")
		}
	}

	prog := programs.Create(&domain.Program{
		Name:        "quanttide-micro",
		Description: "量潮大数据微专业（5 门阶梯课程）",
		Status:      "published",
	})

	for _, spec := range courseSpecs {
		course := courses.Create(&domain.Course{
			Name:        spec.name,
			Description: spec.description,
			Status:      spec.status,
		})
		// id 固定（前端契约：生产实习 id=prod；其余按 slug）
		course.ID = spec.id
		courses.Update(course)
		prog.CourseIDs = append(prog.CourseIDs, course.ID)

		seedLessonsFor(phases, lessons, scenes, course, spec)
	}
	programs.Update(prog)
	log.Printf("seeded %d courses under quanttide-micro", len(courseSpecs))
}

func seedLessonsFor(phases *store.SQLiteStore[domain.Phase], lessons *store.SQLiteStore[domain.Lesson], scenes *store.SQLiteStore[domain.Scene], course *domain.Course, spec courseSpec) {
	if spec.id == "prod" {
		for i, m := range prodModules {
			phase := phases.Create(&domain.Phase{
				CourseID:  course.ID,
				Name:      m.name,
				SortOrder: i + 1,
			})
			phase.ID = fmt.Sprintf("m%d", i+1)
			for _, title := range m.lessons {
				lesson := lessons.Create(&domain.Lesson{
					Title:       title,
					Description: "阅读课时",
					Duration:    10,
					Status:      "published",
				})
				phase.LessonIDs = append(phase.LessonIDs, lesson.ID)
				// 阅读型课时：1 个 caption 场景（无视频）
				scene := scenes.Create(&domain.Scene{
					LessonID: lesson.ID,
					Title:    title,
					Slug:     "intro",
					VerifyTip: "本课时为阅读型内容：" + title + "。",
				})
				lesson.StartSceneID = scene.ID
				lessons.Update(lesson)
			}
			phases.Update(phase)
		}
		return
	}
	// 暂未开放课程：1 阶段 × 2 课时占位
	phase := phases.Create(&domain.Phase{CourseID: course.ID, Name: "课程内容", SortOrder: 1})
	for _, title := range otherLessons[spec.id] {
		lesson := lessons.Create(&domain.Lesson{Title: title, Duration: 10, Status: "published"})
		phase.LessonIDs = append(phase.LessonIDs, lesson.ID)
		scene := scenes.Create(&domain.Scene{LessonID: lesson.ID, Title: title, Slug: "intro", VerifyTip: "本课时为阅读型内容：" + title + "。"})
		lesson.StartSceneID = scene.ID
		lessons.Update(lesson)
	}
	phases.Update(phase)
}
