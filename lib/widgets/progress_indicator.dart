import 'package:flutter/material.dart';
import 'package:todo_list_app/models/todo.dart';

class TodoProgressIndicator extends StatelessWidget {
  final List<Todo> todos;

  const TodoProgressIndicator({super.key, required this.todos});

  @override
  Widget build(BuildContext context) {
    final total = todos.length;
    final completed = todos.where((todo) => todo.isCompleted).length;
    final progress = total > 0 ? completed / total : 0.0;
    final percentage = progress * 100;

    // Deadline checker
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));
    final nearingDeadline = todos.where((todo) =>
        !todo.isCompleted &&
        todo.dueDate.isAfter(now) &&
        todo.dueDate.isBefore(threeDaysLater)).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Harian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 12),

          /// 🔵 Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                _getProgressColor(percentage),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% selesai',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '$completed / $total tugas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          if (nearingDeadline > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '$nearingDeadline tugas mendekati deadline',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 30) return Colors.red;
    if (percentage < 70) return Colors.orange;
    return Colors.green;
  }
}
