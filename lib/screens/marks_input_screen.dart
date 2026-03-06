import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_text_field.dart';
import '../models/subject.dart';
import '../services/grade_calculator_service.dart';
import 'result_screen.dart';

/// Screen for entering marks for each subject
class MarksInputScreen extends StatefulWidget {
  final List<Subject> subjects;

  const MarksInputScreen({Key? key, required this.subjects}) : super(key: key);

  @override
  State<MarksInputScreen> createState() => _MarksInputScreenState();
}

class _MarksInputScreenState extends State<MarksInputScreen> {
  late List<TextEditingController> _marksControllers;
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _marksControllers = List.generate(
      widget.subjects.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (var controller in _marksControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _calculateGrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCalculating = true);

    // Small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 500));

    // Update subjects with marks
    final subjectsWithMarks = <Subject>[];
    for (int i = 0; i < widget.subjects.length; i++) {
      final marks = double.parse(_marksControllers[i].text);
      subjectsWithMarks.add(widget.subjects[i].copyWith(marks: marks));
    }

    // Calculate grade
    final result = GradeCalculatorService.calculateGrade(subjectsWithMarks);
    final stats = GradeCalculatorService.getStatistics(subjectsWithMarks);

    setState(() => _isCalculating = false);

    if (!mounted) return;

    // Navigate to result screen
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ResultScreen(
          subjects: subjectsWithMarks,
          result: result,
          statistics: stats,
        ),
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

  void _resetAll() {
    for (var controller in _marksControllers) {
      controller.clear();
    }
    setState(() {});
  }

  String? _validateMarks(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter marks';
    }
    final marks = double.tryParse(value);
    if (marks == null) {
      return 'Invalid number';
    }
    if (marks < 0 || marks > 100) {
      return 'Marks must be 0-100';
    }
    return null;
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressIndicator(),
                        const SizedBox(height: 20),
                        _buildMarksList(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
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
                  'Enter Marks',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _resetAll,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Reset all',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Enter marks for each subject (0-100)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    int filledCount = _marksControllers
        .where((c) => c.text.isNotEmpty && double.tryParse(c.text) != null)
        .length;
    double progress = filledCount / _marksControllers.length;

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
                '$filledCount/${_marksControllers.length} completed',
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppTheme.accentColor, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'All marks entered! Ready to calculate.',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarksList() {
    return Column(
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
                Icons.assignment,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Subject Marks (${widget.subjects.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(
          widget.subjects.length,
          (index) => MarksTextField(
            controller: _marksControllers[index],
            subjectName: widget.subjects[index].name,
            index: index,
            validator: _validateMarks,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        GradientButton(
          text: 'Calculate Grade',
          icon: Icons.calculate,
          width: double.infinity,
          isLoading: _isCalculating,
          onPressed: _calculateGrade,
        ),
        const SizedBox(height: 16),
        OutlinedGradientButton(
          text: 'Clear All',
          icon: Icons.clear_all,
          onPressed: _resetAll,
        ),
      ],
    );
  }
}
