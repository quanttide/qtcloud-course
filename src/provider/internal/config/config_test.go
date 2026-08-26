package config

import (
	"os"
	"testing"
)

func TestLoad_Defaults(t *testing.T) {
	cfg := Load()
	if cfg.ListenAddr != ":8080" {
		t.Fatalf("ListenAddr = %q, want %q", cfg.ListenAddr, ":8080")
	}
	if cfg.DataDir != "./data" {
		t.Fatalf("DataDir = %q, want %q", cfg.DataDir, "./data")
	}
	if cfg.VideoDir != "./data/video" {
		t.Fatalf("VideoDir = %q, want %q", cfg.VideoDir, "./data/video")
	}
	if cfg.Store != "memory" {
		t.Fatalf("Store = %q, want %q (默认 memory)", cfg.Store, "memory")
	}
}

func TestLoad_EnvOverride(t *testing.T) {
	os.Setenv("LISTEN_ADDR", ":9999")
	os.Setenv("DATA_DIR", "/tmp/data")
	os.Setenv("VIDEO_DIR", "/tmp/video")
	os.Setenv("QTCLOUD_COURSE_STORE", "oss")
	os.Setenv("QTCLOUD_OSS_ENDPOINT", "oss-cn-hangzhou.aliyuncs.com")
	os.Setenv("QTCLOUD_OSS_BUCKET", "qtcloud-course")
	os.Setenv("QTCLOUD_OSS_ACCESS_KEY_ID", "AKID")
	os.Setenv("QTCLOUD_OSS_ACCESS_KEY_SECRET", "SECRET")
	defer func() {
		os.Unsetenv("LISTEN_ADDR")
		os.Unsetenv("DATA_DIR")
		os.Unsetenv("VIDEO_DIR")
		os.Unsetenv("QTCLOUD_COURSE_STORE")
		os.Unsetenv("QTCLOUD_OSS_ENDPOINT")
		os.Unsetenv("QTCLOUD_OSS_BUCKET")
		os.Unsetenv("QTCLOUD_OSS_ACCESS_KEY_ID")
		os.Unsetenv("QTCLOUD_OSS_ACCESS_KEY_SECRET")
	}()

	cfg := Load()
	if cfg.ListenAddr != ":9999" {
		t.Fatalf("ListenAddr = %q", cfg.ListenAddr)
	}
	if cfg.DataDir != "/tmp/data" {
		t.Fatalf("DataDir = %q", cfg.DataDir)
	}
	if cfg.VideoDir != "/tmp/video" {
		t.Fatalf("VideoDir = %q", cfg.VideoDir)
	}
	if cfg.Store != "oss" {
		t.Fatalf("Store = %q, want oss", cfg.Store)
	}
	if cfg.OSSEndpoint != "oss-cn-hangzhou.aliyuncs.com" {
		t.Fatalf("OSSEndpoint = %q", cfg.OSSEndpoint)
	}
	if cfg.OSSBucket != "qtcloud-course" {
		t.Fatalf("OSSBucket = %q", cfg.OSSBucket)
	}
	if cfg.OSSAccessKeyID != "AKID" || cfg.OSSAccessKeySecret != "SECRET" {
		t.Fatalf("OSS credentials = %q/%q", cfg.OSSAccessKeyID, cfg.OSSAccessKeySecret)
	}
}
