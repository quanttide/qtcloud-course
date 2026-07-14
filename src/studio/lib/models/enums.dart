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

enum AssessmentType {
  homework,
  exam;

  String get label {
    switch (this) {
      case AssessmentType.homework:
        return '作业';
      case AssessmentType.exam:
        return '考试';
    }
  }

  static AssessmentType fromString(String value) {
    switch (value) {
      case 'exam':
        return AssessmentType.exam;
      default:
        return AssessmentType.homework;
    }
  }
}

enum SubmissionStatus {
  submitted,
  late,
  resubmitted;

  String get label {
    switch (this) {
      case SubmissionStatus.submitted:
        return '已提交';
      case SubmissionStatus.late:
        return '迟交';
      case SubmissionStatus.resubmitted:
        return '已重交';
    }
  }

  static SubmissionStatus fromString(String value) {
    switch (value) {
      case 'late':
        return SubmissionStatus.late;
      case 'resubmitted':
        return SubmissionStatus.resubmitted;
      default:
        return SubmissionStatus.submitted;
    }
  }
}
