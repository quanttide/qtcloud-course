# ============================================================
# provider（qtcloud-course 课程内容 API）—— 阿里云 FC 3.0 容器部署
# 数据：运行时 OSS store（QTCLOUD_COURSE_STORE=oss）：
#   - 课程数据桶（QTCLOUD_OSS_BUCKET）：programs.json / courses.json /
#     phases.json / lessons.json / scenes.json（每表一个对象，全量实体列表）
# 凭证：provider 通过环境变量读取静态 AK/SK 访问 OSS（见 src/provider/internal/store/oss.go
#       与 cmd/server/main.go——QTCLOUD_OSS_* 前缀，对齐 qtcloud-crowd）；
#       故 FC 函数环境变量注入 QTCLOUD_OSS_ACCESS_KEY_ID/SECRET。
#       此 AK/SK 会明文落入 tfstate，生产环境建议后续改用 FC 密钥管理/配置中心注入。
# ============================================================

# FC 默认角色：允许 FC 服务挂载弹性网卡访问 VPC（应用级）
resource "alicloud_ram_role" "fc" {
  role_name = "${local.app_name_prefix}-fc"
  assume_role_policy_document = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = ["fc.aliyuncs.com"] }
    }]
    Version = "1"
  })
  description = "Function Compute 默认角色（qtcloud-course）"
}

resource "alicloud_ram_role_policy_attachment" "fc_vpc" {
  policy_name = "AliyunECSNetworkInterfaceManagementAccess"
  policy_type = "System"
  role_name   = alicloud_ram_role.fc.role_name
}

# 函数计算（FC 3.0）：custom-container 容器镜像，内置 vibe-coding 课程数据
resource "alicloud_fcv3_function" "this" {
  function_name   = local.app_name_prefix
  description     = "qtcloud-course 课程内容 API（内置 vibe-coding 数据，OSS 持久化）"
  runtime         = "custom-container"
  handler         = "index.handler"
  cpu             = 0.5
  memory_size     = var.fc_memory
  disk_size       = 512
  timeout         = var.fc_timeout
  internet_access = true
  role            = alicloud_ram_role.fc.arn

  custom_container_config {
    image = var.image
    port  = 8080
  }

  # 对齐 provider 运行时约定（见 src/provider/cmd/server/main.go 与 internal/store/oss.go）：
  # QTCLOUD_COURSE_STORE=oss 走对象存储（生产 FC 可读写、容器回收数据仍在）；
  # 容器启动时先 seed（幂等）写入 OSS 再起服务（见 src/provider/Dockerfile）
  environment_variables = {
    QTCLOUD_COURSE_STORE          = "oss"
    QTCLOUD_OSS_BUCKET            = alicloud_oss_bucket.data.bucket
    QTCLOUD_OSS_ENDPOINT          = var.oss_endpoint
    QTCLOUD_OSS_ACCESS_KEY_ID     = var.oss_access_key_id
    QTCLOUD_OSS_ACCESS_KEY_SECRET = var.oss_access_key_secret
  }

  tags = {
    project     = var.project
    environment = var.environment
  }
}

# HTTP 触发器：直接访问（后续经 API 网关统一接入）
resource "alicloud_fcv3_trigger" "http" {
  function_name = alicloud_fcv3_function.this.function_name
  trigger_name  = "http"
  trigger_type  = "http"
  qualifier     = "LATEST"
  trigger_config = jsonencode({
    authType = "anonymous"
    methods  = ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"]
  })
}
