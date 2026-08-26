// 种子命令：量潮大数据微专业 5 门课目录。
//
// 用法（生产/FC）：QTCLOUD_COURSE_STORE=oss QTCLOUD_OSS_*=<配置> go run ./cmd/seed-catalog
// 用法（本地验证）：go run ./cmd/seed-catalog（默认 local——cwd 下生成 courses.json 等）
// 幂等：已存在 Course("prod") 时跳过。SortOrder 定义课程阶梯顺序。
// 生产实习内容来自内置 data/prod-internship.json（赵交付的真实数据，go:embed）。

package main

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

//go:embed data/prod-internship.json
var prodInternshipJSON []byte

type courseSpec struct {
	id, name, description, status string
}

// 5 门课（①-⑤ 阶梯，SortOrder 1-5）。生产实习（prod）与氛围编程（vibe-coding，真实场景+视频）published 可学习，
// 其余 locked（暂未开放）。
var courseSpecs = []courseSpec{
	{"knowledge-work", "知识工作", "高效知识工作的方法与工具", "draft"},
	{"vibe-coding", "氛围编程", "AI 辅助编程实战（Vibe Coding）", "published"},
	{"big-data-intro", "大数据导论", "大数据基础概念与行业全景", "draft"},
	{"data-engineering", "数据工程", "数据采集、清洗与建模工程实践", "draft"},
	{"prod", "生产实习", "走进真实业务：认识量潮、学会做事、发现机会、Sell Your Demo", "published"},
}

// 其余课程每门 2 课时占位（暂未开放）。
var otherLessons = map[string][]string{
	"knowledge-work":   {"高效阅读与信息整理", "知识管理工具实践"},
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
	backend := newBackend()
	courses, _ := store.NewOSSCourseStore(backend)
	lessons, _ := store.NewOSSLessonStore(backend)
	scenes, _ := store.NewOSSSceneStore(backend)

	// 幂等：已存在则跳过
	if _, ok := courses.Get("prod"); ok {
		log.Println("课程目录已存在，跳过")
		return
	}

	// 生产实习数据（赵交付，go:embed 内置）
	var prod courseJSON
	if err := json.Unmarshal(prodInternshipJSON, &prod); err != nil {
		log.Fatalf("parse course.json: %v", err)
	}
	log.Printf("生产实习数据：%d 模块", len(prod.Modules))

	for i, spec := range courseSpecs {
		course := courses.Create(&domain.Course{
			Name:        spec.name,
			Description: spec.description,
			Status:      spec.status,
			SortOrder:   i + 1,
		})
		if course == nil {
			log.Fatal("写入失败：对象存储不可达？请检查 QTCLOUD_OSS_* 配置")
		}
		// id 固定（前端契约：生产实习 id=prod；其余按 slug）
		courses.SetID(course, spec.id)
		course.ID = spec.id

		switch {
		case spec.id == "prod":
			seedProd(lessons, scenes, course, prod)
		case spec.id == "vibe-coding":
			// 氛围编程的真实场景（含视频）由 cmd/seed 提供（Dockerfile 启动时先执行），
			// 此处不建占位课时，避免覆盖
		default:
			seedLocked(lessons, scenes, course, spec)
		}
	}
	log.Printf("seeded %d courses", len(courseSpecs))
}

// seedProd 生产实习：模块展平为课时（跨模块按 SortOrder 全序），正文存 Scene.VerifyTip。
func seedProd(lessons *store.OSSStore[domain.Lesson], scenes *store.OSSStore[domain.Scene], course *domain.Course, prod courseJSON) {
	sortOrder := 0
	for _, m := range prod.Modules {
		for _, l := range m.Lessons {
			sortOrder++
			lesson := lessons.Create(&domain.Lesson{
				CourseID:    course.ID,
				Title:       l.Title,
				Description: l.Type + "课时",
				Duration:    l.Duration,
				SortOrder:   sortOrder,
				Status:      "published",
			})
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
	}
}

// seedLocked 暂未开放课程：课时占位。
func seedLocked(lessons *store.OSSStore[domain.Lesson], scenes *store.OSSStore[domain.Scene], course *domain.Course, spec courseSpec) {
	for i, title := range otherLessons[spec.id] {
		lesson := lessons.Create(&domain.Lesson{
			CourseID:  course.ID,
			Title:     title,
			SortOrder: i + 1,
			Duration:  10,
			Status:    "published",
		})
		scene := scenes.Create(&domain.Scene{LessonID: lesson.ID, Title: title, Slug: "intro", VerifyTip: "本课时为阅读型内容：" + title + "。"})
		lesson.StartSceneID = scene.ID
		lessons.Update(lesson)
	}
	fmt.Printf("locked 课程已建：%s\n", course.ID)
}

// newBackend 选择存储后端：QTCLOUD_COURSE_STORE=oss → 阿里云 OSS（生产 FC）；
// 否则本地文件（默认，cwd 下 key 即文件路径，本地开发/验证）。
func newBackend() store.Store {
	if os.Getenv("QTCLOUD_COURSE_STORE") == "oss" {
		ossStore, err := store.NewOSS(store.OSSConfig{
			Endpoint:        os.Getenv("QTCLOUD_OSS_ENDPOINT"),
			Bucket:          os.Getenv("QTCLOUD_OSS_BUCKET"),
			AccessKeyID:     os.Getenv("QTCLOUD_OSS_ACCESS_KEY_ID"),
			AccessKeySecret: os.Getenv("QTCLOUD_OSS_ACCESS_KEY_SECRET"),
		})
		if err != nil {
			log.Fatalf("oss init: %v", err)
		}
		return ossStore
	}
	return store.NewLocal()
}
