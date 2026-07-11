package main

import (
	"log"
	"net/http"
	"os"

	"github.com/quanttide/qtcloud-course-provider/internal/handler"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

func main() {
	// 初始化存储层
	programStore := store.NewProgramStore()
	classStore := store.NewClassStore()

	// 初始化处理器
	ph := handler.NewProgramHandler(programStore)
	ch := handler.NewClassHandler(classStore)

	// 注册路由（Go 1.22+ 增强 ServeMux）
	mux := http.NewServeMux()

	// Program 路由
	mux.HandleFunc("GET /programs", ph.ListPrograms)
	mux.HandleFunc("POST /programs", ph.CreateProgram)
	mux.HandleFunc("GET /programs/{id}", ph.GetProgram)
	mux.HandleFunc("PUT /programs/{id}", ph.UpdateProgram)
	mux.HandleFunc("DELETE /programs/{id}", ph.DeleteProgram)

	// Course 路由（嵌套在 Program 下）
	mux.HandleFunc("GET /programs/{id}/courses", ph.ListCourses)
	mux.HandleFunc("POST /programs/{id}/courses", ph.CreateCourse)
	mux.HandleFunc("GET /programs/{id}/courses/{courseId}", ph.GetCourse)
	mux.HandleFunc("PUT /programs/{id}/courses/{courseId}", ph.UpdateCourse)
	mux.HandleFunc("DELETE /programs/{id}/courses/{courseId}", ph.DeleteCourse)

	// Lesson 路由（嵌套在 Course 下）
	mux.HandleFunc("GET /programs/{id}/courses/{courseId}/lessons", ph.ListLessons)
	mux.HandleFunc("POST /programs/{id}/courses/{courseId}/lessons", ph.CreateLesson)
	mux.HandleFunc("GET /programs/{id}/courses/{courseId}/lessons/{lessonId}", ph.GetLesson)
	mux.HandleFunc("PUT /programs/{id}/courses/{courseId}/lessons/{lessonId}", ph.UpdateLesson)
	mux.HandleFunc("DELETE /programs/{id}/courses/{courseId}/lessons/{lessonId}", ph.DeleteLesson)

	// Class 路由
	mux.HandleFunc("GET /classes", ch.ListClasses)
	mux.HandleFunc("POST /classes", ch.CreateClass)
	mux.HandleFunc("GET /classes/{id}", ch.GetClass)
	mux.HandleFunc("PUT /classes/{id}", ch.UpdateClass)
	mux.HandleFunc("DELETE /classes/{id}", ch.DeleteClass)

	// 健康检查
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})

	// 启动服务
	addr := getEnv("LISTEN_ADDR", ":8080")
	log.Printf("qtcloud-course-provider starting on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
