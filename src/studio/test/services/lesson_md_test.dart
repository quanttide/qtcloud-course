import 'package:flutter_test/flutter_test.dart';
import 'package:qtcloud_course_studio/models/lesson.dart';
import 'package:qtcloud_course_studio/services/lesson_md.dart';

/// AI创意第 1 课的课时正文，形态与 lite 的 creative-hello-world 对应
const _fixture = '''
# 用 AI 生成你的第一张图

四步做完，你就学会一套「让 AI 教自己」的方法。每步都告诉你「做完会看到什么」

## 把背景交给 AI，让它教你读懂

复制下面整段，连同原文一起发给 AI。别自己硬读——让 AI 当老师，反过来问你问题。

```{copy} 点按钮一键复制
下面是一段小说原文。请当我的老师，帮我读懂它。
```

```{note} 做完你会看到
AI 没有直接把答案塞给你。
你在回答里，慢慢就读懂了这个情境。
```

## 让元宝接着生成图片

把上一步的提示词发给元宝。

```{copy} 点按钮一键复制
用刚才那段提示词，直接生成一张图片。
```

```{code} 做完你会看到
› 正在理解提示词…
✓ 生成完成：雨天咖啡馆里，递毛巾的那一刻
```

```{link} 产出链接
https://example.com/image
?sharecode= 后面那串一定要带上
```

```{image} 对照图
/lessons/hello-world/game-preview.png
串串摊游戏首页对照图
看到这个夜市摊页面就对了
```

```{tip}
想换故事？再说一句话就行。
```

```{foot}
结构是你的，故事随便换
```
''';

void main() {
  group('parseLessonMd', () {
    test('解析课时：标题、步骤序号与五种块', () {
      final lesson = parseLessonMd(_fixture, name: 'creative-hello-world');

      expect(lesson.name, 'creative-hello-world');
      expect(lesson.title, '用 AI 生成你的第一张图');
      expect(lesson.lede, startsWith('四步做完'));
      expect(lesson.steps, hasLength(2));
      expect(lesson.steps[0].num, 1);
      expect(lesson.steps[1].num, 2);
      expect(lesson.tip, '想换故事？再说一句话就行。');
      expect(lesson.foot, '结构是你的，故事随便换');
    });

    test('第 2 步的复制指令与回显原样保留', () {
      final lesson = parseLessonMd(_fixture);
      final step = lesson.steps[1];

      expect(step.doText, '把上一步的提示词发给元宝。');
      final copy = step.blocks.whereType<CopyBlock>().single;
      expect(copy.text, '用刚才那段提示词，直接生成一张图片。');
      expect(copy.label, '点按钮一键复制');

      final code = step.blocks.whereType<CodeBlock>().single;
      expect(code.lines, hasLength(2));
      expect(code.lines[0].ok, isFalse);
      expect(code.lines[1].ok, isTrue);
      expect(code.lines[1].text, '✓ 生成完成：雨天咖啡馆里，递毛巾的那一刻');
    });

    test('link 与 image 块按行拆字段', () {
      final lesson = parseLessonMd(_fixture);
      final step = lesson.steps[1];

      final link = step.blocks.whereType<LinkBlock>().single;
      expect(link.url, 'https://example.com/image');
      expect(link.tip, contains('sharecode'));

      final image = step.blocks.whereType<ImageBlock>().single;
      expect(image.src, '/lessons/hello-world/game-preview.png');
      expect(image.alt, '串串摊游戏首页对照图');
      expect(image.tip, '看到这个夜市摊页面就对了');
    });

    test('缺标题报错', () {
      expect(() => parseLessonMd('没有标题'), throwsFormatException);
    });

    test('围栏未闭合报错', () {
      expect(
        () => parseLessonMd('# 标题\n\n## 步骤\n\n```{copy} 标签\n正文'),
        throwsFormatException,
      );
    });

    test('块悬空（没有 ## 步骤）报错', () {
      expect(
        () => parseLessonMd('# 标题\n\n```{note} 标签\n行\n```\n'),
        throwsFormatException,
      );
    });

    test('未知 directive 报错', () {
      expect(
        () => parseLessonMd('# 标题\n\n## 步骤\n\n```{widget} 标签\n行\n```\n'),
        throwsFormatException,
      );
    });

    test('围栏不写花括号（非 MyST 形状）报错', () {
      expect(
        () => parseLessonMd('# 标题\n\n## 步骤\n\n```copy 标签\n行\n```\n'),
        throwsFormatException,
      );
    });
  });
}
