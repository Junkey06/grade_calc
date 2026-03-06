import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/student.dart';

/// ExcelHandler class — responsible for reading and writing Excel files.
///
/// Handles:
/// - Reading student data from uploaded .xlsx files
/// - Writing student data (with grades) to new .xlsx files
/// - Validating Excel file format and data
class ExcelHandler {
  /// Read students from an Excel file's bytes.
  ///
  /// Expected columns in order:
  ///   Student Name | CA Score | Test Score | Total Score
  ///
  /// Returns a list of Student objects parsed from the file.
  /// Uses lambda functions for data transformation.
  static List<Student> readStudentsFromBytes(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);

    // Get the first sheet
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;

    final students = <Student>[];

    // Skip header row (index 0), iterate data rows using forEach (lambda)
    sheet.rows.skip(1).forEach((row) {
      if (row.length >= 3 && row[0] != null) {
        // Extract values using lambda-style null-safe access
        final name = row[0]?.value?.toString().trim() ?? '';
        final caScore = _parseCell(row.length > 1 ? row[1] : null);
        final testScore = _parseCell(row.length > 2 ? row[2] : null);

        // Total score: use column 4 if available, otherwise compute
        final totalScore = row.length > 3 && row[3] != null
            ? _parseCell(row[3])
            : caScore + testScore;

        if (name.isNotEmpty) {
          students.add(
            Student(
              name: name,
              caScore: caScore,
              testScore: testScore,
              totalScore: totalScore,
            ),
          );
        }
      }
    });

    return students;
  }

  /// Write students (with grades) to a new Excel file and return the file path.
  ///
  /// Generates columns: Student Name | CA Score | Test Score | Total Score | Grade
  /// Uses lambda expressions for row generation.
  static Future<String> writeStudentsToExcel(List<Student> students) async {
    final excel = Excel.createExcel();
    final sheetName = 'Student Grades';
    final sheet = excel[sheetName];

    // Remove the default "Sheet1" if it exists
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Header row styling
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontSize: 12,
    );

    // Write header row
    final headers = [
      'Student Name',
      'CA Score',
      'Test Score',
      'Total Score',
      'Grade',
    ];
    headers.asMap().forEach((index, header) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 0),
      );
      cell.value = TextCellValue(header);
      cell.cellStyle = headerStyle;
    });

    // Data style
    final dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 11,
    );

    // Write student data rows using lambda (forEach with index)
    students.asMap().forEach((index, student) {
      final rowIndex = index + 1;

      // Student Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        ..value = TextCellValue(student.name)
        ..cellStyle = CellStyle(fontSize: 11);

      // CA Score
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        ..value = DoubleCellValue(student.caScore)
        ..cellStyle = dataStyle;

      // Test Score
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
        ..value = DoubleCellValue(student.testScore)
        ..cellStyle = dataStyle;

      // Total Score
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
        ..value = DoubleCellValue(student.totalScore)
        ..cellStyle = dataStyle;

      // Grade
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
        ..value = TextCellValue(student.grade)
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          fontSize: 11,
        );
    });

    // Set column widths for readability
    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 10);

    // Save to device
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/student_grades_$timestamp.xlsx';

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
    }

    return filePath;
  }

  /// Validate that the Excel file has the expected format.
  /// Returns null if valid, or an error message string if invalid.
  static String? validateExcelBytes(Uint8List bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        return 'The Excel file contains no sheets.';
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.rows.isEmpty) {
        return 'The Excel sheet is empty.';
      }

      if (sheet.rows.length < 2) {
        return 'The Excel file has no data rows (only header found).';
      }

      return null; // Valid
    } catch (e) {
      return 'Invalid Excel file format: ${e.toString()}';
    }
  }

  /// Helper: parse a cell value to double
  static double _parseCell(Data? cell) {
    if (cell == null || cell.value == null) return 0.0;
    final val = cell.value;
    if (val is DoubleCellValue) return val.value;
    if (val is IntCellValue) return val.value.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
