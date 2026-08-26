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
	programStore, courseStore, phaseStore, lessonStore, sceneStore, err := newStores(cfg)
	if err != nil {
		return nil, err
	}

	ph := handler.NewProgramHandler(programStore)
	ch := handler.NewCourseHandler(courseStore)
	pshH := handler.NewPhaseHandler(phaseStore, courseStore)
	lh := handler.NewLessonHandler(lessonStore)
	sh := handler.NewSceneHandler(sceneStore, lessonStore)
	mux := buildMux(cfg, ph, ch, pshH, lh, sh)

	player := handler.NewPlayerHandler(programStore, courseStore, phaseStore, lessonStore, sceneStore)
	mux.HandleFunc("GET /player-data", player.Get)
	catalog := handler.NewCatalogHandler(programStore, courseStore, phaseStore, lessonStore)
	registerPublicAPI(mux, catalog, player)
	return mux, nil
}

// newStores 按配置创建 5 个资源 store（program/course/phase/lesson/scene）。
// 内存分支各建独立实例；OSS 分支共享同一后端，各表独立对象（{table}.json）。
func newStores(cfg *config.Config) (handler.ProgramStorer, handler.CourseStorer, handler.PhaseStorer, handler.LessonStorer, handler.SceneStorer, error) {
	switch cfg.Store {
	case "oss":
		backend, err := store.NewOSS(store.OSSConfig{
			Endpoint:        cfg.OSSEndpoint,
			Bucket:          cfg.OSSBucket,
			AccessKeyID:     cfg.OSSAccessKeyID,
			AccessKeySecret: cfg.OSSAccessKeySecret,
		})
		if err != nil {
			return nil, nil, nil, nil, nil, fmt.Errorf("oss init: %w", err)
		}
		ps, err := store.NewOSSProgramStore(backend)
		if err != nil {
			return nil, nil, nil, nil, nil, err
		}
		cs, err := store.NewOSSCourseStore(backend)
		if err != nil {
			return nil, nil, nil, nil, nil, err
		}
		psh, err := store.NewOSSPhaseStore(backend)
		if err != nil {
			return nil, nil, nil, nil, nil, err
		}
		ls, err := store.NewOSSLessonStore(backend)
		if err != nil {
			return nil, nil, nil, nil, nil, err
		}
		ss, err := store.NewOSSSceneStore(backend)
		if err != nil {
			return nil, nil, nil, nil, nil, err
		}
		return ps, cs, psh, ls, ss, nil
	default: // memory（默认/测试）
		return store.NewProgramStore(), store.NewCourseStore(), store.NewPhaseStore(), store.NewLessonStore(), store.NewSceneStore(), nil
	}
}

// registerPublicAPI 学员端公开接口（/v1 前缀，与管理 CRUD 分离）。
func registerPublicAPI(mux *http.ServeMux, catalog *handler.CatalogHandler, player *handler.PlayerHandler) {
	mux.HandleFunc("GET /v1/courses", catalog.List)
	mux.HandleFunc("GET /v1/courses/{id}", catalog.Get)
	mux.HandleFunc("GET /v1/courses/{id}/player", player.GetByCourse)
}

// buildMux 组装路由（内存/OSS 共用）。
func buildMux(cfg *config.Config, ph *handler.ProgramHandler, ch *handler.CourseHandler, pshH *handler.PhaseHandler, lh *handler.LessonHandler, sh *handler.SceneHandler) *http.ServeMux {
	mux := http.NewServeMux()

	// Program
	mux.HandleFunc("GET /programs", ph.List)
	mux.HandleFunc("POST /programs", ph.Create)
	mux.HandleFunc("GET /programs/{id}", ph.Get)
	mux.HandleFunc("PUT /programs/{id}", ph.Update)
	mux.HandleFunc("DELETE /programs/{id}", ph.Delete)

	// Course
	mux.HandleFunc("GET /courses", ch.List)
	mux.HandleFunc("POST /courses", ch.Create)
	mux.HandleFunc("GET /courses/{id}", ch.Get)
	mux.HandleFunc("PUT /courses/{id}", ch.Update)
	mux.HandleFunc("DELETE /courses/{id}", ch.Delete)

	// Phase（嵌套路由 + 全局列表）
	mux.HandleFunc("GET /phases", pshH.List)
	mux.HandleFunc("GET /phases/{id}", pshH.Get)
	mux.HandleFunc("PUT /phases/{id}", pshH.Update)
	mux.HandleFunc("DELETE /phases/{id}", pshH.Delete)
	mux.HandleFunc("GET /courses/{courseId}/phases", pshH.ListByCourse)
	mux.HandleFunc("POST /courses/{courseId}/phases", pshH.CreateByCourse)
	mux.HandleFunc("DELETE /courses/{courseId}/phases/{id}", pshH.Delete)

	// Lesson
	mux.HandleFunc("GET /lessons", lh.List)
	mux.HandleFunc("POST /lessons", lh.Create)
	mux.HandleFunc("GET /lessons/{id}", lh.Get)
	mux.HandleFunc("PUT /lessons/{id}", lh.Update)
	mux.HandleFunc("DELETE /lessons/{id}", lh.Delete)

	// Scene（嵌套路由：场景作为课时的子资源）
	mux.HandleFunc("GET /scenes/{id}", sh.Get)
	mux.HandleFunc("PUT /scenes/{id}", sh.Update)
	mux.HandleFunc("DELETE /scenes/{id}", sh.Delete)
	mux.HandleFunc("GET /lessons/{lessonId}/scenes", sh.ListByLesson)
	mux.HandleFunc("POST /lessons/{lessonId}/scenes", sh.CreateByLesson)

	// Health
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})

	// 视频静态文件服务（本地磁盘路径）
	mux.Handle("GET /video/", http.StripPrefix("/video/", http.FileServer(http.Dir(cfg.VideoDir))))

	return mux
}
