import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_card.dart';
import '../models/student.dart';
import '../services/grade_calculator.dart';
import '../services/student_manager.dart';
import 'student_result_screen.dart';

/// Screen for manually entering student data (name, CA score, test score).
///
/// The user first selects the number of students, then enters each student's
/// name and scores. Total score is computed automatically.
class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({Key? key}) : super(key: key);

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  int _numberOfStudents = 5;
  bool _showEntryForm = false;
  bool _isCalculating = false;

  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _caControllers = [];
  final List<TextEditingController> _testControllers = [];
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    for (var c in _nameControllers) {
      c.dispose();
    }
    for (var c in _caControllers) {
      c.dispose();
    }
    for (var c in _testControllers) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _setupControllers() {
    // Dispose old controllers
    for (var c in _nameControllers) {
      c.dispose();
    }
    for (var c in _caControllers) {
      c.dispose();
    }
    for (var c in _testControllers) {
      c.dispose();
    }

    _nameControllers.clear();
    _caControllers.clear();
    _testControllers.clear();

    // Create new controllers
    for (int i = 0; i < _numberOfStudents; i++) {
      _nameControllers.add(TextEditingController());
      _caControllers.add(TextEditingController());
      _testControllers.add(TextEditingController());
    }
  }

  void _proceedToEntry() {
    setState(() {
      _showEntryForm = true;
      _setupControllers();
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter student name';
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

    // Build Student objects from form data using lambda-style map
    final students = List.generate(_numberOfStudents, (i) {
      final name = _nameControllers[i].text.trim();
      final ca = double.parse(_caControllers[i].text);
      final test = double.parse(_testControllers[i].text);
      return Student(name: name, caScore: ca, testScore: test);
    });

    // Use StudentManager with GradeCalculator (OOP + Interface + Higher-order)
    final manager = StudentManager(gradeStrategy: GradeCalculator());
    manager.setStudents(students);
    manager.calculateAllGrades();

    // Get statistics using lambda-powered method
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
                  child: _showEntryForm
                      ? _buildEntryForm()
                      : _buildStudentCountSelector(),
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
                onPressed: () {
                  if (_showEntryForm) {
                    setState(() => _showEntryForm = false);
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  _showEntryForm ? 'Enter Student Data' : 'Manual Entry',
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
            _showEntryForm
                ? 'Enter name, CA score, and test score for each student'
                : 'Select the number of students',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCountSelector() {
    return Column(
      children: [
        PremiumCard(
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
                      Icons.people,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Number of Students',
                    style: TextStyle(
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
                    if (_numberOfStudents > 1) {
                      setState(() => _numberOfStudents--);
                    }
                  }),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$_numberOfStudents',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryStart,
                          ),
                        ),
                        Text(
                          'students',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCountButton(Icons.add, () {
                    if (_numberOfStudents < 50) {
                      setState(() => _numberOfStudents++);
                    }
                  }),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [5, 10, 15, 20, 30].map((count) {
                  final isSelected = _numberOfStudents == count;
                  return ChoiceChip(
                    label: Text('$count'),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _numberOfStudents = count),
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
        ),
        const SizedBox(height: 24),
        GradientButton(
          text: 'Continue',
          icon: Icons.arrow_forward,
          width: double.infinity,
          onPressed: _proceedToEntry,
        ),
      ],
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

  Widget _buildEntryForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          const SizedBox(height: 20),
          // Student entry cards
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
              for (var c in _caControllers) {
                c.clear();
              }
              for (var c in _testControllers) {
                c.clear();
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
          _caControllers[i].text.isNotEmpty &&
          _testControllers[i].text.isNotEmpty) {
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
        ],
      ),
    );
  }

  Widget _buildStudentCard(int index) {
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
                      '${index + 1}',
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
                  'Student ${index + 1}',
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
              controller: _nameControllers[index],
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
            // CA and Test score in a row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _caControllers[index],
                    validator: _validateScore,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'CA Score',
                      hintText: '0-100',
                      prefixIcon: const Icon(
                        Icons.assignment,
                        color: AppTheme.primaryStart,
                        size: 20,
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _testControllers[index],
                    validator: _validateScore,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Test Score',
                      hintText: '0-100',
                      prefixIcon: const Icon(
                        Icons.quiz,
                        color: AppTheme.primaryStart,
                        size: 20,
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
                ),
              ],
            ),
            // Show computed total if both scores are entered
            if (_caControllers[index].text.isNotEmpty &&
                _testControllers[index].text.isNotEmpty)
              Builder(
                builder: (_) {
                  final ca = double.tryParse(_caControllers[index].text);
                  final test = double.tryParse(_testControllers[index].text);
                  if (ca != null && test != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryStart.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.functions,
                              color: AppTheme.primaryStart,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Total: ${(ca + test).toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryStart,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }
}
