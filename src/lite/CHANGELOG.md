# CHANGELOG

## [0.1.0-alpha.1] - 2026-11-21

### Added

- 课程清单首版：全部课程按通识 / 领域分级展示——通识课程·大一（AI创意、AI办公、AI编程、AI教学）在前，领域课程·大三（知识工作、大数据导论、数据工程、生产实习）在后，两段是先后关系
- 每门课标注上线状态（已上线 / 研发中）；已上线的挂学员端入口 `lite.class.quanttide.com`，研发中的不挂
- 课程数据从 qtclass-lite 迁入（原 `online: false` 的四门隐藏课在这本清单里现形）
- React + Vite + TypeScript 骨架照 qtclass-lite；`npm test` 5 例、`npm run lint`、`npm run build` 通过
