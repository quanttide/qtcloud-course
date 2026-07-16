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
}

func TestLoad_EnvOverride(t *testing.T) {
	os.Setenv("LISTEN_ADDR", ":9999")
	os.Setenv("DATA_DIR", "/tmp/data")
	os.Setenv("VIDEO_DIR", "/tmp/video")
	defer func() {
		os.Unsetenv("LISTEN_ADDR")
		os.Unsetenv("DATA_DIR")
		os.Unsetenv("VIDEO_DIR")
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
}
