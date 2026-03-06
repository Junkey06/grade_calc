import '../models/student.dart';
import '../interfaces/grade_strategy.dart';
import 'grade_calculator.dart';

/// StudentManager class — manages student lists and processing.
///
/// Demonstrates:
/// - Higher-order functions (functions accepting other functions as parameters)
/// - Lambda expressions for list operations
/// - Clean separation of student management from grade logic
class StudentManager {
  /// The list of students being managed
  List<Student> _students = [];

  /// The grade strategy to use (implements the GradeStrategy interface)
  final GradeStrategy _gradeStrategy;

  /// Constructor injects the grade strategy (Dependency Injection via interface)
  StudentManager({GradeStrategy? gradeStrategy})
    : _gradeStrategy = gradeStrategy ?? GradeCalculator();

  /// Getter: returns an unmodifiable view of the student list
  List<Student> get students => List.unmodifiable(_students);

  /// Getter: student count using lambda
  int get studentCount => _students.length;

  /// Add a single student
  void addStudent(Student student) {
    _students.add(student);
  }

  /// Add multiple students at once
  void addAllStudents(List<Student> students) {
    _students.addAll(students);
  }

  /// Set the student list (replaces existing)
  void setStudents(List<Student> students) {
    _students = List.from(students);
  }

  /// Clear all students
  void clearStudents() {
    _students.clear();
  }

  // ─── Higher-Order Functions ───────────────────────────────────────

  /// Higher-order function: processes each student through a provided operation.
  ///
  /// This accepts a function as a parameter and applies it to every student.
  /// Example: processStudents(students, (s) => print(s.name));
  void processStudents(List<Student> students, Function(Student) operation) {
    students.forEach(operation);
  }

  /// Higher-order function: transforms students using a provided mapper function.
  ///
  /// Returns a new list of students transformed by the mapper.
  List<Student> transformStudents(
    List<Student> students,
    Student Function(Student) mapper,
  ) {
    return students.map(mapper).toList();
  }

  /// Higher-order function: filters students using a provided predicate.
  ///
  /// Returns only students that satisfy the test function.
  List<Student> filterStudents(
    List<Student> students,
    bool Function(Student) test,
  ) {
    return students.where(test).toList();
  }

  // ─── Grade Computation ────────────────────────────────────────────

  /// Calculate grades for all managed students using the injected strategy.
  /// Uses lambda expression with map to transform each student.
  void calculateAllGrades() {
    _students = _students
        .map(
          (s) => s.copyWith(grade: _gradeStrategy.calculateGrade(s.totalScore)),
        )
        .toList();
  }

  /// Calculate grades for a provided list and return the result.
  /// Demonstrates lambda with map.
  List<Student> calculateGrades(List<Student> students) {
    return students
        .map(
          (s) => s.copyWith(grade: _gradeStrategy.calculateGrade(s.totalScore)),
        )
        .toList();
  }

  // ─── Lambda-powered Queries ───────────────────────────────────────

  /// Get students who passed (totalScore >= 40) using lambda with where
  List<Student> getPassingStudents() =>
      _students.where((s) => s.totalScore >= 40).toList();

  /// Get students who failed (totalScore < 40) using lambda with where
  List<Student> getFailingStudents() =>
      _students.where((s) => s.totalScore < 40).toList();

  /// Get students with a specific grade using lambda with where
  List<Student> getStudentsByGrade(String grade) =>
      _students.where((s) => s.grade == grade).toList();

  /// Get the highest scoring student using lambda with reduce
  Student? getTopStudent() {
    if (_students.isEmpty) return null;
    return _students.reduce((a, b) => a.totalScore >= b.totalScore ? a : b);
  }

  /// Get the lowest scoring student using lambda with reduce
  Student? getLowestStudent() {
    if (_students.isEmpty) return null;
    return _students.reduce((a, b) => a.totalScore <= b.totalScore ? a : b);
  }

  /// Get grade distribution as a map: grade -> count
  /// Uses lambda with fold for aggregation
  Map<String, int> getGradeDistribution() {
    return _students.fold<Map<String, int>>({}, (map, student) {
      map[student.grade] = (map[student.grade] ?? 0) + 1;
      return map;
    });
  }

  /// Sort students by total score (descending) using lambda comparator
  List<Student> getSortedByScore({bool ascending = false}) {
    final sorted = List<Student>.from(_students);
    sorted.sort(
      (a, b) => ascending
          ? a.totalScore.compareTo(b.totalScore)
          : b.totalScore.compareTo(a.totalScore),
    );
    return sorted;
  }

  /// Get all student names using lambda with map
  List<String> getAllStudentNames() => _students.map((s) => s.name).toList();
}
