import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_card.dart';
import '../models/subject.dart';
import 'marks_input_screen.dart';

/// Screen for setting up subjects (number and names)
class SubjectSetupScreen extends StatefulWidget {
  const SubjectSetupScreen({Key? key}) : super(key: key);

  @override
  State<SubjectSetupScreen> createState() => _SubjectSetupScreenState();
}

class _SubjectSetupScreenState extends State<SubjectSetupScreen> {
  int _numberOfSubjects = 5;
  final List<TextEditingController> _nameControllers = [];
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  void _updateControllers() {
    // Add or remove controllers based on number of subjects
    while (_nameControllers.length < _numberOfSubjects) {
      _nameControllers.add(
        TextEditingController(text: 'Subject ${_nameControllers.length + 1}'),
      );
    }
    while (_nameControllers.length > _numberOfSubjects) {
      _nameControllers.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onSubjectCountChanged(int newCount) {
    setState(() {
      _numberOfSubjects = newCount;
      _updateControllers();
    });
  }

  void _proceed() {
    if (_formKey.currentState!.validate()) {
      final subjects = _nameControllers
          .map((controller) => Subject(name: controller.text.trim()))
          .toList();

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MarksInputScreen(subjects: subjects),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
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
                        _buildSubjectCountSelector(),
                        const SizedBox(height: 24),
                        _buildSubjectNamesList(),
                        const SizedBox(height: 24),
                        _buildProceedButton(),
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
                  'Setup Subjects',
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
          const SizedBox(height: 12),
          Text(
            'Choose the number of subjects and name them',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCountSelector() {
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
                child: const Icon(
                  Icons.format_list_numbered,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Number of Subjects',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Subject count slider
          Row(
            children: [
              _buildCountButton(Icons.remove, () {
                if (_numberOfSubjects > 1) {
                  _onSubjectCountChanged(_numberOfSubjects - 1);
                }
              }),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_numberOfSubjects',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryStart,
                      ),
                    ),
                    Text(
                      'subjects',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCountButton(Icons.add, () {
                if (_numberOfSubjects < 15) {
                  _onSubjectCountChanged(_numberOfSubjects + 1);
                }
              }),
            ],
          ),
          const SizedBox(height: 16),
          // Quick select chips
          Wrap(
            spacing: 10,
            children: [3, 5, 6, 8, 10].map((count) {
              final isSelected = _numberOfSubjects == count;
              return ChoiceChip(
                label: Text('$count'),
                selected: isSelected,
                onSelected: (_) => _onSubjectCountChanged(count),
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

  Widget _buildSubjectNamesList() {
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
              child: const Icon(Icons.edit_note, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Text(
              'Subject Names',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(
          _numberOfSubjects,
          (index) => _buildSubjectNameField(index),
        ),
      ],
    );
  }

  Widget _buildSubjectNameField(int index) {
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
              controller: _nameControllers[index],
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.normal,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject name';
                }
                return null;
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
            onPressed: () {
              _nameControllers[index].clear();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton() {
    return GradientButton(
      text: 'Continue to Enter Marks',
      icon: Icons.arrow_forward,
      width: double.infinity,
      onPressed: _proceed,
    );
  }
}
