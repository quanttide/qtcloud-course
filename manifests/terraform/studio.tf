# ============================================================
# Studio Web 静态站点桶（studio.course.cloud.quanttide.com）
#
# 部署链路（.github/workflows/deploy-studio.yml）：
#   studio/* tag → Actions（flutter build web + ossutil cp）→ 本桶（静态网站模式）
#   → 阿里云 CDN（studio.course.cloud.quanttide.com）→ 用户浏览器
#
# 桶保持私有（RAM 用户无权开放公共读），CDN 私有回源鉴权见 cdn.tf。
# ============================================================

resource "alicloud_oss_bucket" "studio" {
  bucket = var.oss_studio_bucket

  tags = {
    App         = "qtcloud-course-studio"
    Environment = var.environment
  }

  # 静态网站托管：index.html 为入口（Flutter Web SPA，深链接回退到首页）
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}
