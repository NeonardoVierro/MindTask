import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:todo_list_app/services/auth_service.dart';
import 'package:todo_list_app/services/firestore_service.dart';
import 'package:todo_list_app/models/todo.dart';

class AddEditTodoScreen extends StatefulWidget {
  final Todo? todo;
  
  AddEditTodoScreen({this.todo});
  
  @override
  _AddEditTodoScreenState createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends State<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _dueDate;
  String _priority = 'medium';
  List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'Kerja', 'Pribadi', 'Belanja', 'Kesehatan', 'Olahraga', 'Pendidikan'
  ];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.todo?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.todo?.description ?? '',
    );
    _dueDate = widget.todo?.dueDate ?? DateTime.now().add(Duration(days: 1));
    _priority = widget.todo?.priority ?? 'medium';
    _selectedTags = widget.todo?.tags ?? [];
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  /// Date picker untuk memilih due date
  /// initialDate = current dueDate atau besok (untuk todo baru)
  /// lastDate = 1 tahun ke depan
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (picked != null && picked != _dueDate) {
      // preserve existing time (hour/minute)
      setState(() => _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _dueDate.hour,
            _dueDate.minute,
          ));
    }
  }

  /// Time picker untuk memilih jam dan menit
  Future<void> _selectTime() async {
    final TimeOfDay initial = TimeOfDay(hour: _dueDate.hour, minute: _dueDate.minute);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        _dueDate = DateTime(
          _dueDate.year,
          _dueDate.month,
          _dueDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }
  
  /// Simpan atau update todo ke Firestore
  /// Cek validation form terlebih dahulu
  /// Jika widget.todo == null → create baru, else → update existing
  /// Ambil userId dari currentUser untuk filter Firestore query
  Future<void> _saveTodo() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final user = authService.getCurrentUser();
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda harus login terlebih dahulu')),
        );
        return;
      }
      
      // Build Todo object dengan data dari form
      Todo todo = Todo(
        id: widget.todo?.id ?? '',  // Empty string untuk create, existing ID untuk update
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        isCompleted: widget.todo?.isCompleted ?? false,
        createdAt: widget.todo?.createdAt ?? DateTime.now(),
        userId: user.uid,  // User ID untuk memfilter todo di Firestore
        priority: _priority,
        tags: _selectedTags,
      );
      
      try {
        if (widget.todo == null) {
          // Create: tambah todo baru
          await firestoreService.addTodo(todo);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tugas berhasil ditambahkan')),
          );
        } else {
          // Update: perbarui todo existing
          await firestoreService.updateTodo(todo);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tugas berhasil diperbarui')),
          );
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan tugas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo == null ? 'Tambah Tugas Baru' : 'Edit Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveTodo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Tugas *',
                  prefixIcon: const Icon(Icons.title),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              
              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              SizedBox(height: 20),
              
              // Due Date and Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal Jatuh Tempo',
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd MMMM yyyy').format(_dueDate)),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Waktu',
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('HH:mm').format(_dueDate)),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Priority
              Text(
                'Prioritas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Rendah'),
                      selected: _priority == 'low',
                      selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                      onSelected: (selected) {
                        setState(() => _priority = 'low');
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Sedang'),
                      selected: _priority == 'medium',
                      selectedColor: const Color(0xFFF59E0B).withOpacity(0.2),
                      onSelected: (selected) {
                        setState(() => _priority = 'medium');
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Tinggi'),
                      selected: _priority == 'high',
                      selectedColor: const Color(0xFFEF4444).withOpacity(0.2),
                      onSelected: (selected) {
                        setState(() => _priority = 'high');
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Tags
              Text(
                'Tag',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  return FilterChip(
                    label: Text(tag),
                    selected: _selectedTags.contains(tag),
                    selectedColor: const Color(0xFF7C3AED).withOpacity(0.18),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 30),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTodo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.todo == null ? 'TAMBAH TUGAS' : 'UPDATE TUGAS',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}