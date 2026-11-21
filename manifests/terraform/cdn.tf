# ============================================================
# Studio CDN + DNS（studio.course.cloud.quanttide.com）
#
# 链路：OSS 静态站点桶（studio.tf，私有）→ CDN 加速 + 私有回源鉴权
#   → CNAME 接入（云解析）→ 用户浏览器
#
# 说明：
#   - 私有回源两步：① 账号级 RAM 角色 AliyunCDNAccessingPrivateOSSRole
#     账号内唯一，已由 qtcloud-media 的 studio 首次部署创建，本仓不重复建；
#     ② 域名级开关：本文件的 l2_oss_key（private_oss_auth=on，STS 同账号回源）。
#   - 根路径改写：私有回源（签名请求）与 OSS 静态网站托管默认首页重写存在已知冲突
#     （/ 回源 403），改为 CDN 侧直接回源 /index.html。
#   - HTTPS：studio.course.cloud.quanttide.com 是三层子域，*.quanttide.com 泛域名
#     证书不匹配，须用 acme.sh 单域名证书（90 天自动续期）。证书就位前不强制 HTTPS
#     （https_force 会把没证书的域名打成死链），备好证书后再加该配置。
#   - 前置：quanttide.com 已完成 ICP 备案。
# ============================================================

resource "alicloud_cdn_domain_new" "studio" {
  domain_name = "studio.course.cloud.quanttide.com"
  cdn_type    = "web"

  # 源站：OSS 静态网站桶（私有，回源鉴权见上方说明）
  sources {
    content  = "${var.oss_studio_bucket}.${var.oss_endpoint}"
    type     = "oss"
    port     = 80
    priority = 20
  }
}

# 私有 Bucket 回源开关（l2_oss_key：private_oss_auth=on）
# 注意：与 OSS 静态网站托管默认首页存在已知冲突，回源 403 时按下方根路径改写处理。
resource "alicloud_cdn_domain_config" "studio_private_back" {
  domain_name   = alicloud_cdn_domain_new.studio.domain_name
  function_name = "l2_oss_key"
  function_args {
    arg_name  = "private_oss_auth"
    arg_value = "on"
  }
}

resource "alicloud_cdn_domain_config" "studio_root_rewrite" {
  domain_name   = alicloud_cdn_domain_new.studio.domain_name
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

# ── DNS：CNAME 接入 ─────────────────────────────────────────

resource "alicloud_alidns_record" "studio" {
  domain_name = "quanttide.com"
  rr          = "studio.course.cloud"
  type        = "CNAME"
  value       = alicloud_cdn_domain_new.studio.cname
  ttl         = 600
}
