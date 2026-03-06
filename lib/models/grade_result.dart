import 'package:flutter/material.dart';

/// Model class representing the calculated grade result
class GradeResult {
  final double average;
  final String grade;
  final String remark;
  final Color color;
  final IconData icon;

  GradeResult({
    required this.average,
    required this.grade,
    required this.remark,
    required this.color,
    required this.icon,
  });

  /// Factory constructor to create a GradeResult from an average score
  factory GradeResult.fromAverage(double average) {
    if (average >= 90) {
      return GradeResult(
        average: average,
        grade: 'A+',
        remark: 'Outstanding! Exceptional Performance!',
        color: const Color(0xFF00C853),
        icon: Icons.emoji_events,
      );
    } else if (average >= 80) {
      return GradeResult(
        average: average,
        grade: 'A',
        remark: 'Excellent! Keep up the great work!',
        color: const Color(0xFF2E7D32),
        icon: Icons.star,
      );
    } else if (average >= 70) {
      return GradeResult(
        average: average,
        grade: 'B',
        remark: 'Good Job! You\'re doing well!',
        color: const Color(0xFF1976D2),
        icon: Icons.thumb_up,
      );
    } else if (average >= 60) {
      return GradeResult(
        average: average,
        grade: 'C',
        remark: 'Fair! Room for improvement.',
        color: const Color(0xFFFFA000),
        icon: Icons.trending_up,
      );
    } else if (average >= 50) {
      return GradeResult(
        average: average,
        grade: 'D',
        remark: 'Pass! Try harder next time.',
        color: const Color(0xFFE65100),
        icon: Icons.warning_amber,
      );
    } else {
      return GradeResult(
        average: average,
        grade: 'F',
        remark: 'Fail! Don\'t give up, keep trying!',
        color: const Color(0xFFD32F2F),
        icon: Icons.sentiment_dissatisfied,
      );
    }
  }
}
