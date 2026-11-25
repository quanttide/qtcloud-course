/**
 * 课程清单：这里是正在研发的那本清单。
 *
 * 通识课程（AI 开头）先行、领域课程在后，两者是先后关系——
 * 大致对应大一与大三。学员端只放已上线的课，其余留在这本清单里标状态。
 */

export type Track = '通识' | '学科' | '领域' | '职业'

export interface Course {
  name: string
  track: Track
  /** 课程阶梯：入门 / 进阶 / 高阶 / 实训 */
  level: string
  audience: string
  summary: string
  modules: string[]
  /** 是否已在学员端上线 */
  online: boolean
  /** 已上线课程的入口 */
  url?: string
  /** 课件预览：data/profile 下的相对路径，构建时由 scripts/sync-material.sh 搬进 public/courses */
  material?: string
}

/** 学员端入口：已上线课程都从这里进 */
export const LITE_URL = 'https://lite.class.quanttide.com/'

/**
 * 课件路径：material 是 profile 仓里的相对路径，站内按 courses/<目录>/lessons/<课时> 落位。
 * 嵌套课时（如 vibe-coding/phase1-intro/lesson1-hello-world/x.html）取课时目录名，
 * 平铺课件（如 vibe-working/hello-world.html）取文件名——与 scripts/sync-material.sh 同一套规则。
 */
export function materialHref(material: string): string {
  const parts = material.split('/')
  const dir = parts[0]
  const lesson =
    parts.length > 2 ? parts[parts.length - 2] : parts[parts.length - 1].replace(/\.html$/, '')
  return `courses/${dir}/lessons/${lesson}.html`
}

/** 分级：通识在前、领域在后 */
// 四段课程轴，先后关系：通识(大一) → 学科(大二) → 领域(大三) → 职业(大四)
export const tracks: { track: Track; stage: string; note: string }[] = [
  { track: '通识', stage: '大一', note: '先把 AI 当成顺手的工具：三门在学员端，AI教学研发中。' },
  { track: '学科', stage: '大二', note: '学科基础课，还在建设。' },
  { track: '领域', stage: '大三', note: '对齐具体领域的课程，还在研发，上线一门搬一门。' },
  { track: '职业', stage: '大四', note: '接轨社会的两级：职业发展是前置，生产实习是毕业论文。' },
]

export const courses: Course[] = [
  {
    name: 'AI创意',
    track: '通识',
    level: '入门',
    audience: '想把一段文字画出来、第一次用 AI 生图的成员',
    summary:
      '四步把一段小说变成一张图：先让 AI 教你读懂原文，再让它写提示词、生成图片，最后教你怎么写——提示词不用记。',
    modules: ['读懂原文', '替你写提示词', '生成图片', '教你写'],
    online: true,
    url: LITE_URL,
    material: 'vibe-creating/hello-world.html',
  },
  {
    name: 'AI办公',
    track: '通识',
    level: '入门',
    audience: '想让 AI 替自己跑公开网站、拿现状报告的成员',
    summary:
      '当一回总裁：发一句话让 AI 去公开网站采集部门现状，交一份能逐条核对的报告——查不到的它得老实写查不到，不许编。',
    modules: ['一句话指令', 'AI 采集', '现状报告', '验收核对'],
    online: true,
    url: LITE_URL,
    material: 'vibe-working/hello-world.html',
  },
  {
    name: 'AI编程',
    track: '通识',
    level: '入门',
    audience: '想用 AI 把想法做成作品、不用写代码的成员',
    summary:
      '同一个游戏做四遍：做出来、改起来、创出来、推出去。每一步只用一句话指挥 AI，做出能发给朋友玩的上线作品。',
    modules: ['照着做', '换个壳', '自己设计', '拿出去'],
    online: true,
    url: LITE_URL,
    material: 'vibe-coding/phase1-intro/lesson1-hello-world/lesson-1-plan.html',
  },
  {
    name: 'AI教学',
    track: '通识',
    level: '入门',
    audience: '会做一件事、有人想学，但没学过教学法的成员',
    summary:
      '不用教龄不用证书：挑一件你熟的事，拆成几步，每步写清「做完你会看到」，生成自己的课程闯关图——做一遍就做出来了。',
    modules: ['想一件事', '拆成几步', '做完你会看到', '生成课程图'],
    online: false,
  },
  {
    name: '知识工作',
    track: '领域',
    level: '入门',
    audience: '新同学、实习生、业务协作成员',
    summary: '建立文档、信息收集、结构化表达和复盘的基本工作习惯。',
    modules: ['文档即资产', '信息收集与整理', '知识输出'],
    online: false,
  },
  {
    name: '大数据导论',
    track: '领域',
    level: '进阶',
    audience: '数据岗位入门、业务分析协作成员',
    summary: '理解数据采集、治理、分析和应用的基本链路。',
    modules: ['数据资产', '分析流程', '业务指标'],
    online: false,
  },
  {
    name: '数据工程',
    track: '领域',
    level: '高阶',
    audience: '数据工程、平台建设和交付实施成员',
    summary: '面向真实项目的数据建模、管道、质量和交付规范。',
    modules: ['数据建模', '工程管道', '质量与运维'],
    online: false,
  },
  {
    name: '职业发展',
    track: '职业',
    level: '入门',
    audience: '即将接轨社会、想让对的搭档找到自己的成员',
    summary:
      '打开 WorkBuddy 答一次职业探索访谈，10 分钟拿到协作名片与简介短签，挂进飞书简介和公共索引——先被找到，再去做交付。',
    modules: ['职业探索访谈', '协作名片', '简介短签', '挂进公共索引'],
    online: false,
    material: 'career-development/hello-world.html',
  },
  {
    name: '生产实习',
    track: '职业',
    level: '实训',
    audience: '公司内部培训、实训基地学员',
    summary: '以微型创业和真实交付为牵引，完成学习、Demo、进度和立项闭环。',
    modules: ['理解业务', '识别机会', '验证 Demo', '提交立项'],
    online: false,
  },
]
