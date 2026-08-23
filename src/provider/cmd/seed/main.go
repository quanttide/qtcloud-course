// 种子命令：加载 vibe-coding 教程数据（quanttide-course/data/profile/vibe-coding）到 SQLite。
//
// 用法：DB_PATH=<sqlite文件> go run ./cmd/seed --dir <vibe-coding目录>
// 幂等：已存在 Program("vibe-coding") 时跳过。

package main

import (
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

	_ "modernc.org/sqlite"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

// sceneJSON 是每节课的 scene 数据文件（01-install-zed.json 等）。
type sceneJSON struct {
	Title       string `json:"title"`
	Description string `json:"description"`
	VideoURL    string `json:"videoUrl"`
	Steps       []struct {
		Order       int    `json:"order"`
		Title       string `json:"title"`
		Description string `json:"description"`
	} `json:"steps"`
}

// lessonIndex 是每阶段目录的 index.json。
type lessonIndex struct {
	Description string `json:"description"`
}

func main() {
	dir := flag.String("dir", "", "vibe-coding 数据目录")
	dbPath := os.Getenv("DB_PATH")
	flag.Parse()
	if *dir == "" || dbPath == "" {
		log.Fatal("用法: DB_PATH=<db> go run ./cmd/seed --dir <vibe-coding目录>")
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

	// 幂等：已 seed 过则跳过
	for _, p := range programs.List() {
		if p.Name == "vibe-coding" {
			log.Println("已存在 vibe-coding 数据，跳过")
			return
		}
	}

	prog := programs.Create(&domain.Program{Name: "vibe-coding", Description: "氛围编程（Vibe Coding）系列教程", Status: "published"})
	course := courses.Create(&domain.Course{Name: "氛围编程教程", Description: "Vibe Coding 系列教程", Status: "published"})
	// 固定课程 ID：与公开课程目录（seed-catalog）的 vibe-coding 课程一致，player 端点按 ID 查询
	courses.SetID(course, "vibe-coding")

	entries, err := os.ReadDir(*dir)
	if err != nil {
		log.Fatalf("read dir: %v", err)
	}
	dirs := []string{}
	for _, e := range entries {
		if e.IsDir() {
			dirs = append(dirs, e.Name())
		}
	}
	sort.Strings(dirs)

	for i, d := range dirs {
		phaseDir := filepath.Join(*dir, d)
		idx := readIndex(phaseDir)
		phase := phases.Create(&domain.Phase{
			CourseID:    course.ID,
			Name:        d,
			Description: idx.Description,
			SortOrder:   i,
		})

		lesson := lessons.Create(&domain.Lesson{
			Title:       d,
			Description: idx.Description,
			Status:      "published",
		})
		phase.LessonIDs = append(phase.LessonIDs, lesson.ID)
		phases.Update(phase)

		sceneFiles := []string{}
		fs, _ := os.ReadDir(phaseDir)
		for _, f := range fs {
			if !f.IsDir() && strings.HasSuffix(f.Name(), ".json") && f.Name() != "index.json" {
				sceneFiles = append(sceneFiles, f.Name())
			}
		}
		sort.Strings(sceneFiles)

		var startSceneID string
		for _, sf := range sceneFiles {
			sj := readScene(filepath.Join(phaseDir, sf))
			// 当前上线范围只发布已录制视频课时；E1 排错 JSON 暂不进入播放器。
			if sj.VideoURL == "" {
				continue
			}
			scene := scenes.Create(&domain.Scene{
				LessonID:  lesson.ID,
				Title:     sj.Title,
				Slug:      strings.TrimSuffix(sf, ".json"),
				VideoURL:  sj.VideoURL,
				Steps:     toSteps(sj),
				VerifyTip: sj.Description,
				Choices:   []domain.Choice{},
			})
			if startSceneID == "" {
				startSceneID = scene.ID
			}
		}
		if startSceneID != "" {
			lesson.StartSceneID = startSceneID
			lessons.Update(lesson)
		}
	}

	prog.CourseIDs = []string{course.ID}
	programs.Update(prog)
	fmt.Printf("seed 完成: program=%s course=%s phases=%d\n", prog.ID, course.ID, len(dirs))
}

func readIndex(dir string) lessonIndex {
	raw, err := os.ReadFile(filepath.Join(dir, "index.json"))
	if err != nil {
		return lessonIndex{}
	}
	var idx lessonIndex
	_ = json.Unmarshal(raw, &idx)
	return idx
}

func readScene(path string) sceneJSON {
	raw, err := os.ReadFile(path)
	if err != nil {
		log.Fatalf("read scene %s: %v", path, err)
	}
	var sj sceneJSON
	if err := json.Unmarshal(raw, &sj); err != nil {
		log.Fatalf("parse scene %s: %v", path, err)
	}
	return sj
}

func toSteps(sj sceneJSON) []domain.Step {
	steps := []domain.Step{}
	for i, st := range sj.Steps {
		content := st.Description
		if st.Title != "" {
			content = st.Title + "：" + st.Description
		}
		steps = append(steps, domain.Step{Order: i + 1, Content: content})
	}
	return steps
}
