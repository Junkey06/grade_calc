/// Interface (abstract class) that defines the grade calculation strategy.
///
/// Any class implementing this interface must provide a method
/// to calculate a grade from a total score.
/// This follows the Strategy Pattern — allowing different grading
/// strategies to be swapped in if needed.
abstract class GradeStrategy {
  /// Calculate and return the grade string based on the total score.
  ///
  /// [totalScore] must be between 0 and 100.
  String calculateGrade(double totalScore);
}
