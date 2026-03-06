import '../models/subject.dart';
import '../models/grade_result.dart';

/// Service class containing all grade calculation business logic
class GradeCalculatorService {
  /// Calculate the average from a list of subjects
  static double calculateAverage(List<Subject> subjects) {
    if (subjects.isEmpty) return 0;

    double total = 0;
    int count = 0;

    for (var subject in subjects) {
      if (subject.hasMarks) {
        total += subject.marks!;
        count++;
      }
    }

    if (count == 0) return 0;
    return total / count;
  }

  /// Calculate and return a GradeResult from subjects
  static GradeResult calculateGrade(List<Subject> subjects) {
    final average = calculateAverage(subjects);
    return GradeResult.fromAverage(average);
  }

  /// Validate if marks are within valid range (0-100)
  static bool isValidMarks(double marks) {
    return marks >= 0 && marks <= 100;
  }

  /// Parse and validate marks input string
  static double? parseMarks(String input) {
    if (input.isEmpty) return null;

    final marks = double.tryParse(input);
    if (marks == null) return null;
    if (!isValidMarks(marks)) return null;

    return marks;
  }

  /// Get grade statistics breakdown
  static Map<String, dynamic> getStatistics(List<Subject> subjects) {
    if (subjects.isEmpty || subjects.every((s) => !s.hasMarks)) {
      return {
        'highest': 0.0,
        'lowest': 0.0,
        'average': 0.0,
        'total': 0.0,
        'subjectCount': 0,
      };
    }

    final marksWithValues = subjects
        .where((s) => s.hasMarks)
        .map((s) => s.marks!)
        .toList();

    return {
      'highest': marksWithValues.reduce((a, b) => a > b ? a : b),
      'lowest': marksWithValues.reduce((a, b) => a < b ? a : b),
      'average': calculateAverage(subjects),
      'total': marksWithValues.reduce((a, b) => a + b),
      'subjectCount': marksWithValues.length,
    };
  }
}
