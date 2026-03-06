import 'package:flutter/material.dart';
import 'subject_score.dart';

/// OOP Model class representing a Student with scores and grade.
///
/// Supports multiple subjects — each subject has its own CA and Test score.
/// The student's overall caScore, testScore, and totalScore are computed
/// as averages across all subjects.
class Student {
  /// Student's full name
  final String name;

  /// List of per-subject scores (CA + Test per subject)
  final List<SubjectScore> subjects;

  /// Calculated grade based on totalScore (e.g., 'A', 'B+', 'F')
  String grade;

  Student({required this.name, required this.subjects, this.grade = ''});

  /// Factory constructor for single-subject backward compatibility.
  /// Used when importing from Excel or other flat data sources.
  factory Student.singleSubject({
    required String name,
    required double caScore,
    required double testScore,
    String subjectName = 'Subject',
    String grade = '',
  }) {
    return Student(
      name: name,
      subjects: [
        SubjectScore(
          subjectName: subjectName,
          caScore: caScore,
          testScore: testScore,
        ),
      ],
      grade: grade,
    );
  }

  /// Average CA score across all subjects (lambda getter)
  double get caScore => subjects.isEmpty
      ? 0
      : subjects.map((s) => s.caScore).reduce((a, b) => a + b) /
            subjects.length;

  /// Average Test score across all subjects (lambda getter)
  double get testScore => subjects.isEmpty
      ? 0
      : subjects.map((s) => s.testScore).reduce((a, b) => a + b) /
            subjects.length;

  /// Average Total score across all subjects (lambda getter)
  double get totalScore => subjects.isEmpty
      ? 0
      : subjects.map((s) => s.total).reduce((a, b) => a + b) / subjects.length;

  /// Whether this student has multiple subjects
  bool get hasMultipleSubjects => subjects.length > 1;

  /// Lambda getter — returns the color corresponding to the grade
  Color get gradeColor => _gradeColorMap[grade] ?? Colors.grey;

  /// Lambda getter — returns an icon corresponding to the grade
  IconData get gradeIcon => _gradeIconMap[grade] ?? Icons.help_outline;

  /// Lambda getter — returns a motivational remark for the grade
  String get remark => _remarkMap[grade] ?? 'No grade assigned yet.';

  /// Grade to color mapping (using lambda-style map literal)
  static final Map<String, Color> _gradeColorMap = {
    'A': const Color(0xFF00C853),
    'B+': const Color(0xFF2E7D32),
    'B': const Color(0xFF1976D2),
    'C+': const Color(0xFF0288D1),
    'C': const Color(0xFFFFA000),
    'D+': const Color(0xFFE65100),
    'D': const Color(0xFFBF360C),
    'F': const Color(0xFFD32F2F),
  };

  /// Grade to icon mapping
  static final Map<String, IconData> _gradeIconMap = {
    'A': Icons.emoji_events,
    'B+': Icons.star,
    'B': Icons.thumb_up,
    'C+': Icons.trending_up,
    'C': Icons.trending_flat,
    'D+': Icons.warning_amber,
    'D': Icons.arrow_downward,
    'F': Icons.sentiment_dissatisfied,
  };

  /// Grade to remark mapping
  static final Map<String, String> _remarkMap = {
    'A': 'Outstanding! Exceptional Performance!',
    'B+': 'Excellent! Keep up the great work!',
    'B': 'Good Job! You\'re doing well!',
    'C+': 'Above Average! Push a little harder!',
    'C': 'Fair! Room for improvement.',
    'D+': 'Below Average. Try harder next time.',
    'D': 'Poor. Significant improvement needed.',
    'F': 'Fail! Don\'t give up, keep trying!',
  };

  /// Create a copy of this student with an updated grade
  Student copyWith({String? grade}) {
    return Student(name: name, subjects: subjects, grade: grade ?? this.grade);
  }

  @override
  String toString() =>
      'Student(name: $name, subjects: ${subjects.length}, Avg Total: ${totalScore.toStringAsFixed(1)}, Grade: $grade)';
}
