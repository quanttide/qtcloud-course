package main

import (
	"log"
	"net/http"
	"os"

	"github.com/quanttide/qtcloud-course-provider/internal/handler"
	"github.com/quanttide/qtcloud-course-provider/internal/store"
)

func main() {
	programStore := store.NewProgramStore()
	courseStore := store.NewCourseStore()
	lessonStore := store.NewLessonStore()
	sceneStore := store.NewSceneStore()
	classStore := store.NewClassStore()

	ph := handler.NewProgramHandler(programStore)
	ch := handler.NewCourseHandler(courseStore)
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

	// Lesson
	mux.HandleFunc("GET /lessons", lh.List)
	mux.HandleFunc("POST /lessons", lh.Create)
	mux.HandleFunc("GET /lessons/{id}", lh.Get)
	mux.HandleFunc("PUT /lessons/{id}", lh.Update)
	mux.HandleFunc("DELETE /lessons/{id}", lh.Delete)

	// Scene（按 lessonId 查询）
	mux.HandleFunc("GET /scenes", sh.List)
	mux.HandleFunc("POST /scenes", sh.Create)
	mux.HandleFunc("GET /scenes/{id}", sh.Get)
	mux.HandleFunc("PUT /scenes/{id}", sh.Update)
	mux.HandleFunc("DELETE /scenes/{id}", sh.Delete)

	// Class
	mux.HandleFunc("GET /classes", clh.ListClasses)
	mux.HandleFunc("POST /classes", clh.CreateClass)
	mux.HandleFunc("GET /classes/{id}", clh.GetClass)
	mux.HandleFunc("PUT /classes/{id}", clh.UpdateClass)
	mux.HandleFunc("DELETE /classes/{id}", clh.DeleteClass)

	// Health
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})

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
