import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/faculty/faculty_assignment_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatters.dart';
import 'package:lms/models/faculty/question_bank_item_model.dart';
import 'package:lms/models/faculty/test_submission_model.dart';
import 'package:lms/widgets/faculty/app_drawer.dart';
import 'package:lms/widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_dropdown_field.dart';
import '../../../widgets/custom_loader.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/initials_avatar.dart';
import '../../../widgets/search_field.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_badge.dart';

const List<String> _subjects = ['Basic Electrical Wiring'];
const List<QuestionDifficulty> _difficulties = QuestionDifficulty.values;

/// The "Question Bank & Tests" screen, split into three tabs:
///   - "Add Question/Test": add a question to the bank, or schedule
///     a new online test.
///   - "Question Bank": search, browse, and edit the question bank.
///   - "Submissions": who has taken the online tests, and their
///     auto-calculated MCQ score.
class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FacultyAssignmentController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Question Bank & Tests',
        subtitle: 'Build MCQs and schedule online tests',
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'Add Question/Test'),
            Tab(text: 'Question Bank'),
            Tab(text: 'Submissions'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: Routes.facultyQuestionBank),
      body: Obx(() {
        if (controller.isLoadingQuestions.value) {
          return const CustomLoader();
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildAddTab(),
            _buildQuestionBankTab(controller),
            _buildSubmissionsTab(controller),
          ],
        );
      }),
    );
  }

  Widget _buildAddTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _AddQuestionForm(),
        SizedBox(height: 16),
        _CreateTestForm(),
      ],
    );
  }

  Widget _buildQuestionBankTab(FacultyAssignmentController controller) {
    final query = _searchQuery.trim().toLowerCase();
    final questions = controller.questions
        .where((question) => question.questionText.toLowerCase().contains(query))
        .toList();

    return RefreshIndicator(
      onRefresh: controller.loadQuestions,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchField(
            controller: _searchController,
            hint: 'Search questions',
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'My Question Bank - Basic Electrical Wiring',
            padding: EdgeInsets.zero,
            trailing: StatusBadge(
              label: '${controller.questions.length} Questions',
              type: BadgeType.info,
            ),
            child: questions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.search_off,
                      title: 'No matches',
                      message: 'No questions match that search.',
                    ),
                  )
                : Column(
                    children: [
                      for (final question in questions) _QuestionTile(question: question),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTab(FacultyAssignmentController controller) {
    return Obx(() {
      if (controller.isLoadingTestSubmissions.value) {
        return const CustomLoader();
      }

      return RefreshIndicator(
        onRefresh: controller.loadTestSubmissions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Unit Test 1 - Results',
              padding: EdgeInsets.zero,
              trailing: StatusBadge(
                label: '${controller.testSubmissions.length} Submitted',
                type: BadgeType.info,
              ),
              child: controller.testSubmissions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: EmptyStateWidget(
                        icon: Icons.quiz_outlined,
                        title: 'No submissions yet',
                        message: 'Results show up here once students take the test.',
                      ),
                    )
                  : Column(
                      children: [
                        for (final submission in controller.testSubmissions)
                          _TestSubmissionTile(submission: submission),
                      ],
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _AddQuestionForm extends StatefulWidget {
  const _AddQuestionForm();

  @override
  State<_AddQuestionForm> createState() => _AddQuestionFormState();
}

class _AddQuestionFormState extends State<_AddQuestionForm> {
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();

  // 0 = Option A, 1 = Option B, and so on.
  int _correctOptionIndex = 0;

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type the question first')),
      );
      return;
    }

    Get.find<FacultyAssignmentController>().addQuestion(
      QuestionBankItemModel(
        id: 'q-${DateTime.now().millisecondsSinceEpoch}',
        questionText: _questionController.text.trim(),
        difficulty: QuestionDifficulty.medium,
        addedOnText: formatDate(DateTime.now()),
        options: [
          _optionAController.text.trim(),
          _optionBController.text.trim(),
          _optionCController.text.trim(),
          _optionDController.text.trim(),
        ],
        correctOptionIndex: _correctOptionIndex,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question added to the bank')),
    );

    setState(() {
      _questionController.clear();
      _optionAController.clear();
      _optionBController.clear();
      _optionCController.clear();
      _optionDController.clear();
      _correctOptionIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Add Question',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _questionController,
            label: 'Question',
            hint: 'Enter question text',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          CustomTextField(controller: _optionAController, label: 'Option A'),
          const SizedBox(height: 16),
          CustomTextField(controller: _optionBController, label: 'Option B'),
          const SizedBox(height: 16),
          CustomTextField(controller: _optionCController, label: 'Option C'),
          const SizedBox(height: 16),
          CustomTextField(controller: _optionDController, label: 'Option D'),
          const SizedBox(height: 16),
          CustomDropdownField<int>(
            label: 'Correct Answer',
            value: _correctOptionIndex,
            options: const [0, 1, 2, 3],
            labelFor: (index) => 'Option ${String.fromCharCode(65 + index)}',
            onChanged: (value) => setState(() => _correctOptionIndex = value!),
          ),
          const SizedBox(height: 20),
          CustomButton(text: 'Add to Question Bank', onPressed: _addQuestion),
        ],
      ),
    );
  }
}

class _CreateTestForm extends StatefulWidget {
  const _CreateTestForm();

  @override
  State<_CreateTestForm> createState() => _CreateTestFormState();
}

class _CreateTestFormState extends State<_CreateTestForm> {
  final _testNameController = TextEditingController();
  final _questionCountController = TextEditingController(text: '25');
  final _durationController = TextEditingController(text: '60');
  String _subject = _subjects.first;
  DateTime? _scheduleDate;
  bool _randomSelection = true;

  @override
  void dispose() {
    _testNameController.dispose();
    _questionCountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickScheduleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduleDate = picked);
  }

  void _scheduleTest() {
    if (_testNameController.text.trim().isEmpty || _scheduleDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please name the test and pick a date')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_testNameController.text.trim()} scheduled for ${formatDate(_scheduleDate!)}',
        ),
      ),
    );

    setState(() {
      _testNameController.clear();
      _scheduleDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Create Online Test',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _testNameController,
            label: 'Test Name',
            hint: 'e.g. Unit Test 2',
          ),
          const SizedBox(height: 16),
          CustomDropdownField<String>(
            label: 'Subject',
            value: _subject,
            options: _subjects,
            labelFor: (option) => option,
            onChanged: (value) => setState(() => _subject = value!),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _questionCountController,
            label: 'No. of Questions',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _durationController,
            label: 'Duration (minutes)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickScheduleDate,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Schedule Date',
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                _scheduleDate == null ? 'Tap to pick a date' : formatDate(_scheduleDate!),
                style: TextStyle(
                  color: _scheduleDate == null ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          CheckboxListTile(
            value: _randomSelection,
            onChanged: (value) => setState(() => _randomSelection = value ?? true),
            title: const Text('Random Question Selection', style: TextStyle(fontSize: 13.5)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          CustomButton(text: 'Schedule Test', onPressed: _scheduleTest),
        ],
      ),
    );
  }
}

/// One question in the bank. Tapping it opens a dialog to edit its
/// text, its 4 options, which one is correct, and its difficulty.
class _QuestionTile extends StatelessWidget {
  final QuestionBankItemModel question;

  const _QuestionTile({required this.question});

  Future<void> _editQuestion(BuildContext context) async {
    final textController = TextEditingController(text: question.questionText);
    final optionControllers = [
      for (var i = 0; i < 4; i++)
        TextEditingController(text: i < question.options.length ? question.options[i] : ''),
    ];
    int correctIndex = question.correctOptionIndex;
    QuestionDifficulty difficulty = question.difficulty;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: textController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Question'),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: optionControllers[i],
                          decoration: InputDecoration(labelText: 'Option ${String.fromCharCode(65 + i)}'),
                        ),
                      ),
                    DropdownButtonFormField<int>(
                      initialValue: correctIndex,
                      decoration: const InputDecoration(labelText: 'Correct Answer'),
                      items: [
                        for (var i = 0; i < 4; i++)
                          DropdownMenuItem(value: i, child: Text('Option ${String.fromCharCode(65 + i)}')),
                      ],
                      onChanged: (value) => setDialogState(() => correctIndex = value!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<QuestionDifficulty>(
                      initialValue: difficulty,
                      decoration: const InputDecoration(labelText: 'Difficulty'),
                      items: [
                        for (final level in _difficulties)
                          DropdownMenuItem(value: level, child: Text(level.name)),
                      ],
                      onChanged: (value) => setDialogState(() => difficulty = value!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved ?? false) {
      Get.find<FacultyAssignmentController>().updateQuestion(
        question,
        questionText: textController.text.trim(),
        options: [for (final controller in optionControllers) controller.text.trim()],
        correctOptionIndex: correctIndex,
        difficulty: difficulty,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _editQuestion(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.questionText,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Added ${question.addedOnText}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _difficultyBadge(question.difficulty),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _difficultyBadge(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return const StatusBadge(label: 'Easy', type: BadgeType.neutral);
      case QuestionDifficulty.medium:
        return const StatusBadge(label: 'Medium', type: BadgeType.warning);
      case QuestionDifficulty.hard:
        return const StatusBadge(label: 'Hard', type: BadgeType.danger);
    }
  }
}

/// One student's auto-graded result for an online test.
class _TestSubmissionTile extends StatelessWidget {
  final TestSubmissionModel submission;

  const _TestSubmissionTile({required this.submission});

  BadgeType _scoreBadgeType() {
    if (submission.scorePercent >= 80) return BadgeType.success;
    if (submission.scorePercent >= 50) return BadgeType.warning;
    return BadgeType.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          InitialsAvatar(initials: submission.studentInitials),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.studentName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                Text(
                  '${submission.correctAnswers}/${submission.totalQuestions} correct',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: '${submission.scorePercent.round()}%',
            type: _scoreBadgeType(),
          ),
        ],
      ),
    );
  }
}
