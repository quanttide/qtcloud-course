# ============================================================
# 课程清单 lite（lite.course.cloud.quanttide.com）
#
# 部署链路（.github/workflows/deploy-lite.yml）：
#   lite/* tag → Actions（npm ci + vite build + ossutil cp）→ 本桶（静态网站托管）
#   → 阿里云 CDN（lite.course.cloud.quanttide.com）→ 用户浏览器
#
# 说明：
#   - 桶私有，CDN 私有回源鉴权与根路径改写的说明见 cdn.tf（同一套）；
#     账号级 RAM 角色 AliyunCDNAccessingPrivateOSSRole 已存在，本仓不重复建。
#   - 证书：lite.course.cloud.quanttide.com 是三层子域，*.quanttide.com 泛域名
#     不覆盖，须 acme.sh 单域名证书；reloadcmd 为
#     ~/.acme.sh/deploy-cdn-cert-course-lite.sh（与 course-studio 同款）。
#   - 前置：quanttide.com 已完成 ICP 备案。
# ============================================================

resource "alicloud_oss_bucket" "lite" {
  bucket = var.oss_lite_bucket

  tags = {
    App         = "qtcloud-course-lite"
    Environment = var.environment
  }

  # 静态网站托管：index.html 为入口（Vite SPA，深链接回退首页）
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "alicloud_cdn_domain_new" "lite" {
  domain_name = "lite.course.cloud.quanttide.com"
  cdn_type    = "web"

  sources {
    content  = "${var.oss_lite_bucket}.${var.oss_endpoint}"
    type     = "oss"
    port     = 80
    priority = 20
  }
}

# 私有 Bucket 回源开关（l2_oss_key：private_oss_auth=on）
resource "alicloud_cdn_domain_config" "lite_private_back" {
  domain_name   = alicloud_cdn_domain_new.lite.domain_name
  function_name = "l2_oss_key"
  function_args {
    arg_name  = "private_oss_auth"
    arg_value = "on"
  }
}

# 根路径改写：私有回源与 OSS 网站托管默认首页重写的已知冲突（/ 回源 403）
resource "alicloud_cdn_domain_config" "lite_root_rewrite" {
  domain_name   = alicloud_cdn_domain_new.lite.domain_name
  function_name = "back_to_origin_url_rewrite"
  function_args {
    arg_name  = "source_url"
    arg_value = "^/$"
  }
  function_args {
    arg_name  = "target_url"
    arg_value = "/index.html"
  }
  function_args {
    arg_name  = "flag"
    arg_value = "break"
  }
}

# 强制 HTTPS（https_force）：证书绑定到 CDN 之后再加——域名没证书就开强制跳转会把站点打成死链。
# 首版先建桶与域名（见 CHANGELOG 0.1.0-alpha.2），证书绑定后补回本块。

# ── DNS：CNAME 接入 ─────────────────────────────────────────

resource "alicloud_alidns_record" "lite" {
  domain_name = "quanttide.com"
  rr          = "lite.course.cloud"
  type        = "CNAME"
  value       = alicloud_cdn_domain_new.lite.cname
  ttl         = 600
}
