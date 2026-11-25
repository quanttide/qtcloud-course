# CHANGELOG

## [Unreleased]

### Changed

- AI教学改研发中：课时已从学员端下线，计划上线到本清单（`lite.course.cloud.quanttide.com`）——卡片撤掉「去上课」入口，通识注释改「三门在学员端，AI教学研发中」
- 测试：已上线 3 / 研发中 5，补 AI教学卡无入口断言


## [0.1.0-alpha.3] - 2026-11-21

### Added

- 强制 HTTPS：证书已绑定 CDN（acme.sh 单域名，reloadcmd `~/.acme.sh/deploy-cdn-cert-course-lite.sh`），`https_force` 随本次 apply 打开，HTTP 301 到 HTTPS

## [0.1.0-alpha.2] - 2026-11-21

### Added

- 部署链路：`lite/*` tag → `.github/workflows/deploy-lite.yml`（Terraform 建站点桶 / CDN / DNS → npm ci + vite build → 分段上传 OSS → 刷 CDN），域名 `lite.course.cloud.quanttide.com`；证书为 acme.sh 单域名，reloadcmd `~/.acme.sh/deploy-cdn-cert-course-lite.sh`

## [0.1.0-alpha.1] - 2026-11-21

### Added

- 课程清单首版：全部课程按通识 / 领域分级展示——通识课程·大一（AI创意、AI办公、AI编程、AI教学）在前，领域课程·大三（知识工作、大数据导论、数据工程、生产实习）在后，两段是先后关系
- 每门课标注上线状态（已上线 / 研发中）；已上线的挂学员端入口 `lite.class.quanttide.com`，研发中的不挂
- 课程数据从 qtclass-lite 迁入（原 `online: false` 的四门隐藏课在这本清单里现形）
- React + Vite + TypeScript 骨架照 qtclass-lite；`npm test` 5 例、`npm run lint`、`npm run build` 通过
