// File: lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/todo.dart'; 
import 'notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get todosCollection => _firestore.collection('todos');
  
  /// Menambahkan todo baru ke Firestore
  /// Mengembalikan ID dokumen yang baru dibuat
  /// Throws error jika gagal menyimpan ke database
  Future<String> addTodo(Todo todo) async {
    try {
      // Create document with generated ID and save the id inside the document
      DocumentReference docRef = todosCollection.doc();
      final data = todo.toMap();
      data['id'] = docRef.id;
      await docRef.set(data);

      // Schedule local notifications for this todo
      final savedTodo = Todo.fromMap(docRef.id, data);
      try {
        await NotificationService().scheduleForTodo(savedTodo);
      } catch (e) {
        if (kDebugMode) print('Failed to schedule notification: $e');
      }

      // Show immediate feedback notification for create
      try {
        await NotificationService().showImmediateNotification(
          'Todo Dibuat',
          '${savedTodo.title} telah ditambahkan',
        );
      } catch (e) {
        if (kDebugMode) print('Failed to show create notification: $e');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('Error adding todo: $e');
      rethrow;
    }
  }
  
  /// Update todo yang sudah ada di Firestore
  /// Semua field akan diganti dengan data baru dari parameter todo
  /// Throws error jika ID tidak ditemukan atau gagal update
  Future<void> updateTodo(Todo todo) async {
    try {
      await todosCollection.doc(todo.id).update(todo.toMap());

      // Reschedule notifications to reflect updated due date / title
      try {
        await NotificationService().scheduleForTodo(todo);
      } catch (e) {
        if (kDebugMode) print('Failed to reschedule notification: $e');
      }
      // immediate notification about update
      try {
        await NotificationService().showImmediateNotification(
          'Todo Diperbarui',
          '${todo.title} berhasil diperbarui',
        );
      } catch (e) {
        if (kDebugMode) print('Failed to show update notification: $e');
      }
    } catch (e) {
      if (kDebugMode) print('Error updating todo: $e');
      rethrow;
    }
  }
  
  /// Menghapus todo dari Firestore berdasarkan ID
  /// Operasi tidak bisa dibatalkan setelah dikonfirmasi
  Future<void> deleteTodo(String todoId) async {
    try {
      // Cancel notifications for this todo, then delete
      try {
        await NotificationService().cancelForTodoId(todoId);
      } catch (e) {
        if (kDebugMode) print('Failed to cancel notifications: $e');
      }

      await todosCollection.doc(todoId).delete();

      // immediate notification about delete
      try {
        await NotificationService().showImmediateNotification(
          'Todo Dihapus',
          'Todo dengan ID $todoId telah dihapus',
        );
      } catch (e) {
        if (kDebugMode) print('Failed to show delete notification: $e');
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting todo: $e');
      rethrow;
    }
  }
  
  /// Stream yang mendengarkan semua todo milik user tertentu
  /// Otomatis di-sort di client-side karena Firestore composite index requirement
  /// Mengembalikan List<Todo> yang sudah di-sort dari terbaru (createdAt DESC)
  /// Real-time: update otomatis saat ada perubahan di Firestore
  Stream<List<Todo>> getTodos(String userId) {
    return todosCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          List<Todo> todos = snapshot.docs.map((doc) {
            return Todo.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();
          
          // Sort di client side (createdAt DESC) untuk menghindari composite index requirement
          todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return todos;
        });
  }
  
  // TAMBAHKAN METHOD INI untuk Stats Screen
  Future<Map<String, dynamic>> getTodoStats(String userId) async {
    try {
      QuerySnapshot snapshot = await todosCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      List<Todo> todos = snapshot.docs.map((doc) {
        return Todo.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      int total = todos.length;
      int completed = todos.where((todo) => todo.isCompleted).length;
      double percentage = total > 0 ? (completed / total * 100) : 0;
      
      // Hitung berdasarkan prioritas
      int highPriority = todos.where((todo) => todo.priority == 'high').length;
      int mediumPriority = todos.where((todo) => todo.priority == 'medium').length;
      int lowPriority = todos.where((todo) => todo.priority == 'low').length;
      
      // Hitung yang hampir deadline (kurang dari 3 hari)
      DateTime now = DateTime.now();
      DateTime threeDaysLater = now.add(const Duration(days: 3));
      int nearingDeadline = todos.where((todo) => 
        !todo.isCompleted && 
        todo.dueDate.isAfter(now) && 
        todo.dueDate.isBefore(threeDaysLater)
      ).length;
      
      return {
        'total': total,
        'completed': completed,
        'percentage': percentage,
        'highPriority': highPriority,
        'mediumPriority': mediumPriority,
        'lowPriority': lowPriority,
        'nearingDeadline': nearingDeadline,
      };
    } catch (e) {
      if (kDebugMode) print('Error getting stats: $e');
      return {
        'total': 0,
        'completed': 0,
        'percentage': 0.0,
        'highPriority': 0,
        'mediumPriority': 0,
        'lowPriority': 0,
        'nearingDeadline': 0,
      };
    }
  }
}