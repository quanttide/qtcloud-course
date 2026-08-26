// 种子命令：加载 vibe-coding 教程数据（quanttide-course/data/profile/vibe-coding）到对象存储。
//
// 用法（生产/FC）：QTCLOUD_COURSE_STORE=oss QTCLOUD_OSS_*=<配置> go run ./cmd/seed --dir <vibe-coding目录>
// 用法（本地验证）：go run ./cmd/seed --dir <vibe-coding目录>（默认 local——cwd 下生成 courses.json 等）
// 幂等：已存在 Course("vibe-coding") 时跳过。

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

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
	flag.Parse()
	if *dir == "" {
		log.Fatal("用法: go run ./cmd/seed --dir <vibe-coding目录>（QTCLOUD_COURSE_STORE=oss 时写入 OSS）")
	}

	backend := newBackend()
	courses, _ := store.NewOSSCourseStore(backend)
	lessons, _ := store.NewOSSLessonStore(backend)
	scenes, _ := store.NewOSSSceneStore(backend)

	// 幂等：已 seed 过则跳过
	if _, ok := courses.Get("vibe-coding"); ok {
		log.Println("已存在 vibe-coding 数据，跳过")
		return
	}

	course := courses.Create(&domain.Course{Name: "氛围编程教程", Description: "Vibe Coding 系列教程", Status: "published"})
	if course == nil {
		log.Fatal("写入失败：对象存储不可达？请检查 QTCLOUD_OSS_* 配置")
	}
	// 固定课程 ID：与公开课程目录（seed-catalog）的 vibe-coding 课程一致
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
		lessonDir := filepath.Join(*dir, d)
		idx := readIndex(lessonDir)
		lesson := lessons.Create(&domain.Lesson{
			CourseID:    course.ID,
			Title:       d,
			Description: idx.Description,
			SortOrder:   i,
			Status:      "published",
		})

		sceneFiles := []string{}
		fs, _ := os.ReadDir(lessonDir)
		for _, f := range fs {
			if !f.IsDir() && strings.HasSuffix(f.Name(), ".json") && f.Name() != "index.json" {
				sceneFiles = append(sceneFiles, f.Name())
			}
		}
		sort.Strings(sceneFiles)

		var startSceneID string
		for _, sf := range sceneFiles {
			sj := readScene(filepath.Join(lessonDir, sf))
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

	fmt.Printf("seed 完成: course=%s lessons=%d\n", course.ID, len(dirs))
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
