// 种子命令：量潮大数据微专业 5 门课目录。
//
// 用法：DB_PATH=<sqlite文件> go run ./cmd/seed-catalog --dir <prod-internship目录>
// 幂等：已存在 Program("quanttide-micro") 时跳过；同时把旧 vibe-coding Program 置为 draft
// （不进入学员端公开列表——公开列表只遍历 published Program，5 门课统一挂在 quanttide-micro 下）。
// 生产实习内容来自内置 data/prod-internship.json（赵交付的真实数据，go:embed）。

package main

import (
	"database/sql"
	_ "embed"
	"encoding/json"
	"fmt"
	"log"
	"os"

	_ "modernc.org/sqlite"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

//go:embed data/prod-internship.json
var prodInternshipJSON []byte

type courseSpec struct {
	id, name, description, status string
}

// 5 门课（①-⑤ 阶梯）。生产实习（prod）与氛围编程（vibe-coding，真实场景+视频）published 可学习，
// 其余 locked（暂未开放）。
var courseSpecs = []courseSpec{
	{"knowledge-work", "知识工作", "高效知识工作的方法与工具", "draft"},
	{"vibe-coding", "氛围编程", "AI 辅助编程实战（Vibe Coding）", "published"},
	{"big-data-intro", "大数据导论", "大数据基础概念与行业全景", "draft"},
	{"data-engineering", "数据工程", "数据采集、清洗与建模工程实践", "draft"},
	{"prod", "生产实习", "走进真实业务：认识量潮、学会做事、发现机会、Sell Your Demo", "published"},
}

// 其余 4 门课每门 1 阶段 × 2 课时（占位，暂未开放）。
var otherLessons = map[string][]string{
	"knowledge-work":   {"高效阅读与信息整理", "知识管理工具实践"},
	"vibe-coding":      {"AI 编程基础", "从提示词到完整项目"},
	"big-data-intro":   {"大数据全景", "大数据技术栈导览"},
	"data-engineering": {"数据管线入门", "数据质量与治理"},
}

// courseJSON 生产实习数据文件结构（data/prod-internship/course.json）。
type courseJSON struct {
	Name    string `json:"name"`
	Modules []struct {
		Name    string `json:"name"`
		Lessons []struct {
			Title    string `json:"title"`
			Duration int    `json:"duration"`
			Type     string `json:"type"`
			Content  string `json:"content"`
		} `json:"lessons"`
	} `json:"modules"`
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

	// 生产实习数据（赵交付，go:embed 内置）
	var prod courseJSON
	if err := json.Unmarshal(prodInternshipJSON, &prod); err != nil {
		log.Fatalf("parse course.json: %v", err)
	}
	log.Printf("生产实习数据：%d 模块", len(prod.Modules))

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
		courses.SetID(course, spec.id)
		prog.CourseIDs = append(prog.CourseIDs, course.ID)

		if spec.id == "prod" {
			seedProd(phases, lessons, scenes, course, prod)
		} else if spec.id == "vibe-coding" {
			// 氛围编程的真实场景（含视频）由 course-seed 提供（cmd/seed，Dockerfile 启动时先执行），
			// 此处不建占位课时，避免覆盖
		} else {
			seedLocked(phases, lessons, scenes, course, spec)
		}
	}
	programs.Update(prog)
	log.Printf("seeded %d courses under quanttide-micro", len(courseSpecs))
}

// seedProd 生产实习：5 模块 × 课时（阅读/练习），正文存 Scene.VerifyTip（播放器 Caption 显示）。
func seedProd(phases *store.SQLiteStore[domain.Phase], lessons *store.SQLiteStore[domain.Lesson], scenes *store.SQLiteStore[domain.Scene], course *domain.Course, prod courseJSON) {
	for i, m := range prod.Modules {
		phase := phases.Create(&domain.Phase{
			CourseID:  course.ID,
			Name:      m.Name,
			SortOrder: i + 1,
		})
		phases.SetID(phase, fmt.Sprintf("m%d", i+1))
		for _, l := range m.Lessons {
			lesson := lessons.Create(&domain.Lesson{
				Title:       l.Title,
				Description: l.Type + "课时",
				Duration:    l.Duration,
				Status:      "published",
			})
			phase.LessonIDs = append(phase.LessonIDs, lesson.ID)
			// 阅读/练习型课时：1 个正文场景（无视频）
			scene := scenes.Create(&domain.Scene{
				LessonID:  lesson.ID,
				Title:     l.Title,
				Slug:      "intro",
				VerifyTip: l.Content,
			})
			lesson.StartSceneID = scene.ID
			lessons.Update(lesson)
		}
		phases.Update(phase)
	}
}

// seedLocked 暂未开放课程：1 阶段 × 2 课时占位。
func seedLocked(phases *store.SQLiteStore[domain.Phase], lessons *store.SQLiteStore[domain.Lesson], scenes *store.SQLiteStore[domain.Scene], course *domain.Course, spec courseSpec) {
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
