/// 课时 Markdown → [Lesson] 解析器。规则只此一份：Studio 预览按它渲染，
/// 学员端（qtclass-lite）按同一份 Lesson 形状渲染，两边不许各写一套。
///
/// 约定：
/// ```md
/// # 课时标题            → title（只认第一个）
/// lede 段落             → lede（H1 之后、第一个 ## 之前）
///
/// ## 步骤标题           → 新步骤，num 按顺序从 1 起
/// 动作段落               → 该步骤的 do（多段以空格相连）
///
/// ```copy 标签          → 一键复制块，正文原样作 text（保留换行）
/// ```note 标签          → 预期结果块，正文逐行作 lines
/// ```code 标签          → 回显块，正文逐行，以 ✓ 开头的行记为完成态
/// ```link 标签          → 链接块，正文第一行是 url、其余是 tip
/// ```image 标签         → 对照图块，正文第一行 src、第二行 alt、其余是 tip
/// ```tip                → 课末提示（lesson.tip）
/// ```foot               → 页脚一句话（lesson.foot）
/// ```
///
/// 围栏外只按段落处理；步骤块必须出现在某个 `##` 之后，否则报错——
/// 解析失败要在编辑器里当场看见，不许静默吞掉。
library;

import '../models/lesson.dart';

Lesson parseLessonMd(String source, {String name = '', String course = ''}) {
  final lines = source.split('\n');
  String? title;
  String? lede;
  String? tip;
  String? foot;
  final steps = <_StepDraft>[];
  _StepDraft? current;

  final paragraph = <String>[];
  var inFence = false;
  var fenceInfo = '';
  final fenceBody = <String>[];

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    final text = paragraph.join(' ').trim();
    paragraph.clear();
    if (text.isEmpty) return;
    final draft = current;
    if (draft != null) {
      draft.doText = draft.doText.isEmpty ? text : '${draft.doText} $text';
    } else if (title == null) {
      // 标题之前的引言不进课时
    } else if (lede == null) {
      lede = text;
    } else {
      lede = '$lede $text';
    }
  }

  void flushFence() {
    final info = fenceInfo.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (info.isEmpty) {
      throw const FormatException('围栏代码块缺少类型（copy/note/code/link/image/tip/foot）');
    }
    final kind = info.first;
    final label = info.length > 1 ? info.sublist(1).join(' ') : null;
    final body = fenceBody.toList();
    fenceBody.clear();

    const stepKinds = {'note', 'copy', 'code', 'link', 'image'};
    if (stepKinds.contains(kind) && current == null) {
      throw FormatException('$kind 块必须出现在某个 ## 步骤之后');
    }

    switch (kind) {
      case 'tip':
        tip = body.join('\n').trim();
      case 'foot':
        foot = body.join('\n').trim();
      case 'note':
        current!.blocks.add(NoteBlock(
          label: label,
          lines: body.map((l) => l.trimRight()).toList(),
        ));
      case 'copy':
        current!.blocks.add(CopyBlock(label: label, text: body.join('\n').trim()));
      case 'code':
        current!.blocks.add(CodeBlock(
          label: label,
          lines: body
              .map((l) => CodeLine(l, ok: l.trimLeft().startsWith('✓')))
              .toList(),
        ));
      case 'link':
        final url = body.firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
        final rest = body.where((l) => l.trim().isNotEmpty && l != url).join(' ');
        current!.blocks.add(LinkBlock(label: label, url: url.trim(), tip: rest.isEmpty ? null : rest));
      case 'image':
        final nonEmpty = body.where((l) => l.trim().isNotEmpty).toList();
        if (nonEmpty.length < 2) {
          throw const FormatException('image 块至少要有 src 与 alt 两行');
        }
        current!.blocks.add(ImageBlock(
          label: label,
          src: nonEmpty[0].trim(),
          alt: nonEmpty[1].trim(),
          tip: nonEmpty.length > 2 ? nonEmpty.sublist(2).join(' ') : null,
        ));
      default:
        throw FormatException('未知的围栏类型：$kind');
    }
  }

  for (final raw in lines) {
    if (inFence) {
      if (raw.trimRight() == '```') {
        inFence = false;
        flushFence();
      } else {
        fenceBody.add(raw);
      }
      continue;
    }

    if (raw.startsWith('```')) {
      flushParagraph();
      inFence = true;
      fenceInfo = raw.substring(3).trim();
      continue;
    }

    if (raw.startsWith('# ')) {
      flushParagraph();
      title ??= raw.substring(2).trim();
      continue;
    }

    if (raw.startsWith('## ')) {
      flushParagraph();
      current = _StepDraft(title: raw.substring(3).trim());
      steps.add(current);
      continue;
    }

    if (raw.trim().isEmpty) {
      flushParagraph();
      continue;
    }

    paragraph.add(raw.trim());
  }

  if (inFence) {
    throw const FormatException('围栏代码块没有闭合');
  }
  flushParagraph();

  if (title == null || title.isEmpty) {
    throw const FormatException('缺少以 # 开头的课时标题');
  }

  return Lesson(
    name: name,
    course: course,
    title: title,
    lede: lede,
    steps: [
      for (var i = 0; i < steps.length; i++)
        LessonStep(
          num: i + 1,
          title: steps[i].title,
          doText: steps[i].doText,
          blocks: steps[i].blocks,
        ),
    ],
    tip: tip,
    foot: foot,
  );
}

class _StepDraft {
  final String title;
  String doText = '';
  final List<LessonBlock> blocks = [];

  _StepDraft({required this.title});
}
