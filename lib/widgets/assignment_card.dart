import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'package:lms/models/faculty/assignment_model.dart';

/// A small card showing basic info about one assignment:
/// its title, its course, its due date, and its current status.
class AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;

  const AssignmentCard({super.key, required this.assignment});

  /// Picks a color to represent the assignment's status.
  Color _statusColor() {
    switch (assignment.status) {
      case AssignmentStatus.pending:
        return AppColors.statusAmber;
      case AssignmentStatus.submitted:
        return AppColors.statusOrange;
      case AssignmentStatus.graded:
        return AppColors.statusGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assignment.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(assignment.courseName, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  assignment.status.name,
                  style: TextStyle(color: _statusColor(), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
