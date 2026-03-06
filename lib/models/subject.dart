/// Model class representing a subject with its name and marks
class Subject {
  final String name;
  double? marks;

  Subject({required this.name, this.marks});

  /// Check if marks have been entered for this subject
  bool get hasMarks => marks != null;

  /// Create a copy of this subject with updated values
  Subject copyWith({String? name, double? marks}) {
    return Subject(name: name ?? this.name, marks: marks ?? this.marks);
  }
}
