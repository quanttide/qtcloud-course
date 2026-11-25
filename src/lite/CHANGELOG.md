# CHANGELOG

## [0.1.0-beta.1] - 2026-11-25

### Added

- 课程卡新增「预览课件 →」：有课件的四门（AI创意 / AI办公 / AI编程 / 职业发展）点开即看课件正文，**研发中的课也能被看见**——清单成为课程的第一上架地
- `scripts/sync-material.sh`：构建前从 profile 仓把课件搬进 `src/lite/public/preview/`（单一事实源在 profile，只搬 `material` 指向的目录，仓内 md 不上站）；CI 加同步步骤，preview 文件单独 no-cache 上传（固定名、内容会变）
- 课程分级记全四段：通识(大一) → 学科(大二) → 领域(大三) → 职业(大四)，段与段是先后关系；`data/profile/AGENTS.md` 同步一张分级表
- 大二「学科」段先占位（无课，注记"学科基础课，还在建设"）
- 大四新增「职业发展」课程卡（研发中，内容为 WorkBuddy 职业探索访谈入门）

### Changed

- 大四级由「职业发展」改称「职业」段，与前三段命名齐平；生产实习从「领域 · 大三」移入「职业 · 大四」——职业发展是前置（论文写作教学），生产实习是毕业论文
- 页首改为四段说明；测试覆盖四段标题、年级对应、领域三门、职业两门

## [0.1.0-alpha.4] - 2026-11-25

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
