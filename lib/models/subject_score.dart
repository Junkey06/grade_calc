/// Model class representing a single subject's scores for a student.
///
/// Each subject has a name, CA (Continuous Assessment) score, and Test score.
/// The total is computed automatically.
class SubjectScore {
  /// Name of the subject (e.g., "Mathematics", "English")
  final String subjectName;

  /// Continuous Assessment score for this subject
  final double caScore;

  /// Test/Exam score for this subject
  final double testScore;

  /// Total score for this subject (CA + Test), computed automatically
  double get total => caScore + testScore;

  SubjectScore({
    required this.subjectName,
    required this.caScore,
    required this.testScore,
  });

  @override
  String toString() =>
      'SubjectScore($subjectName: CA=$caScore, Test=$testScore, Total=$total)';
}
