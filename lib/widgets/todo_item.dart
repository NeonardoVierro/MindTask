import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todo_list_app/models/todo.dart';
import 'package:todo_list_app/services/firestore_service.dart';
import 'package:todo_list_app/screens/add_edit_todo_screen.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  
  TodoItem({required this.todo});
  
  /// Map string prioritas ke Color untuk left border strip
  /// high (merah) = #EF4444
  /// medium (amber) = #F59E0B
  /// low (hijau) = #10B981
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return const Color(0xFFEF4444);
      case 'medium': return const Color(0xFFF59E0B);
      case 'low': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }
  
  /// Convert prioritas code (high/medium/low) ke text Indonesia
  /// Digunakan untuk menampilkan label prioritas di UI
  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high': return 'Tinggi';
      case 'medium': return 'Sedang';
      case 'low': return 'Rendah';
      default: return '-';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            // Left colored priority strip
            Container(
              width: 6,
              height: 96,
              decoration: BoxDecoration(
                color: _getPriorityColor(todo.priority),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Transform.scale(
                  scale: 1.15,
                  child: Checkbox(
                    value: todo.isCompleted,
                    onChanged: (value) async {
                      // Update status completion, sync ke Firestore
                      Todo updatedTodo = Todo(
                        id: todo.id,
                        title: todo.title,
                        description: todo.description,
                        dueDate: todo.dueDate,
                        isCompleted: value ?? false,  // Toggle checkbox state
                        createdAt: todo.createdAt,
                        userId: todo.userId,
                        priority: todo.priority,
                        tags: todo.tags,
                      );
                      await firestoreService.updateTodo(updatedTodo);
                    },
                  ),
                ),
                title: Text(
                  todo.title,
                  style: TextStyle(
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w700,
                    color: todo.isCompleted ? Colors.grey : Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (todo.description.isNotEmpty)
                      Text(
                        todo.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          color: Colors.grey[700],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM yyyy').format(todo.dueDate),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(todo.priority).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _getPriorityColor(todo.priority).withOpacity(0.22)),
                          ),
                          child: Text(
                            _getPriorityText(todo.priority),
                            style: TextStyle(fontSize: 11, color: _getPriorityColor(todo.priority), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (todo.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          children: todo.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              labelStyle: const TextStyle(fontSize: 11),
                              backgroundColor: Colors.grey.shade100,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditTodoScreen(todo: todo),
                        ),
                      );
                    } else if (value == 'delete') {
                      bool confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Konfirmasi Hapus'),
                          content: const Text('Apakah Anda yakin ingin menghapus tugas ini?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await firestoreService.deleteTodo(todo.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tugas berhasil dihapus')),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}