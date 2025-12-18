// File: lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class StatsScreen extends StatefulWidget {
  final User? user;
  
  StatsScreen({super.key, this.user});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }
  
  Future<void> _loadStats() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.getCurrentUser();
    
    if (user != null) {
      final stats = await firestoreService.getTodoStats(user.uid);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Overall Progress
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircularPercentIndicator(
                            radius: 80,
                            lineWidth: 12,
                            percent: (_stats['percentage'] ?? 0.0) / 100,
                            center: Text(
                              '${(_stats['percentage'] ?? 0.0).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            progressColor: _getProgressColor(_stats['percentage'] ?? 0.0),
                            backgroundColor: const Color.fromARGB(255, 234, 199, 199),  // PERBAIKI: gunakan grey
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Progress Keseluruhan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_stats['completed'] ?? 0} dari ${_stats['total'] ?? 0} tugas selesai',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatCard(
                        icon: Icons.task_alt,
                        color: Colors.green,
                        title: 'Selesai',
                        value: (_stats['completed'] ?? 0).toString(),
                      ),
                      _buildStatCard(
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                        title: 'Belum Selesai',
                        value: ((_stats['total'] ?? 0) - (_stats['completed'] ?? 0)).toString(),
                      ),
                      _buildStatCard(
                        icon: Icons.priority_high,
                        color: Colors.red,
                        title: 'Prioritas Tinggi',
                        value: (_stats['highPriority'] ?? 0).toString(),
                      ),
                      _buildStatCard(
                        icon: Icons.timer,
                        color: Colors.purple,
                        title: 'Deadline Dekat',
                        value: (_stats['nearingDeadline'] ?? 0).toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Priority Distribution
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Distribusi Prioritas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildPriorityRow('Tinggi', _stats['highPriority'] ?? 0, Colors.red),
                          _buildPriorityRow('Sedang', _stats['mediumPriority'] ?? 0, Colors.orange),
                          _buildPriorityRow('Rendah', _stats['lowPriority'] ?? 0, Colors.green),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadStats,
        child: const Icon(Icons.refresh),
        mini: true,
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriorityRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
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