// Package config 提供集中化环境变量配置。
package config

import "os"

// Config 是服务端全部配置。
type Config struct {
	ListenAddr string // 监听地址，默认 ":8080"
	DataDir    string // 数据目录，默认 "./data"
	VideoDir   string // 视频文件目录，默认 "./data/video"
	Store      string // 存储后端：oss | memory（默认 memory，测试/开发）
	// OSS 配置（Store=oss 时必填，QTCLOUD_OSS_* 前缀，对齐 qtcloud-crowd）
	OSSEndpoint        string // 如 oss-cn-hangzhou.aliyuncs.com
	OSSBucket          string // 课程数据桶
	OSSAccessKeyID     string
	OSSAccessKeySecret string
}

// Load 从环境变量加载配置，缺失时使用默认值。
func Load() *Config {
	return &Config{
		ListenAddr:         getEnv("LISTEN_ADDR", ":8080"),
		DataDir:            getEnv("DATA_DIR", "./data"),
		VideoDir:           getEnv("VIDEO_DIR", "./data/video"),
		Store:              getEnv("QTCLOUD_COURSE_STORE", "memory"),
		OSSEndpoint:        os.Getenv("QTCLOUD_OSS_ENDPOINT"),
		OSSBucket:          os.Getenv("QTCLOUD_OSS_BUCKET"),
		OSSAccessKeyID:     os.Getenv("QTCLOUD_OSS_ACCESS_KEY_ID"),
		OSSAccessKeySecret: os.Getenv("QTCLOUD_OSS_ACCESS_KEY_SECRET"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
