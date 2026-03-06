import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../models/student.dart';
import '../services/excel_handler.dart';
import '../services/pdf_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Result screen showing all student grades with statistics and export options.
///
/// Displays:
/// - Student table with name, CA, test, total, grade, and remark
/// - Per-subject score breakdown (expandable) when multiple subjects
/// - Class statistics (highest, lowest, average, pass/fail counts)
/// - Grade distribution bar chart
/// - Export buttons: Download Excel (with Grade column), Download PDF
class StudentResultScreen extends StatefulWidget {
  final List<Student> students;
  final Map<String, dynamic> statistics;

  const StudentResultScreen({
    Key? key,
    required this.students,
    required this.statistics,
  }) : super(key: key);

  @override
  State<StudentResultScreen> createState() => _StudentResultScreenState();
}

class _StudentResultScreenState extends State<StudentResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;
  final Set<int> _expandedStudents = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final path = await ExcelHandler.writeStudentsToExcel(widget.students);
      setState(() => _isExporting = false);
      if (!mounted) return;
      _showExportDialog('Excel Exported', path, 'xlsx');
    } catch (e) {
      setState(() => _isExporting = false);
      if (!mounted) return;
      _showErrorSnackbar('Failed to export Excel: $e');
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final path = await PdfHandler.generateReport(widget.students);
      setState(() => _isExporting = false);
      if (!mounted) return;
      _showExportDialog('PDF Generated', path, 'pdf');
    } catch (e) {
      setState(() => _isExporting = false);
      if (!mounted) return;
      _showErrorSnackbar('Failed to generate PDF: $e');
    }
  }

  void _showExportDialog(String title, String filePath, String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              type == 'pdf' ? Icons.picture_as_pdf : Icons.table_chart,
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File saved successfully!',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                filePath,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Share.shareXFiles([XFile(filePath)]);
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryStart,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStudentListTab(),
                    _buildStatisticsTab(),
                    _buildExportTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final passRate = widget.students.isNotEmpty
        ? ((widget.statistics['passCount'] as int) /
                  widget.students.length *
                  100)
              .toStringAsFixed(1)
        : '0.0';

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
                  'Grade Results',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeaderStat(
                '${widget.students.length}',
                'Students',
                Icons.people,
              ),
              _buildHeaderStat('$passRate%', 'Pass Rate', Icons.trending_up),
              _buildHeaderStat(
                (widget.statistics['average'] as double).toStringAsFixed(1),
                'Average',
                Icons.analytics,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Students'),
          Tab(text: 'Statistics'),
          Tab(text: 'Export'),
        ],
      ),
    );
  }

  // ─── Students Tab ─────────────────────────────────────────────────

  Widget _buildStudentListTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: widget.students.length,
      itemBuilder: (context, index) {
        final student = widget.students[index];
        return _buildStudentTile(student, index);
      },
    );
  }

  Widget _buildStudentTile(Student student, int index) {
    final isExpanded = _expandedStudents.contains(index);
    final hasSubjects = student.hasMultipleSubjects;

    return GestureDetector(
      onTap: hasSubjects
          ? () => setState(() {
              if (isExpanded) {
                _expandedStudents.remove(index);
              } else {
                _expandedStudents.add(index);
              }
            })
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
              Row(
                children: [
                  // Rank number
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Student details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildScorePill(
                              'CA: ${student.caScore.toStringAsFixed(0)}',
                            ),
                            const SizedBox(width: 6),
                            _buildScorePill(
                              'Test: ${student.testScore.toStringAsFixed(0)}',
                            ),
                            const SizedBox(width: 6),
                            _buildScorePill(
                              'Total: ${student.totalScore.toStringAsFixed(1)}',
                              highlight: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              student.gradeIcon,
                              size: 14,
                              color: student.gradeColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                student.remark,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: student.gradeColor,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Grade badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: student.gradeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        student.grade,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: student.gradeColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Expand hint for multi-subject students
              if (hasSubjects && !isExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.expand_more,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to view ${student.subjects.length} subjects',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              // Per-subject breakdown (expanded)
              if (hasSubjects && isExpanded) ...[
                const Divider(height: 24),
                ...student.subjects.map((subject) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryStart,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Text(
                            subject.subjectName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        _buildScorePill(
                          'CA: ${subject.caScore.toStringAsFixed(0)}',
                        ),
                        const SizedBox(width: 6),
                        _buildScorePill(
                          'Test: ${subject.testScore.toStringAsFixed(0)}',
                        ),
                        const SizedBox(width: 6),
                        _buildScorePill(
                          'Total: ${subject.total.toStringAsFixed(1)}',
                          highlight: true,
                        ),
                      ],
                    ),
                  );
                }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.expand_less,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to collapse',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScorePill(String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.primaryStart.withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          color: highlight ? AppTheme.primaryStart : Colors.grey.shade600,
        ),
      ),
    );
  }

  // ─── Statistics Tab ───────────────────────────────────────────────

  Widget _buildStatisticsTab() {
    final stats = widget.statistics;
    final passCount = stats['passCount'] as int;
    final failCount = stats['failCount'] as int;
    final total = widget.students.length;
    final passRate = total > 0 ? (passCount / total * 100) : 0.0;

    // Grade distribution using lambda fold
    final gradeDistribution = widget.students.fold<Map<String, int>>({}, (
      map,
      s,
    ) {
      map[s.grade] = (map[s.grade] ?? 0) + 1;
      return map;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Score overview cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Highest',
                  (stats['highest'] as double).toStringAsFixed(1),
                  Icons.arrow_upward,
                  const Color(0xFF00C853),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Lowest',
                  (stats['lowest'] as double).toStringAsFixed(1),
                  Icons.arrow_downward,
                  const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Average',
                  (stats['average'] as double).toStringAsFixed(2),
                  Icons.analytics,
                  AppTheme.primaryStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pass Rate',
                  '${passRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Passed',
                  '$passCount',
                  Icons.thumb_up,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Failed',
                  '$failCount',
                  Icons.thumb_down,
                  const Color(0xFFBF360C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Grade Distribution
          _buildGradeDistributionCard(gradeDistribution, total),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDistributionCard(Map<String, int> distribution, int total) {
    final grades = ['A', 'B+', 'B', 'C+', 'C', 'D+', 'D', 'F'];
    final gradeColors = {
      'A': const Color(0xFF00C853),
      'B+': const Color(0xFF2E7D32),
      'B': const Color(0xFF1976D2),
      'C+': const Color(0xFF0288D1),
      'C': const Color(0xFFFFA000),
      'D+': const Color(0xFFE65100),
      'D': const Color(0xFFBF360C),
      'F': const Color(0xFFD32F2F),
    };

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
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppTheme.primaryStart, size: 22),
              SizedBox(width: 10),
              Text(
                'Grade Distribution',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Lambda-powered grade bar generation
          ...grades.map((grade) {
            final count = distribution[grade] ?? 0;
            final fraction = total > 0 ? count / total : 0.0;
            final percentage = (fraction * 100).toStringAsFixed(0);
            final color = gradeColors[grade] ?? Colors.grey;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      grade,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: fraction,
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 55,
                    child: Text(
                      '$count ($percentage%)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
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

  // ─── Export Tab ───────────────────────────────────────────────────

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildExportCard(
            title: 'Export to Excel',
            description:
                'Download an Excel file (.xlsx) with all student grades, including the Grade column added automatically.',
            icon: Icons.table_chart,
            color: const Color(0xFF217346),
            onTap: _exportExcel,
          ),
          const SizedBox(height: 16),
          _buildExportCard(
            title: 'Export to PDF',
            description:
                'Generate a professional PDF report with student grades, statistics, and grade distribution chart.',
            icon: Icons.picture_as_pdf,
            color: const Color(0xFFD32F2F),
            onTap: _exportPdf,
          ),
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryStart,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('Generating file...'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
          OutlinedGradientButton(
            text: 'Back to Home',
            icon: Icons.home,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isExporting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
