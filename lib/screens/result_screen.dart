import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_card.dart';
import '../models/subject.dart';
import '../models/grade_result.dart';
import 'home_screen.dart';

/// Beautiful animated result screen
class ResultScreen extends StatefulWidget {
  final List<Subject> subjects;
  final GradeResult result;
  final Map<String, dynamic> statistics;

  const ResultScreen({
    Key? key,
    required this.subjects,
    required this.result,
    required this.statistics,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradeAnimController;
  late AnimationController _statsAnimController;
  late Animation<double> _gradeScaleAnimation;
  late Animation<double> _gradeFadeAnimation;
  late Animation<double> _statsSlideAnimation;

  @override
  void initState() {
    super.initState();

    _gradeAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _statsAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _gradeScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradeAnimController, curve: Curves.elasticOut),
    );

    _gradeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _gradeAnimController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _statsSlideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _statsAnimController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _gradeAnimController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _statsAnimController.forward();
    });
  }

  @override
  void dispose() {
    _gradeAnimController.dispose();
    _statsAnimController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _calculateAgain() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildGradeCard(),
                const SizedBox(height: 24),
                _buildStatsSection(),
                const SizedBox(height: 24),
                _buildSubjectBreakdown(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.primaryStart,
              size: 20,
            ),
          ),
        ),
        const Expanded(
          child: Text(
            'Your Result',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildGradeCard() {
    return AnimatedBuilder(
      animation: _gradeAnimController,
      builder: (context, child) {
        return Transform.scale(
          scale: _gradeScaleAnimation.value,
          child: Opacity(opacity: _gradeFadeAnimation.value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.result.color.withOpacity(0.9), widget.result.color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: widget.result.color.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            // Trophy/Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.result.icon, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            // Grade letter
            Text(
              widget.result.grade,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            // Average
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Average: ${widget.result.average.toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Remark
            Text(
              widget.result.remark,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return AnimatedBuilder(
      animation: _statsAnimController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _statsSlideAnimation.value),
          child: Opacity(opacity: _statsAnimController.value, child: child),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              title: 'Highest',
              value:
                  '${(widget.statistics['highest'] as double).toStringAsFixed(1)}',
              icon: Icons.arrow_upward,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              title: 'Lowest',
              value:
                  '${(widget.statistics['lowest'] as double).toStringAsFixed(1)}',
              icon: Icons.arrow_downward,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              title: 'Total',
              value:
                  '${(widget.statistics['total'] as double).toStringAsFixed(0)}',
              icon: Icons.functions,
              color: AppTheme.primaryStart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdown() {
    return AnimatedBuilder(
      animation: _statsAnimController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _statsSlideAnimation.value),
          child: Opacity(opacity: _statsAnimController.value, child: child),
        );
      },
      child: PremiumCard(
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
                    Icons.list_alt,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Subject Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...widget.subjects.asMap().entries.map((entry) {
              final index = entry.key;
              final subject = entry.value;
              final marks = subject.marks ?? 0;
              final percentage = marks / 100;

              return _buildSubjectRow(
                index + 1,
                subject.name,
                marks,
                percentage,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectRow(
    int number,
    String name,
    double marks,
    double percentage,
  ) {
    Color barColor;
    if (marks >= 80) {
      barColor = AppTheme.accentColor;
    } else if (marks >= 60) {
      barColor = AppTheme.primaryStart;
    } else if (marks >= 50) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: barColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${marks.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        GradientButton(
          text: 'Calculate Again',
          icon: Icons.refresh,
          width: double.infinity,
          onPressed: _calculateAgain,
        ),
        const SizedBox(height: 12),
        OutlinedGradientButton(
          text: 'Back to Home',
          icon: Icons.home,
          onPressed: _goHome,
        ),
      ],
    );
  }
}
