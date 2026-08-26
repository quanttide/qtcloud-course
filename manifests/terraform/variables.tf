variable "region" {
  description = "阿里云地域"
  type        = string
  default     = "cn-hangzhou"
}

variable "project" {
  description = "项目名（资源命名前缀）"
  type        = string
  default     = "qtcloud-course"
}

variable "environment" {
  description = "环境：dev / prod"
  type        = string
  default     = "prod"
}

variable "image" {
  description = "FC 容器镜像（ACR 地址）。由 CI 注入"
  type        = string
}

variable "oss_data_bucket" {
  description = "provider 运行时课程数据 OSS 桶（私有，QTCLOUD_OSS_BUCKET；programs.json 等 5 个对象）"
  type        = string
  default     = "qtcloud-course-provider"
}

variable "oss_endpoint" {
  description = "阿里云 OSS Endpoint（provider 运行时 QTCLOUD_OSS_ENDPOINT）"
  type        = string
  default     = "oss-cn-hangzhou.aliyuncs.com"
}

variable "oss_access_key_id" {
  description = "provider 运行时访问 OSS 的 AccessKey ID（FC 环境变量 QTCLOUD_OSS_ACCESS_KEY_ID；会明文落入 tfstate，生产建议后续改用 FC 密钥管理注入）"
  type        = string
  sensitive   = true
}

variable "oss_access_key_secret" {
  description = "provider 运行时访问 OSS 的 AccessKey Secret（FC 环境变量 QTCLOUD_OSS_ACCESS_KEY_SECRET；会明文落入 tfstate，生产建议后续改用 FC 密钥管理注入）"
  type        = string
  sensitive   = true
}

variable "fc_memory" {
  description = "FC 函数内存（MB）"
  type        = number
  default     = 512
}

variable "fc_timeout" {
  description = "FC 函数超时（秒）"
  type        = number
  default     = 60
}
