// Package config 提供集中化环境变量配置。
package config

import "os"

// Config 是服务端全部配置。
type Config struct {
	ListenAddr string // 监听地址，默认 ":8080"
	DataDir    string // 数据目录，默认 "./data"
	VideoDir   string // 视频文件目录，默认 "./data/video"
}

// Load 从环境变量加载配置，缺失时使用默认值。
func Load() *Config {
	return &Config{
		ListenAddr: getEnv("LISTEN_ADDR", ":8080"),
		DataDir:    getEnv("DATA_DIR", "./data"),
		VideoDir:   getEnv("VIDEO_DIR", "./data/video"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
