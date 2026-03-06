import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_card.dart';
import '../models/student.dart';
import '../models/subject_score.dart';
import '../services/grade_calculator.dart';
import '../services/student_manager.dart';
import 'student_result_screen.dart';

/// Screen for manually entering student data with multiple subjects.
///
/// Flow:
/// Step 1 — Select number of students and number of subjects
/// Step 2 — Enter subject names
/// Step 3 — Enter each student's name and scores per subject
class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({Key? key}) : super(key: key);

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  // Step tracking: 0 = setup, 1 = subject names, 2 = student entry
  int _currentStep = 0;

  int _numberOfStudents = 5;
  int _numberOfSubjects = 3;
  bool _isCalculating = false;

  // Subject name controllers
  final List<TextEditingController> _subjectNameControllers = [];

  // Student name controllers (indexed by student)
  final List<TextEditingController> _nameControllers = [];

  // Score controllers: _caControllers[studentIndex][subjectIndex]
  final List<List<TextEditingController>> _caControllers = [];
  final List<List<TextEditingController>> _testControllers = [];

  final _formKey = GlobalKey<FormState>();
  final _subjectFormKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _disposeAllControllers();
    _scrollController.dispose();
    super.dispose();
  }

  void _disposeAllControllers() {
    for (var c in _subjectNameControllers) {
      c.dispose();
    }
    for (var c in _nameControllers) {
      c.dispose();
    }
    for (var row in _caControllers) {
      for (var c in row) {
        c.dispose();
      }
    }
    for (var row in _testControllers) {
      for (var c in row) {
        c.dispose();
      }
    }
  }

  void _setupSubjectNameControllers() {
    // Dispose old subject name controllers
    for (var c in _subjectNameControllers) {
      c.dispose();
    }
    _subjectNameControllers.clear();

    for (int i = 0; i < _numberOfSubjects; i++) {
      _subjectNameControllers.add(
        TextEditingController(text: 'Subject ${i + 1}'),
      );
    }
  }

  void _setupStudentControllers() {
    // Dispose old student controllers
    for (var c in _nameControllers) {
      c.dispose();
    }
    for (var row in _caControllers) {
      for (var c in row) {
        c.dispose();
      }
    }
    for (var row in _testControllers) {
      for (var c in row) {
        c.dispose();
      }
    }

    _nameControllers.clear();
    _caControllers.clear();
    _testControllers.clear();

    for (int i = 0; i < _numberOfStudents; i++) {
      _nameControllers.add(TextEditingController());
      _caControllers.add(
        List.generate(_numberOfSubjects, (_) => TextEditingController()),
      );
      _testControllers.add(
        List.generate(_numberOfSubjects, (_) => TextEditingController()),
      );
    }
  }

  void _goToSubjectNames() {
    setState(() {
      _setupSubjectNameControllers();
      _currentStep = 1;
    });
    _scrollToTop();
  }

  void _goToStudentEntry() {
    if (!_subjectFormKey.currentState!.validate()) return;
    setState(() {
      _setupStudentControllers();
      _currentStep = 2;
    });
    _scrollToTop();
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _scrollToTop();
    } else {
      Navigator.pop(context);
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  List<String> get _subjectNames =>
      _subjectNameControllers.map((c) => c.text.trim()).toList();

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _validateScore(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final score = double.tryParse(value);
    if (score == null) return 'Invalid';
    if (score < 0 || score > 100) return '0-100';
    return null;
  }

  Future<void> _calculateGrades() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCalculating = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final subjectNames = _subjectNames;

    // Build Student objects with per-subject scores using lambda-style map
    final students = List.generate(_numberOfStudents, (i) {
      final name = _nameControllers[i].text.trim();
      final subjects = List.generate(_numberOfSubjects, (j) {
        return SubjectScore(
          subjectName: subjectNames[j],
          caScore: double.parse(_caControllers[i][j].text),
          testScore: double.parse(_testControllers[i][j].text),
        );
      });
      return Student(name: name, subjects: subjects);
    });

    // Use StudentManager with GradeCalculator (OOP + Interface + Higher-order)
    final manager = StudentManager(gradeStrategy: GradeCalculator());
    manager.setStudents(students);
    manager.calculateAllGrades();

    final stats = GradeCalculator.calculateStatistics(manager.students);

    setState(() => _isCalculating = false);
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
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  child: _currentStep == 0
                      ? _buildSetupStep()
                      : _currentStep == 1
                      ? _buildSubjectNamesStep()
                      : _buildStudentEntryStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = ['Manual Entry', 'Name Subjects', 'Enter Student Data'];
    final subtitles = [
      'Set up your class size and subjects',
      'Give each subject a name',
      'Enter name and scores for each student',
    ];

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
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  titles[_currentStep],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
            subtitles[_currentStep],
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          // Step indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final isActive = i <= _currentStep;
              return Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: isActive
                              ? AppTheme.primaryStart
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  if (i < 2)
                    Container(
                      width: 40,
                      height: 2,
                      color: i < _currentStep
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Step 0: Setup (student count + subject count) ────────────────

  Widget _buildSetupStep() {
    return Column(
      children: [
        _buildCountCard(
          icon: Icons.people,
          title: 'Number of Students',
          value: _numberOfStudents,
          min: 1,
          max: 50,
          quickPicks: [5, 10, 15, 20, 30],
          onChanged: (v) => setState(() => _numberOfStudents = v),
        ),
        const SizedBox(height: 20),
        _buildCountCard(
          icon: Icons.menu_book,
          title: 'Number of Subjects',
          value: _numberOfSubjects,
          min: 1,
          max: 15,
          quickPicks: [3, 5, 6, 8, 10],
          onChanged: (v) => setState(() => _numberOfSubjects = v),
        ),
        const SizedBox(height: 24),
        GradientButton(
          text: 'Continue',
          icon: Icons.arrow_forward,
          width: double.infinity,
          onPressed: _goToSubjectNames,
        ),
      ],
    );
  }

  Widget _buildCountCard({
    required IconData icon,
    required String title,
    required int value,
    required int min,
    required int max,
    required List<int> quickPicks,
    required ValueChanged<int> onChanged,
  }) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildCountButton(Icons.remove, () {
                if (value > min) onChanged(value - 1);
              }),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryStart,
                      ),
                    ),
                    Text(
                      title.toLowerCase().replaceAll('number of ', ''),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCountButton(Icons.add, () {
                if (value < max) onChanged(value + 1);
              }),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: quickPicks.map((count) {
              final isSelected = value == count;
              return ChoiceChip(
                label: Text('$count'),
                selected: isSelected,
                onSelected: (_) => onChanged(count),
                selectedColor: AppTheme.primaryStart,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCountButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: AppTheme.primaryStart, size: 28),
      ),
    );
  }

  // ─── Step 1: Subject Names ────────────────────────────────────────

  Widget _buildSubjectNamesStep() {
    return Form(
      key: _subjectFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Name Your $_numberOfSubjects Subjects',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_numberOfSubjects, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 66,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _subjectNameControllers[index],
                      validator: _validateName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter subject name',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    onPressed: () => _subjectNameControllers[index].clear(),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Continue to Enter Scores',
            icon: Icons.arrow_forward,
            width: double.infinity,
            onPressed: _goToStudentEntry,
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Student Entry Form ───────────────────────────────────

  Widget _buildStudentEntryStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(),
          const SizedBox(height: 20),
          ...List.generate(
            _numberOfStudents,
            (index) => _buildStudentCard(index),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Calculate Grades',
            icon: Icons.calculate,
            width: double.infinity,
            isLoading: _isCalculating,
            onPressed: _calculateGrades,
          ),
          const SizedBox(height: 12),
          OutlinedGradientButton(
            text: 'Reset All',
            icon: Icons.refresh,
            onPressed: () {
              for (var c in _nameControllers) {
                c.clear();
              }
              for (var row in _caControllers) {
                for (var c in row) {
                  c.clear();
                }
              }
              for (var row in _testControllers) {
                for (var c in row) {
                  c.clear();
                }
              }
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    int filledCount = 0;
    for (int i = 0; i < _numberOfStudents; i++) {
      if (_nameControllers[i].text.isNotEmpty &&
          _caControllers[i].every((c) => c.text.isNotEmpty) &&
          _testControllers[i].every((c) => c.text.isNotEmpty)) {
        filledCount++;
      }
    }
    double progress = filledCount / _numberOfStudents;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '$filledCount/$_numberOfStudents students',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppTheme.accentColor : AppTheme.primaryStart,
              ),
            ),
          ),
          if (progress == 1.0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppTheme.accentColor, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'All students filled! Ready to calculate.',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentCard(int studentIndex) {
    final subjectNames = _subjectNames;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student number header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${studentIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Student ${studentIndex + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Name field
            TextFormField(
              controller: _nameControllers[studentIndex],
              validator: _validateName,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Student Name',
                hintText: 'Enter full name',
                prefixIcon: const Icon(
                  Icons.person,
                  color: AppTheme.primaryStart,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryStart,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Per-subject score fields
            ...List.generate(_numberOfSubjects, (subjectIndex) {
              return _buildSubjectScoreRow(
                studentIndex,
                subjectIndex,
                subjectNames[subjectIndex],
              );
            }),
            // Show computed average total
            _buildAverageTotal(studentIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectScoreRow(
    int studentIndex,
    int subjectIndex,
    String subjectName,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject label
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryStart.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${subjectIndex + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryStart,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subjectName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // CA and Test fields side by side
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _caControllers[studentIndex][subjectIndex],
                  validator: _validateScore,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'CA',
                    hintText: '0-100',
                    prefixIcon: const Icon(
                      Icons.assignment,
                      color: AppTheme.primaryStart,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryStart,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _testControllers[studentIndex][subjectIndex],
                  validator: _validateScore,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Test',
                    hintText: '0-100',
                    prefixIcon: const Icon(
                      Icons.quiz,
                      color: AppTheme.primaryStart,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryStart,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAverageTotal(int studentIndex) {
    // Compute average total from all subjects that have both scores entered
    double totalSum = 0;
    int validCount = 0;

    for (int j = 0; j < _numberOfSubjects; j++) {
      final ca = double.tryParse(_caControllers[studentIndex][j].text);
      final test = double.tryParse(_testControllers[studentIndex][j].text);
      if (ca != null && test != null) {
        totalSum += (ca + test);
        validCount++;
      }
    }

    if (validCount == 0) return const SizedBox.shrink();

    final avgTotal = totalSum / validCount;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryStart.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.functions, color: AppTheme.primaryStart, size: 18),
            const SizedBox(width: 6),
            Text(
              'Avg Total: ${avgTotal.toStringAsFixed(1)} ($validCount/$_numberOfSubjects subjects)',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryStart,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
