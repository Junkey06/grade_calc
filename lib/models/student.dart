import 'package:flutter/material.dart';

/// OOP Model class representing a Student with scores and grade.
///
/// Encapsulates all student-related data: name, CA score, test score,
/// computed total score, and the resulting grade.
class Student {
  /// Student's full name
  final String name;

  /// Continuous Assessment score
  final double caScore;

  /// Test/Exam score
  final double testScore;

  /// Total score (CA + Test), computed automatically
  final double totalScore;

  /// Calculated grade based on totalScore (e.g., 'A', 'B+', 'F')
  String grade;

  Student({
    required this.name,
    required this.caScore,
    required this.testScore,
    double? totalScore,
    this.grade = '',
  }) : totalScore = totalScore ?? (caScore + testScore);

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
    return Student(
      name: name,
      caScore: caScore,
      testScore: testScore,
      totalScore: totalScore,
      grade: grade ?? this.grade,
    );
  }

  @override
  String toString() =>
      'Student(name: $name, CA: $caScore, Test: $testScore, Total: $totalScore, Grade: $grade)';
}
