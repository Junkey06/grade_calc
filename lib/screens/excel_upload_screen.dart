import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../models/student.dart';
import '../services/excel_handler.dart';
import '../services/grade_calculator.dart';
import '../services/student_manager.dart';
import 'student_result_screen.dart';

/// Screen for uploading an Excel (.xlsx/.xls) file with student data.
///
/// Validates the file format, parses student records, calculates grades
/// using the OOP service layer, and navigates to the result screen.
class ExcelUploadScreen extends StatefulWidget {
  const ExcelUploadScreen({Key? key}) : super(key: key);

  @override
  State<ExcelUploadScreen> createState() => _ExcelUploadScreenState();
}

class _ExcelUploadScreenState extends State<ExcelUploadScreen> {
  String? _fileName;
  Uint8List? _fileBytes;
  bool _isProcessing = false;
  String? _errorMessage;
  List<Student>? _previewStudents;

  Future<void> _pickFile() async {
    setState(() {
      _errorMessage = null;
      _previewStudents = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _fileName = file.name;
          _fileBytes = file.bytes!;
        });
        _validateAndPreview();
      } else {
        setState(() => _errorMessage = 'Could not read file data.');
      }
    }
  }

  void _validateAndPreview() {
    if (_fileBytes == null) return;

    // Validate Excel format
    final validationError = ExcelHandler.validateExcelBytes(_fileBytes!);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    // Parse students from Excel (without grades yet — just preview)
    try {
      final students = ExcelHandler.readStudentsFromBytes(_fileBytes!);
      if (students.isEmpty) {
        setState(() => _errorMessage = 'No student data found in the file.');
        return;
      }
      setState(() => _previewStudents = students);
    } catch (e) {
      setState(() => _errorMessage = 'Error reading file: ${e.toString()}');
    }
  }

  Future<void> _processAndNavigate() async {
    if (_previewStudents == null) return;

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 400));

    // Use StudentManager with GradeCalculator (OOP + Interface)
    final manager = StudentManager(gradeStrategy: GradeCalculator());
    manager.setStudents(_previewStudents!);
    manager.calculateAllGrades();

    // Calculate statistics using lambda-powered method
    final stats = GradeCalculator.calculateStatistics(manager.students);

    setState(() => _isProcessing = false);
    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            StudentResultScreen(students: manager.students, statistics: stats),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildUploadArea(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBanner(),
                      ],
                      if (_previewStudents != null) ...[
                        const SizedBox(height: 20),
                        _buildPreview(),
                        const SizedBox(height: 24),
                        GradientButton(
                          text: 'Calculate Grades',
                          icon: Icons.calculate,
                          width: double.infinity,
                          isLoading: _isProcessing,
                          onPressed: _processAndNavigate,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildFormatGuide(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'Excel Upload',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload an Excel file with student scores',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _fileName != null
                ? AppTheme.accentColor
                : AppTheme.primaryStart.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _fileName != null
                    ? AppTheme.accentColor.withOpacity(0.1)
                    : AppTheme.primaryStart.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _fileName != null ? Icons.check_circle : Icons.upload_file,
                size: 50,
                color: _fileName != null
                    ? AppTheme.accentColor
                    : AppTheme.primaryStart,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _fileName ?? 'Tap to Select Excel File',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _fileName != null
                    ? AppTheme.accentColor
                    : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _fileName != null
                  ? 'Tap to choose a different file'
                  : 'Supported: .xlsx, .xls',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final students = _previewStudents!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.preview, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Preview (${students.length} students)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Show first 5 students as preview
          ...students
              .take(5)
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'CA: ${s.caScore.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Test: ${s.testScore.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          'Total: ${s.totalScore.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryStart,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (students.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... and ${students.length - 5} more students',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormatGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade800,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Expected Excel Format',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFormatRow('Column A', 'Student Name', Icons.person),
          _buildFormatRow('Column B', 'CA Score', Icons.assignment),
          _buildFormatRow('Column C', 'Test Score', Icons.quiz),
          _buildFormatRow(
            'Column D',
            'Total Score (optional)',
            Icons.functions,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'The first row should be a header. Data starts from row 2. If Total Score is not provided, it will be calculated as CA + Test.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatRow(String column, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryStart),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              column,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.primaryStart,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
