package main

import (
	"log"
	"net/http"

	"github.com/quanttide/qtcloud-course-provider/internal/config"
	"github.com/quanttide/qtcloud-course-provider/internal/handler"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

func main() {
	cfg := config.Load()
	mux := newRouter(cfg)
	log.Printf("qtcloud-course-provider starting on %s", cfg.ListenAddr)
	if err := http.ListenAndServe(cfg.ListenAddr, mux); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

// newRouter 创建并配置所有路由，可单独测试。
func newRouter(cfg *config.Config) *http.ServeMux {
	programStore := store.NewProgramStore()
	courseStore := store.NewCourseStore()
	lessonStore := store.NewLessonStore()
	sceneStore := store.NewSceneStore()
	phaseStore := store.NewPhaseStore()
	classStore := store.NewClassStore()

	ph := handler.NewProgramHandler(programStore)
	ch := handler.NewCourseHandler(courseStore)
	psh := handler.NewPhaseHandler(phaseStore, courseStore)
	lh := handler.NewLessonHandler(lessonStore)
	sh := handler.NewSceneHandler(sceneStore, lessonStore)
	clh := handler.NewClassHandler(classStore)

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
	mux.HandleFunc("GET /phases", psh.List)
	mux.HandleFunc("GET /phases/{id}", psh.Get)
	mux.HandleFunc("PUT /phases/{id}", psh.Update)
	mux.HandleFunc("DELETE /phases/{id}", psh.Delete)
	mux.HandleFunc("GET /courses/{courseId}/phases", psh.ListByCourse)
	mux.HandleFunc("POST /courses/{courseId}/phases", psh.CreateByCourse)
	mux.HandleFunc("DELETE /courses/{courseId}/phases/{id}", psh.Delete)

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

	// Class
	mux.HandleFunc("GET /classes", clh.List)
	mux.HandleFunc("POST /classes", clh.Create)
	mux.HandleFunc("GET /classes/{id}", clh.Get)
	mux.HandleFunc("PUT /classes/{id}", clh.Update)
	mux.HandleFunc("DELETE /classes/{id}", clh.Delete)

	// Health
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})

	// 视频静态文件服务（本地磁盘路径）
	mux.Handle("GET /video/", http.StripPrefix("/video/", http.FileServer(http.Dir(cfg.VideoDir))))

	return mux
}
