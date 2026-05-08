enum ContentStatus {
  draft,
  published;

  String get label {
    switch (this) {
      case ContentStatus.draft:
        return '草稿';
      case ContentStatus.published:
        return '已发布';
    }
  }

  static ContentStatus fromString(String value) {
    switch (value) {
      case 'published':
        return ContentStatus.published;
      default:
        return ContentStatus.draft;
    }
  }
}

enum ClassStatus {
  preparing,
  active,
  ended;

  String get label {
    switch (this) {
      case ClassStatus.preparing:
        return '筹备中';
      case ClassStatus.active:
        return '进行中';
      case ClassStatus.ended:
        return '已结束';
    }
  }

  static ClassStatus fromString(String value) {
    switch (value) {
      case 'active':
        return ClassStatus.active;
      case 'ended':
        return ClassStatus.ended;
      default:
        return ClassStatus.preparing;
    }
  }
}
