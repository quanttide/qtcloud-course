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



