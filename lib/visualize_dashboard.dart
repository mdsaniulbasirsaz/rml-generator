import 'package:flutter/material.dart';
import 'api/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class VisualizeDashboardPage extends StatefulWidget {
  const VisualizeDashboardPage({super.key});

  @override
  State<VisualizeDashboardPage> createState() => _VisualizeDashboardPageState();
}

class _VisualizeDashboardPageState extends State<VisualizeDashboardPage> {
  final ApiService _apiService = ApiService();

  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<dynamic>> _studentsFuture;
  late Future<List<dynamic>> _tasksFuture;

  final List<String> _statuses = [
    'backlog',
    'pending',
    'in_progress',
    'review',
    'testing',
    'done',
    'archived'
  ];

  final Map<String, Color> _statusColors = {
    'backlog': Colors.grey,
    'pending': Colors.blue,
    'in_progress': Colors.orange,
    'review': Colors.purple,
    'testing': Colors.cyan,
    'done': Colors.green,
    'archived': Colors.blueGrey,
  };

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _statsFuture = _apiService.getTaskStatistics();
      _studentsFuture = _apiService.getStudents(limit: 20); // More students for chart
      _tasksFuture = _apiService.getTasks();
    });
  }

  // Helper: Count tasks by status for a specific student
  Map<String, int> _countTasksByStatusForStudent(List<dynamic> tasks, String studentId) {
    final Map<String, int> counts = {for (var s in _statuses) s: 0};
    for (var task in tasks) {
      final assignedId = task['assigned_student_id']?.toString();
      final status = task['status']?.toString() ?? 'pending';
      if (assignedId == studentId && counts.containsKey(status)) {
        counts[status] = (counts[status] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualize Dashboard'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 2,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Global Task Distribution (Unchanged) ===
              const Text('Task Distribution by Status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildErrorWidget('Error loading statistics: ${snapshot.error}');
                  }

                  final data = snapshot.data ?? {};
                  final byStatus = (data['by_status'] as Map<String, dynamic>?) ?? {};
                  final total = (data['total'] as num?)?.toDouble() ?? 1;
                  final overdue = (data['overdue'] as num?)?.toInt() ?? 0;
                  final maxY = total > 0 ? total * 1.3 : 10;

                  return Column(
                    children: [
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            height: 300,
                            child: BarChart(
                              BarChartData(
                                maxY: maxY.toDouble(),
                                barTouchData: _barTouchData,
                                titlesData: _titlesData,
                                gridData: const FlGridData(show: true),
                                borderData: FlBorderData(show: false),
                                barGroups: _statuses.asMap().entries.map((e) {
                                  final index = e.key;
                                  final status = e.value;
                                  final count = (byStatus[status] ?? 0).toDouble();
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: count,
                                        color: _statusColors[status],
                                        width: 28,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: maxY.toDouble(),
                                          color: Colors.grey.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      if (overdue > 0)
                        Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber, color: Colors.red),
                                const SizedBox(width: 12),
                                Text('$overdue task(s) are overdue', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _statuses.map((status) {
                          final count = byStatus[status] ?? 0;
                          return _buildStatusChip(status, count);
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 50),

              // === NEW: Tasks per Student Bar Chart ===
              const Text('Tasks per Student', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Each bar represents one student\'s task distribution', style: TextStyle(color: Colors.grey)),

              const SizedBox(height: 20),

              FutureBuilder<List<dynamic>>(
                future: Future.wait([_studentsFuture, _tasksFuture]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _buildErrorWidget('Failed to load student task data');
                  }

                  final students = snapshot.data![0] as List<dynamic>;
                  final tasks = snapshot.data![1] as List<dynamic>;

                  if (students.isEmpty) {
                    return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No students available')));
                  }

                  return SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final studentId = (student['_id'] ?? student['id']).toString();
                        final studentName = student['name'] ?? 'Unknown';

                        final statusCounts = _countTasksByStatusForStudent(tasks, studentId);
                        final maxStudentTasks = statusCounts.values.fold(0, (a, b) => a + b);
                        final maxY = maxStudentTasks > 0 ? (maxStudentTasks * 1.4).toDouble() : 5;

                        return Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: SizedBox(
                            width: 300,
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Total: $maxStudentTasks tasks',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: BarChart(
                                        BarChartData(
                                          maxY: maxY.toDouble(),
                                          titlesData: FlTitlesData(
                                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          ),
                                          gridData: const FlGridData(show: false),
                                          borderData: FlBorderData(show: false),
                                          barGroups: _statuses.asMap().entries.map((e) {
                                            final status = e.value;
                                            final count = (statusCounts[status] ?? 0).toDouble();
                                            return BarChartGroupData(
                                              x: e.key,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: count,
                                                  color: _statusColors[status],
                                                  width: 20,
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                          barTouchData: BarTouchData(
                                            enabled: true,
                                            touchTooltipData: BarTouchTooltipData(
                                              getTooltipColor: (_) => Colors.black87,
                                              getTooltipItem: (group, _, rod, __) {
                                                final status = _statuses[group.x];
                                                return BarTooltipItem(
                                                  '${status.replaceAll('_', ' ').toTitleCase()}: ${rod.toY.toInt()}',
                                                  const TextStyle(color: Colors.white),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // === Recent Students List (Unchanged) ===
              const Text('Recent Students', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              FutureBuilder<List<dynamic>>(
                future: _studentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
                  if (snapshot.hasError) return _buildErrorWidget('Failed to load students');
                  final students = snapshot.data ?? [];
                  if (students.isEmpty) return const Text('No students found');

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    itemBuilder: (_, i) {
                      final s = students[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(
                              (s['name']?[0] ?? 'S').toString().toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(s['name'] ?? 'Unknown Student'),
                          subtitle: Text(s['email'] ?? 'No email'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, int count) {
    return Chip(
      backgroundColor: _statusColors[status]!.withOpacity(0.15),
      label: Text('$count ${status.replaceAll('_', ' ').toTitleCase()}'),
      avatar: CircleAvatar(
        backgroundColor: _statusColors[status],
        child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildErrorWidget(String msg) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(msg, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
      ),
    );
  }

  BarTouchData get _barTouchData => BarTouchData(
    enabled: true,
    touchTooltipData: BarTouchTooltipData(
      getTooltipColor: (_) => Colors.black87,
      tooltipRoundedRadius: 12,
      tooltipPadding: const EdgeInsets.all(10),
      getTooltipItem: (group, _, rod, __) {
        final status = _statuses[group.x];
        return BarTooltipItem(
          '${status.replaceAll('_', ' ').toTitleCase()}\n${rod.toY.toInt()} tasks',
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        );
      },
    ),
  );

  FlTitlesData get _titlesData => FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 50,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < 0 || index >= _statuses.length) return const SizedBox();
          final status = _statuses[index];
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              status.replaceAll('_', '\n').toTitleCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    ),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}

extension StringX on String {
  String toTitleCase() => split(' ')
      .map((word) => word.isEmpty
          ? ''
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}