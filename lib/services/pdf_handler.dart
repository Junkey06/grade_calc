import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/student.dart';
import 'grade_calculator.dart';

/// PdfHandler class — generates beautiful PDF reports of student grades.
///
/// Creates a professional PDF document containing:
/// - Title and date header
/// - Student grades table (Name, CA, Test, Total, Grade)
/// - Summary statistics section
/// - Grade distribution breakdown
class PdfHandler {
  /// Generate a PDF report and return the file path.
  ///
  /// Uses lambda expressions for data mapping and PDF construction.
  static Future<String> generateReport(List<Student> students) async {
    final pdf = pw.Document();

    // Calculate statistics using lambdas
    final stats = GradeCalculator.calculateStatistics(students);
    final passCount = students.where((s) => s.totalScore >= 40).length;
    final failCount = students.where((s) => s.totalScore < 40).length;

    // Grade distribution using fold lambda
    final gradeDistribution = students.fold<Map<String, int>>({}, (map, s) {
      map[s.grade] = (map[s.grade] ?? 0) + 1;
      return map;
    });

    // Sort grades in order
    final gradeOrder = ['A', 'B+', 'B', 'C+', 'C', 'D+', 'D', 'F'];

    // Build the PDF pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Title section
          _buildTitle(),
          pw.SizedBox(height: 20),

          // Student table
          _buildStudentTable(students),
          pw.SizedBox(height: 30),

          // Statistics section
          _buildStatisticsSection(stats, passCount, failCount, students.length),
          pw.SizedBox(height: 20),

          // Grade distribution
          _buildGradeDistribution(
            gradeDistribution,
            gradeOrder,
            students.length,
          ),
        ],
      ),
    );

    // Save to file
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/student_grades_report_$timestamp.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  /// Build the PDF header with app name
  static pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        'Grade Calculator Report',
        style: pw.TextStyle(
          color: PdfColors.grey600,
          fontSize: 10,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  /// Build the PDF footer with page number
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
      ),
    );
  }

  /// Build the title section
  static pw.Widget _buildTitle() {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Student Grade Report',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo800,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Generated on: $dateStr',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: PdfColors.indigo200, thickness: 2),
      ],
    );
  }

  /// Build the student grades table.
  /// Uses lambda for row mapping.
  static pw.Widget _buildStudentTable(List<Student> students) {
    return pw.TableHelper.fromTextArray(
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 11,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      headers: [
        'Student Name',
        'CA Score',
        'Test Score',
        'Total Score',
        'Grade',
      ],
      // Lambda: map each student to a row of string values
      data: students
          .map(
            (s) => [
              s.name,
              s.caScore.toStringAsFixed(1),
              s.testScore.toStringAsFixed(1),
              s.totalScore.toStringAsFixed(1),
              s.grade,
            ],
          )
          .toList(),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
    );
  }

  /// Build the statistics section
  static pw.Widget _buildStatisticsSection(
    Map<String, dynamic> stats,
    int passCount,
    int failCount,
    int totalStudents,
  ) {
    final passRate = totalStudents > 0
        ? ((passCount / totalStudents) * 100).toStringAsFixed(1)
        : '0.0';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Class Statistics',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _statItem('Total Students', '$totalStudents'),
              _statItem(
                'Highest Score',
                (stats['highest'] as double).toStringAsFixed(1),
              ),
              _statItem(
                'Lowest Score',
                (stats['lowest'] as double).toStringAsFixed(1),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _statItem(
                'Class Average',
                (stats['average'] as double).toStringAsFixed(2),
              ),
              _statItem('Pass Count', '$passCount'),
              _statItem('Fail Count', '$failCount'),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(children: [_statItem('Pass Rate', '$passRate%')]),
        ],
      ),
    );
  }

  /// Build a single statistic item
  static pw.Widget _statItem(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
        ],
      ),
    );
  }

  /// Build grade distribution section.
  /// Uses lambda to iterate over grade entries.
  static pw.Widget _buildGradeDistribution(
    Map<String, int> distribution,
    List<String> gradeOrder,
    int totalStudents,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Grade Distribution',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
          pw.SizedBox(height: 12),
          // Lambda: map each grade to a row widget
          ...gradeOrder.where((g) => distribution.containsKey(g)).map((grade) {
            final count = distribution[grade]!;
            final percentage = totalStudents > 0
                ? ((count / totalStudents) * 100).toStringAsFixed(1)
                : '0.0';
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 30,
                    child: pw.Text(
                      grade,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      height: 16,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Stack(
                        children: [
                          pw.Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: pw.Container(
                              width: totalStudents > 0
                                  ? 150 * (count / totalStudents)
                                  : 0,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.indigo400,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.SizedBox(
                    width: 60,
                    child: pw.Text(
                      '$count ($percentage%)',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
