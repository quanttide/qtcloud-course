/// 课时契约：与 qtclass-lite 的 `src/models/lesson.ts` 同形。
///
/// lite 是学员端渲染方，本文件是 Studio 侧的同一套形状——两边字段改动必须同步，
/// 否则右侧预览与学员看到的又会变成两套。
library;

/// 块类型，与 lite 的 `LessonBlock` 一一对应
sealed class LessonBlock {
  /// 块上方的小标签，如「做完你会看到」
  final String? label;

  const LessonBlock({this.label});
}

/// 「做完你会看到」：学员的预期结果，lines 逐行渲染
class NoteBlock extends LessonBlock {
  final List<String> lines;

  const NoteBlock({super.label, required this.lines});
}

/// 一键复制：学员原样粘贴的指令，不手打
class CopyBlock extends LessonBlock {
  final String text;

  const CopyBlock({super.label, required this.text});
}

/// 过程回显：等它跑完时屏幕上滚过的行
class CodeLine {
  final String text;
  final bool ok;

  const CodeLine(this.text, {this.ok = false});
}

class CodeBlock extends LessonBlock {
  final List<CodeLine> lines;

  const CodeBlock({super.label, required this.lines});
}

/// 产出链接：跑完拿到的地址
class LinkBlock extends LessonBlock {
  final String url;
  final String? tip;

  const LinkBlock({super.label, required this.url, this.tip});
}

/// 对照图：学员比对自己屏幕的截图
class ImageBlock extends LessonBlock {
  final String src;
  final String alt;
  final String? tip;

  const ImageBlock({super.label, required this.src, required this.alt, this.tip});
}

/// 一步 = 一个动作 + 若干展示块
class LessonStep {
  /// 步骤序号，按文档顺序从 1 起
  final int num;

  /// 步骤标题
  final String title;

  /// 学员要做的动作
  final String doText;

  final List<LessonBlock> blocks;

  const LessonStep({
    required this.num,
    required this.title,
    required this.doText,
    this.blocks = const [],
  });
}

class Lesson {
  /// 课时 slug，兼路径；缺省用文件名
  final String name;

  /// 所属课程名，与课堂页 courses.name 同源
  final String course;

  final String title;
  final String description;
  final String status;
  final String? kicker;
  final String? lede;
  final List<LessonStep> steps;

  /// 课末提示
  final String? tip;

  /// 页脚一句话
  final String? foot;

  const Lesson({
    this.name = '',
    this.course = '',
    required this.title,
    this.description = '',
    this.status = 'draft',
    this.kicker,
    this.lede,
    this.steps = const [],
    this.tip,
    this.foot,
  });
}
