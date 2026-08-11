package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/domain"

	_ "modernc.org/sqlite"

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
	log.Printf("qtcloud-course-provider starting on %s (db=%s)", cfg.ListenAddr, cfg.DBPath)
	if err := http.ListenAndServe(cfg.ListenAddr, mux); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

// newRouter 创建并配置所有路由，可单独测试。
// 持久化：DB_PATH 非空时启用 SQLite（生产），否则内存（默认/测试）。
func newRouter(cfg *config.Config) (*http.ServeMux, error) {
	var (
		programStore *store.SQLiteStore[domain.Program]
		courseStore  *store.SQLiteStore[domain.Course]
		phaseStore   *store.SQLiteStore[domain.Phase]
		lessonStore  *store.SQLiteStore[domain.Lesson]
		sceneStore   *store.SQLiteStore[domain.Scene]
		db           *sql.DB
		err          error
	)
	if cfg.DBPath != "" {
		db, err = sql.Open("sqlite", cfg.DBPath)
		if err != nil {
			return nil, fmt.Errorf("open sqlite %s: %w", cfg.DBPath, err)
		}
		if programStore, err = store.NewSQLiteProgramStore(db); err != nil {
			return nil, err
		}
		if courseStore, err = store.NewSQLiteCourseStore(db); err != nil {
			return nil, err
		}
		if phaseStore, err = store.NewSQLitePhaseStore(db); err != nil {
			return nil, err
		}
		if lessonStore, err = store.NewSQLiteLessonStore(db); err != nil {
			return nil, err
		}
		if sceneStore, err = store.NewSQLiteSceneStore(db); err != nil {
			return nil, err
		}
	} else {
		ps := store.NewProgramStore()
		cs := store.NewCourseStore()
		psh := store.NewPhaseStore()
		ls := store.NewLessonStore()
		ss := store.NewSceneStore()
		ph := handler.NewProgramHandler(ps)
		ch := handler.NewCourseHandler(cs)
		pshH := handler.NewPhaseHandler(psh, cs)
		lh := handler.NewLessonHandler(ls)
		sh := handler.NewSceneHandler(ss, ls)
		return buildMux(cfg, ph, ch, pshH, lh, sh), nil
	}

	ph := handler.NewProgramHandler(programStore)
	ch := handler.NewCourseHandler(courseStore)
	pshH := handler.NewPhaseHandler(phaseStore, courseStore)
	lh := handler.NewLessonHandler(lessonStore)
	sh := handler.NewSceneHandler(sceneStore, lessonStore)
	return buildMux(cfg, ph, ch, pshH, lh, sh), nil
}

// buildMux 组装路由（内存/SQLite 共用）。
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
