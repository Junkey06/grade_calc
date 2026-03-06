import '../interfaces/grade_strategy.dart';
import '../models/student.dart';

/// GradeCalculator implements the GradeStrategy interface.
///
/// This class is responsible for all grade computation logic.
/// It uses the grading boundaries specified in the requirements:
///   A  : 80 - 100
///   B+ : 70 - 79.99
///   B  : 60 - 69.99
///   C+ : 55 - 59.99
///   C  : 50 - 54.99
///   D+ : 45 - 49.99
///   D  : 40 - 44.99
///   F  : 0  - 39.99
class GradeCalculator implements GradeStrategy {
  /// Grade boundaries defined as a list of (minScore, grade) tuples.
  /// Ordered from highest to lowest for efficient lookup.
  /// Uses a lambda-style list literal for clean definition.
  static final List<({double min, String grade})> _boundaries = [
    (min: 80.0, grade: 'A'),
    (min: 70.0, grade: 'B+'),
    (min: 60.0, grade: 'B'),
    (min: 55.0, grade: 'C+'),
    (min: 50.0, grade: 'C'),
    (min: 45.0, grade: 'D+'),
    (min: 40.0, grade: 'D'),
    (min: 0.0, grade: 'F'),
  ];

  /// Implements the GradeStrategy interface.
  /// Calculates grade from total score using the boundary table.
  @override
  String calculateGrade(double totalScore) {
    // Lambda expression: find the first boundary where score >= min
    final match = _boundaries.firstWhere(
      (b) => totalScore >= b.min,
      orElse: () => (min: 0.0, grade: 'F'),
    );
    return match.grade;
  }

  /// Higher-order function: applies a grade computation function
  /// to a single student and returns a new Student with the grade set.
  Student gradeStudent(Student student, String Function(double) gradeFunction) {
    final grade = gradeFunction(student.totalScore);
    return student.copyWith(grade: grade);
  }

  /// Lambda-powered bulk grading: maps over a list of students
  /// and assigns grades using this calculator's logic.
  List<Student> gradeAllStudents(List<Student> students) {
    // Uses lambda (=>) with map to transform each student
    return students
        .map((s) => s.copyWith(grade: calculateGrade(s.totalScore)))
        .toList();
  }

  /// Validate that a score is within the valid range (0-100)
  static bool isValidScore(double score) => score >= 0 && score <= 100;

  /// Parse and validate a score input string
  static double? parseScore(String input) {
    if (input.isEmpty) return null;
    final score = double.tryParse(input);
    if (score == null || !isValidScore(score)) return null;
    return score;
  }

  /// Calculate class statistics using lambda functions.
  /// Returns a map of statistical data about the students.
  static Map<String, dynamic> calculateStatistics(List<Student> students) {
    if (students.isEmpty) {
      return {
        'highest': 0.0,
        'lowest': 0.0,
        'average': 0.0,
        'total': 0.0,
        'studentCount': 0,
        'passCount': 0,
        'failCount': 0,
      };
    }

    // Lambda expressions used throughout for concise data extraction
    final scores = students.map((s) => s.totalScore).toList();
    final highest = scores.reduce((a, b) => a > b ? a : b);
    final lowest = scores.reduce((a, b) => a < b ? a : b);
    final total = scores.fold(0.0, (sum, s) => sum + s);
    final average = total / scores.length;

    // Lambda: count passing and failing students
    final passCount = students.where((s) => s.totalScore >= 40).length;
    final failCount = students.where((s) => s.totalScore < 40).length;

    return {
      'highest': highest,
      'lowest': lowest,
      'average': average,
      'total': total,
      'studentCount': students.length,
      'passCount': passCount,
      'failCount': failCount,
    };
  }
}
