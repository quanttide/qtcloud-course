package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/config"
	"github.com/quanttide/qtcloud-course-provider/internal/handler"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

func main() {
	cfg := config.Load()
	mux, err := newRouter(cfg)
	if err != nil {
		log.Fatalf("router init: %v", err)
	}
	log.Printf("qtcloud-course-provider starting on %s (store=%s)", cfg.ListenAddr, cfg.Store)
	if err := http.ListenAndServe(cfg.ListenAddr, mux); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

// newRouter 创建并配置所有路由，可单独测试。
// 持久化：QTCLOUD_COURSE_STORE=oss 时启用对象存储（生产 FC 可读写、容器回收数据仍在），
// 否则内存（默认/测试）。
func newRouter(cfg *config.Config) (*http.ServeMux, error) {
	courseStore, lessonStore, sceneStore, criterionStore, err := newStores(cfg)
	if err != nil {
		return nil, err
	}

	ch := handler.NewCourseHandler(courseStore)      // 写操作
	crh := handler.NewCourseReadHandler(courseStore) // 读入口（内容实体）
	lh := handler.NewLessonHandler(lessonStore, courseStore)
	sh := handler.NewSceneHandler(sceneStore, lessonStore)
	crith := handler.NewCriterionHandler(criterionStore, lessonStore, sceneStore)
	mux := buildMux(ch, crh, lh, sh, crith)
	return mux, nil
}

// newStores 按配置创建 4 个资源 store（course/lesson/scene/criterion）。
// 内存分支各建独立实例；OSS 分支共享同一后端，各表独立对象（{table}.json）。
func newStores(cfg *config.Config) (handler.CourseStorer, handler.LessonStorer, handler.SceneStorer, handler.CriterionStorer, error) {
	switch cfg.Store {
	case "oss":
		backend, err := store.NewOSS(store.OSSConfig{
			Endpoint:        cfg.OSSEndpoint,
			Bucket:          cfg.OSSBucket,
			AccessKeyID:     cfg.OSSAccessKeyID,
			AccessKeySecret: cfg.OSSAccessKeySecret,
		})
		if err != nil {
			return nil, nil, nil, nil, fmt.Errorf("oss init: %w", err)
		}
		cs, err := store.NewOSSCourseStore(backend)
		if err != nil {
			return nil, nil, nil, nil, err
		}
		ls, err := store.NewOSSLessonStore(backend)
		if err != nil {
			return nil, nil, nil, nil, err
		}
		ss, err := store.NewOSSSceneStore(backend)
		if err != nil {
			return nil, nil, nil, nil, err
		}
		cris, err := store.NewOSSCriterionStore(backend)
		if err != nil {
			return nil, nil, nil, nil, err
		}
		return cs, ls, ss, cris, nil
	default: // memory（默认/测试）
		return store.NewCourseStore(), store.NewLessonStore(), store.NewSceneStore(), store.NewCriterionStore(), nil
	}
}

// buildMux 组装路由（内存/OSS 共用）。
// 单一路由面：一套资源接口承担内容编辑与学员交付；服务端只出内容实体，
// 展示层组装（目录卡片、播放器 segments 等）属应用侧职责（见 qtclass src/provider）。
// 课程树三级结构：Course → Lesson → Scene，Criterion 作为课时/场景的子资源管理。
func buildMux(ch *handler.CourseHandler, crh *handler.CourseReadHandler, lh *handler.LessonHandler, sh *handler.SceneHandler, crith *handler.CriterionHandler) *http.ServeMux {
	mux := http.NewServeMux()

	// Course
	mux.HandleFunc("GET /courses", crh.List)
	mux.HandleFunc("GET /courses/{id}", crh.Get)
	mux.HandleFunc("POST /courses", ch.Create)
	mux.HandleFunc("PUT /courses/{id}", ch.Update)
	mux.HandleFunc("DELETE /courses/{id}", ch.Delete)

	// Lesson（全局 + 课程子路由；SortOrder 保证课时顺序）
	mux.HandleFunc("GET /lessons", lh.List)
	mux.HandleFunc("POST /lessons", lh.Create)
	mux.HandleFunc("GET /lessons/{id}", lh.Get)
	mux.HandleFunc("PUT /lessons/{id}", lh.Update)
	mux.HandleFunc("DELETE /lessons/{id}", lh.Delete)
	mux.HandleFunc("GET /courses/{courseId}/lessons", lh.ListByCourse)
	mux.HandleFunc("POST /courses/{courseId}/lessons", lh.CreateByCourse)

	// Scene（嵌套路由：场景作为课时的子资源）
	mux.HandleFunc("GET /scenes/{id}", sh.Get)
	mux.HandleFunc("PUT /scenes/{id}", sh.Update)
	mux.HandleFunc("DELETE /scenes/{id}", sh.Delete)
	mux.HandleFunc("GET /lessons/{lessonId}/scenes", sh.ListByLesson)
	mux.HandleFunc("POST /lessons/{lessonId}/scenes", sh.CreateByLesson)

	// Criterion（验收标准：课时级与场景级子路由 + 全局清单）
	mux.HandleFunc("GET /criteria", crith.ListAll)
	mux.HandleFunc("GET /criteria/{id}", crith.Get)
	mux.HandleFunc("PUT /criteria/{id}", crith.Update)
	mux.HandleFunc("DELETE /criteria/{id}", crith.Delete)
	mux.HandleFunc("GET /lessons/{lessonId}/criteria", crith.ListByLesson)
	mux.HandleFunc("POST /lessons/{lessonId}/criteria", crith.CreateByLesson)
	mux.HandleFunc("GET /scenes/{sceneId}/criteria", crith.ListByScene)
	mux.HandleFunc("POST /scenes/{sceneId}/criteria", crith.CreateByScene)

	// Health
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})

	return mux
}
