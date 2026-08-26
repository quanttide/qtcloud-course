# ============================================================
# provider 运行时 OSS 桶：课程数据桶（私有）
# 持久化方案：每表一个对象（programs.json / courses.json / phases.json /
# lessons.json / scenes.json）——FC 容器可读写对象存储、容器回收数据仍在
# （解决 FC 无持久化问题，替代 SQLite 本地文件）。
# ============================================================

# ── 课程数据桶（私有，默认 ACL 即私有）──
resource "alicloud_oss_bucket" "data" {
  bucket = var.oss_data_bucket

  tags = {
    App         = "qtcloud-course-data"
    Environment = var.environment
  }
}
