/// 课时 directive：MyST 形状（`​```{name} 参数` + 正文），语义由注册表分发。
///
/// 这是 Studio 自己的一份实现，**不依赖 quanttide-docs-toolkit**——
/// 两边各自演化，架构稳了再谈依赖。库只认形状不认语义：七种课时块
/// 注册在 [DirectiveRegistry.lesson]，调用方可以再注册自己的。
library;

import '../models/lesson.dart';

/// 一个 directive 实例
class Directive {
  /// 名字，如 `copy`
  final String name;

  /// 首行 `}` 之后的参数，如 `点按钮一键复制`；无参数为空串
  final String args;

  /// 围栏正文，逐行保留
  final List<String> body;

  const Directive({
    required this.name,
    required this.args,
    required this.body,
  });

  /// 作为块标签的参数；无参数返回 null
  String? get label => args.isEmpty ? null : args;

  /// 正文拼成一段文本
  String get bodyText => body.join('\n');

  /// 正文里非空的行
  List<String> get nonEmptyBody =>
      body.where((line) => line.trim().isNotEmpty).toList();
}

/// 处理结果：挂到当前步骤的块，或课时级字段（tip / foot）
sealed class DirectiveOutcome {
  const DirectiveOutcome();
}

final class BlockOutcome extends DirectiveOutcome {
  final LessonBlock block;

  const BlockOutcome(this.block);
}

final class FieldOutcome extends DirectiveOutcome {
  /// 字段名，目前是 `tip` / `foot`
  final String field;
  final String value;

  const FieldOutcome(this.field, this.value);
}

typedef DirectiveHandler = DirectiveOutcome Function(Directive directive);

/// directive 注册表：名字 → 处理函数。这是扩展自定义语法的唯一入口。
class DirectiveRegistry {
  final _handlers = <String, DirectiveHandler>{};

  void register(String name, DirectiveHandler handler) {
    if (name.isEmpty || name.contains(' ') || name.contains('}')) {
      throw ArgumentError('非法 directive 名：$name');
    }
    _handlers[name] = handler;
  }

  bool supports(String name) => _handlers.containsKey(name);

  Iterable<String> get names => _handlers.keys;

  /// 分发；未注册报错，不让内容悄悄走样
  DirectiveOutcome resolve(Directive directive) {
    final handler = _handlers[directive.name];
    if (handler == null) {
      throw FormatException('未知的 directive：{${directive.name}}');
    }
    return handler(directive);
  }

  /// 课时的七种 directive
  static DirectiveRegistry lesson() {
    final registry = DirectiveRegistry()
      ..register('note', (d) {
        return BlockOutcome(NoteBlock(
          label: d.label,
          lines: d.body.map((line) => line.trimRight()).toList(),
        ));
      })
      ..register('copy', (d) {
        return BlockOutcome(CopyBlock(label: d.label, text: d.bodyText.trim()));
      })
      ..register('code', (d) {
        return BlockOutcome(CodeBlock(
          label: d.label,
          lines: d.body
              .map((line) => CodeLine(line, ok: line.trimLeft().startsWith('✓')))
              .toList(),
        ));
      })
      ..register('link', (d) {
        final body = d.nonEmptyBody;
        final url = body.isEmpty ? '' : body.first;
        final rest = body.length > 1 ? body.sublist(1).join(' ') : '';
        return BlockOutcome(LinkBlock(
          label: d.label,
          url: url.trim(),
          tip: rest.isEmpty ? null : rest,
        ));
      })
      ..register('image', (d) {
        final body = d.nonEmptyBody;
        if (body.length < 2) {
          throw const FormatException('image 块至少要有 src 与 alt 两行');
        }
        return BlockOutcome(ImageBlock(
          label: d.label,
          src: body[0].trim(),
          alt: body[1].trim(),
          tip: body.length > 2 ? body.sublist(2).join(' ') : null,
        ));
      })
      ..register('tip', (d) => FieldOutcome('tip', d.bodyText.trim()))
      ..register('foot', (d) => FieldOutcome('foot', d.bodyText.trim()));
    return registry;
  }
}
