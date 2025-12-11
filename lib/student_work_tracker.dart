import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rmpdf/student_add.dart';
import 'package:rmpdf/visualize_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'api/api_service.dart';

/// Jira-Style Kanban Board Student Work Tracker - Clean White Theme with Additional Columns
class StudentWorkTracker extends StatefulWidget {
  const StudentWorkTracker({super.key});

  @override
  State<StudentWorkTracker> createState() => _StudentWorkTrackerState();
}

class _StudentWorkTrackerState extends State<StudentWorkTracker> {
  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();
  List<Student> _students = [];
  List<Task> _tasks = [];
  bool _isSupervisor = true;
  String? _selectedStudentId;
  bool _isLoading = true;
  bool _isDragging = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      // Try to sync local data first
      await _storage.syncLocalData();
      
      // Load from API
      await _loadDataFromApi();
      _isOnline = true;
    } catch (e) {
      print('API Error: $e');
      _isOnline = false;
      // Fallback to local storage
      await _loadDataFromLocal();
    }
    
    if (!_isSupervisor && _students.isNotEmpty) {
      _selectedStudentId ??= _students.first.id;
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadDataFromApi() async {
    try {
      // Load students from API
      final studentsData = await _api.getStudents();
      _students = studentsData.map((json) => Student.fromApiJson(json)).toList();
      
      // Load tasks from API
      final tasksData = await _api.getTasks();
      _tasks = tasksData.map((json) => Task.fromApiJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load data from API: $e');
    }
  }

  Future<void> _loadDataFromLocal() async {
    _students = await _storage.loadStudents();
    _tasks = await _storage.loadTasks();
  }

  Future<void> _refreshData() async {
    try {
      await _loadDataFromApi();
      _isOnline = true;
      setState(() {});
    } catch (e) {
      _isOnline = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offline mode - Using cached data'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _saveTask(Task task) async {
    try {
      if (task.id.startsWith('local_')) {
        // New task - create via API
        final taskData = task.toApiJson();
        final response = await _api.createTask(taskData);
        final newTask = Task.fromApiJson(response);
        
        setState(() {
          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) _tasks[index] = newTask;
        });
      } else {
        // Existing task - update via API
        final taskData = task.toApiJson();
        final response = await _api.updateTask(task.id, taskData);
        final updatedTask = Task.fromApiJson(response);
        
        setState(() {
          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) _tasks[index] = updatedTask;
        });
      }
      
      // Save to local storage as backup
      await _storage.saveTask(task);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving task: $e');
      // Save locally as fallback
      await _storage.saveTask(task);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task saved locally (offline)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _updateTaskStatus(Task task, TaskStatus newStatus) async {
    final oldStatus = task.status;
    
    // Optimistic update
    setState(() {
      task.status = newStatus;
      if (newStatus == TaskStatus.done) {
        task.completionDate = DateTime.now();
      }
    });
    
    try {
      // Update via API
      await _api.updateTaskStatus(task.id, Task._statusToString(newStatus));
      await _storage.saveTask(task);
    } catch (e) {
      print('Error updating task status: $e');
      // Revert on failure
      setState(() {
        task.status = oldStatus;
        if (newStatus == TaskStatus.done) {
          task.completionDate = null;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status update failed - using local data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final taskToDelete = task;
    
    // Optimistic removal
    setState(() => _tasks.remove(task));
    
    try {
      // Delete via API
      await _api.deleteTask(task.id);
      await _storage.deleteTask(task.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting task: $e');
      // Re-add on failure
      setState(() => _tasks.add(taskToDelete));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete task'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onDragStarted() {
    setState(() => _isDragging = true);
  }

  void _onDragEnded() {
    setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        Colors.blue.shade700,
                      ),
                      strokeWidth: 4,
                    ),
                    Center(
                      child: Icon(
                        Icons.dashboard_rounded,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading Kanban Board...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              if (!_isOnline) ...[
                SizedBox(height: 10),
                Text(
                  'Offline Mode',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 12,
                  ),
                ),
              ]
            ],
          ),
        ),
      );
    }

    final tasksToShow = _isSupervisor
        ? _tasks
        : _tasks
            .where((t) => t.assignedStudentId == _selectedStudentId)
            .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (!_isSupervisor) _buildStudentSelector(),
          const SizedBox(height: 8),
          _buildStatsBar(),
          if (!_isOnline)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Offline Mode - Changes saved locally',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: KanbanBoard(
              tasks: tasksToShow,
              students: _students,
              isSupervisor: _isSupervisor,
              onStatusChanged: _updateTaskStatus,
              onEdit: (task) => _showTaskDialog(task: task),
              onDelete: _deleteTask,
              onDragStarted: _onDragStarted,
              onDragEnded: _onDragEnded,
            ),
          ),
        ],
      ),
      floatingActionButton: _isSupervisor
          ? AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: _isDragging ? 0 : 1,
              child: FloatingActionButton.extended(
                onPressed: () => _showTaskDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Task'),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStatsBar() {
    final inProgressCount = _tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final doneCount = _tasks.where((t) => t.status == TaskStatus.done).length;
    final overdueCount = _tasks.where((t) => t.isOverdue() && t.status != TaskStatus.done).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          Text(
            'Board Stats:',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          _buildStatItem('Total', _tasks.length.toString(), Colors.grey.shade700),
          _buildStatItem('Overdue', overdueCount.toString(), Colors.red.shade600),
          _buildStatItem('In Progress', inProgressCount.toString(), Colors.orange.shade600),
          _buildStatItem('Done', doneCount.toString(), Colors.green.shade600),
          const Spacer(),
          // Add New Student Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentDashboard(),
                  ),
                );
            },
            icon: Icon(Icons.person_add, size: 16),
            label: Text('Add New Student'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              textStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Visualize Progress Button
          ElevatedButton.icon(
            onPressed: () {
             Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VisualizeDashboardPage(),
                  ),
                );
            },
            icon: Icon(Icons.analytics, size: 16),
            label: Text('Visualize Progress'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              textStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Existing Refresh Button
          IconButton(
            icon: Icon(Icons.refresh, size: 18),
            onPressed: _refreshData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade500,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSupervisor ? 'Kanban Board' : 'Kanban Board',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_tasks.length} tasks, ${_students.length} students',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: Colors.blue.shade700,
              selectedForegroundColor: Colors.white,
              backgroundColor: Colors.transparent,
            ),
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Supervisor'),
                icon: Icon(Icons.supervisor_account, size: 16),
              ),
              ButtonSegment(
                value: false,
                label: Text('Student'),
                icon: Icon(Icons.school, size: 16),
              ),
            ],
            selected: {_isSupervisor},
            onSelectionChanged: (s) => setState(() {
              _isSupervisor = s.first;
              if (!_isSupervisor && _students.isNotEmpty) {
                _selectedStudentId ??= _students.first.id;
              }
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Viewing as:',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStudentId,
                  icon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.grey.shade600,
                  ),
                  isExpanded: true,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  items: _students
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    s.name.isNotEmpty
                                        ? s.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(s.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStudentId = v),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDialog({Task? task}) {
    showDialog(
      context: context,
      builder: (_) => TaskDialog(
        task: task,
        students: _students,
        onSave: (newTask) async {
          // If task is null, it's a new task - generate local ID
          if (task == null) {
            newTask.id = 'local_${DateTime.now().millisecondsSinceEpoch}';
          }
          
          setState(() {
            if (task == null) {
              _tasks.add(newTask);
            } else {
              final i = _tasks.indexWhere((t) => t.id == task.id);
              if (i != -1) _tasks[i] = newTask;
            }
          });
          
          await _saveTask(newTask);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ============================================================================
// ENHANCED KANBAN BOARD WITH ADDITIONAL COLUMNS
// ============================================================================

class KanbanBoard extends StatefulWidget {
  final List<Task> tasks;
  final List<Student> students;
  final bool isSupervisor;
  final Function(Task, TaskStatus) onStatusChanged;
  final Function(Task)? onEdit;
  final Function(Task)? onDelete;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  const KanbanBoard({
    super.key,
    required this.tasks,
    required this.students,
    required this.isSupervisor,
    required this.onStatusChanged,
    this.onEdit,
    this.onDelete,
    this.onDragStarted,
    this.onDragEnded,
  });

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  TaskStatus? _draggingOverStatus;
  Task? _draggedTask;

  List<Task> _tasksByStatus(TaskStatus status) {
    return widget.tasks.where((t) => t.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColumn(
            'Backlog',
            TaskStatus.backlog,
            const Color(0xFF94A3B8),
            Icons.inventory_2_outlined,
            'Tasks to be planned',
          ),
          _buildColumn(
            'To Do',
            TaskStatus.pending,
            const Color(0xFF6366F1),
            Icons.assignment_outlined,
            'Ready to start',
          ),
          _buildColumn(
            'In Progress',
            TaskStatus.inProgress,
            const Color(0xFFF59E0B),
            Icons.sync_rounded,
            'Currently working',
          ),
          _buildColumn(
            'Review',
            TaskStatus.review,
            const Color(0xFF8B5CF6),
            Icons.rate_review_outlined,
            'Awaiting review',
          ),
          _buildColumn(
            'Testing',
            TaskStatus.testing,
            const Color(0xFFEC4899),
            Icons.bug_report_outlined,
            'In testing phase',
          ),
          _buildColumn(
            'Done',
            TaskStatus.done,
            const Color(0xFF10B981),
            Icons.check_circle_outline,
            'Completed tasks',
          ),
          _buildColumn(
            'Archived',
            TaskStatus.archived,
            const Color(0xFF6B7280),
            Icons.archive_outlined,
            'Completed & archived',
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(
    String title,
    TaskStatus status,
    Color color,
    IconData icon,
    String subtitle,
  ) {
    final columnTasks = _tasksByStatus(status);
    final isDraggingOver = _draggingOverStatus == status;
    final isDragging = _draggedTask != null;

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: color.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Text(
                        columnTasks.length.toString(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Drop Zone
          Flexible(
            child: DragTarget<Task>(
              onWillAcceptWithDetails: (details) {
                final shouldAccept = details.data.status != status;
                if (shouldAccept) {
                  setState(() => _draggingOverStatus = status);
                }
                return shouldAccept;
              },
              onLeave: (details) {
                setState(() => _draggingOverStatus = null);
              },
              onAcceptWithDetails: (details) {
                setState(() {
                  _draggingOverStatus = null;
                  _draggedTask = null;
                });
                final task = details.data;
                if (task.status != status) {
                  widget.onStatusChanged(task, status);
                  widget.onDragEnded?.call();
                }
              },
              builder: (context, candidateData, rejectedData) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isDraggingOver
                        ? color.withOpacity(0.03)
                        : Colors.transparent,
                    border: isDraggingOver
                        ? Border.all(color: color, width: 2, style: BorderStyle.solid)
                        : null,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  constraints: const BoxConstraints(minHeight: 400),
                  child: Stack(
                    children: [
                      if (columnTasks.isEmpty && !isDragging)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No tasks',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Drag tasks here',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: columnTasks.length,
                          itemBuilder: (context, i) {
                            final task = columnTasks[i];
                            final student = widget.students.firstWhere(
                              (s) => s.id == task.assignedStudentId,
                              orElse: () => Student(
                                  id: '', name: 'Unknown', email: ''),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildDraggableTask(task, student),
                            );
                          },
                        ),
                      if (isDraggingOver)
                        Container(
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(0.3),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          height: 60,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, color: color, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Drop to move',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableTask(Task task, Student student) {
    return Draggable<Task>(
      data: task,
      feedback: Transform.scale(
        scale: 1.02,
        child: Material(
          elevation: 8,
          shadowColor: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 280,
            child: KanbanTaskCard(
              task: task,
              student: student,
              isSupervisor: widget.isSupervisor,
              isDragging: true,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      onDragStarted: () {
        setState(() => _draggedTask = task);
        widget.onDragStarted?.call();
      },
      onDragEnd: (details) {
        setState(() => _draggedTask = null);
        widget.onDragEnded?.call();
      },
      onDraggableCanceled: (velocity, offset) {
        setState(() => _draggedTask = null);
        widget.onDragEnded?.call();
      },
      child: KanbanTaskCard(
        task: task,
        student: student,
        isSupervisor: widget.isSupervisor,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
      ),
    );
  }

  Color get color => Colors.blue;
}

// ============================================================================
// ENHANCED KANBAN TASK CARD WITH WHITE THEME
// ============================================================================

class KanbanTaskCard extends StatelessWidget {
  final Task task;
  final Student student;
  final bool isSupervisor;
  final bool isDragging;
  final Function(Task)? onEdit;
  final Function(Task)? onDelete;

  const KanbanTaskCard({
    super.key,
    required this.task,
    required this.student,
    required this.isSupervisor,
    this.isDragging = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue();
    final priorityColor = _getPriorityColor(task.priority);
    final statusColor = _getStatusColor(task.status);

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDragging ? 0.1 : 0.03),
              blurRadius: isDragging ? 8 : 4,
              offset: Offset(0, isDragging ? 4 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSupervisor && onEdit != null ? () => onEdit!(task) : null,
            borderRadius: BorderRadius.circular(12),
            hoverColor: Colors.blue.shade50,
            splashColor: Colors.blue.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Status & Priority
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              task.status.name.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPriorityIcon(task.priority),
                              size: 10,
                              color: priorityColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.priority.name,
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Task Title
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Task Description
                  Text(
                    task.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Footer: Assignee & Due Date
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            student.name.isNotEmpty
                                ? student.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Student Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              student.email,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Due Date
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? Colors.red.shade50
                              : task.status == TaskStatus.done
                                  ? Colors.green.shade50
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isOverdue
                                ? Colors.red.shade200
                                : task.status == TaskStatus.done
                                    ? Colors.green.shade200
                                    : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              task.status == TaskStatus.done
                                  ? Icons.check_circle_rounded
                                  : Icons.schedule_rounded,
                              size: 12,
                              color: isOverdue
                                  ? Colors.red.shade600
                                  : task.status == TaskStatus.done
                                      ? Colors.green.shade600
                                      : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              task.getRelativeTime(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isOverdue
                                    ? Colors.red.shade600
                                    : task.status == TaskStatus.done
                                        ? Colors.green.shade600
                                        : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Actions Menu
                      if (isSupervisor) ...[
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.grey.shade500,
                            size: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: Colors.white,
                          surfaceTintColor: Colors.white,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Edit Task',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.red.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') onEdit?.call(task);
                            if (value == 'delete') onDelete?.call(task);
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFEF4444);
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return const Color(0xFF10B981);
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return const Color(0xFF94A3B8);
      case TaskStatus.pending:
        return const Color(0xFF6366F1);
      case TaskStatus.inProgress:
        return const Color(0xFFF59E0B);
      case TaskStatus.review:
        return const Color(0xFF8B5CF6);
      case TaskStatus.testing:
        return const Color(0xFFEC4899);
      case TaskStatus.done:
        return const Color(0xFF10B981);
      case TaskStatus.archived:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Icons.arrow_upward_rounded;
      case TaskPriority.medium:
        return Icons.drag_handle_rounded;
      case TaskPriority.low:
        return Icons.arrow_downward_rounded;
    }
  }
}

// ============================================================================
// ENHANCED TASK DIALOG
// ============================================================================

class TaskDialog extends StatefulWidget {
  final Task? task;
  final List<Student> students;
  final Function(Task) onSave;

  const TaskDialog({
    super.key,
    this.task,
    required this.students,
    required this.onSave,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController _titleCtrl, _descCtrl;
  late String _studentId;
  late DateTime _dueDate;
  late TaskPriority _priority;
  late TaskStatus _status;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');
    _studentId = widget.task?.assignedStudentId ?? widget.students.first.id;
    _dueDate = widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _status = widget.task?.status ?? TaskStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade600,
                            Colors.blue.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.task == null
                            ? Icons.add_task_rounded
                            : Icons.edit_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.task == null ? 'Create New Task' : 'Edit Task',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title Field
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade400),
                    ),
                    prefixIcon: Icon(
                      Icons.title_rounded,
                      color: Colors.grey.shade600,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade400),
                    ),
                    prefixIcon: Icon(
                      Icons.description_outlined,
                      color: Colors.grey.shade600,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                DropdownButtonFormField<TaskStatus>(
                  value: _status,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade400),
                    ),
                    prefixIcon: Icon(
                      Icons.list_alt,
                      color: Colors.grey.shade600,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: TaskStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(s),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            s.name.toUpperCase(),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 16),

                // Assignee Dropdown
                DropdownButtonFormField<String>(
                  value: _studentId,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Assign to Student',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade400),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Colors.grey.shade600,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: widget.students
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    s.name.isNotEmpty
                                        ? s.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  s.name,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _studentId = v!),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate:
                                DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Colors.blue.shade700,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Due Date',
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade400),
                            ),
                            prefixIcon: Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.grey.shade600,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          child: Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(_dueDate),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<TaskPriority>(
                        value: _priority,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          labelStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade400),
                          ),
                          prefixIcon: Icon(
                            Icons.flag_outlined,
                            color: Colors.grey.shade600,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: TaskPriority.values.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Row(
                              children: [
                                Icon(
                                  p == TaskPriority.high
                                      ? Icons.arrow_upward_rounded
                                      : p == TaskPriority.medium
                                          ? Icons.drag_handle_rounded
                                          : Icons.arrow_downward_rounded,
                                  color: p == TaskPriority.high
                                      ? Colors.red.shade600
                                      : p == TaskPriority.medium
                                          ? Colors.orange.shade600
                                          : Colors.green.shade600,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  p.name.toUpperCase(),
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final newTask = widget.task != null
                              ? (widget.task!
                                ..title = _titleCtrl.text.trim()
                                ..description = _descCtrl.text.trim()
                                ..assignedStudentId = _studentId
                                ..dueDate = _dueDate
                                ..priority = _priority
                                ..status = _status)
                              : Task(
                                  id:
                                      DateTime.now().millisecondsSinceEpoch.toString(),
                                  title: _titleCtrl.text.trim(),
                                  description: _descCtrl.text.trim(),
                                  assignedStudentId: _studentId,
                                  startDate: DateTime.now(),
                                  dueDate: _dueDate,
                                  priority: _priority,
                                  status: _status,
                                );

                          widget.onSave(newTask);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(widget.task == null ? 'Create Task' : 'Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return const Color(0xFF94A3B8);
      case TaskStatus.pending:
        return const Color(0xFF6366F1);
      case TaskStatus.inProgress:
        return const Color(0xFFF59E0B);
      case TaskStatus.review:
        return const Color(0xFF8B5CF6);
      case TaskStatus.testing:
        return const Color(0xFFEC4899);
      case TaskStatus.done:
        return const Color(0xFF10B981);
      case TaskStatus.archived:
        return const Color(0xFF6B7280);
    }
  }
}

// ============================================================================
// SUPPORTING CLASSES
// ============================================================================

class Student {
  final String id;
  final String name;
  final String email;

  Student({required this.id, required this.name, required this.email});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
  
  Map<String, dynamic> toApiJson() => {
    'name': name,
    'email': email,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'],
        name: json['name'],
        email: json['email'],
      );
      
  factory Student.fromApiJson(Map<String, dynamic> json) => Student(
        id: json['_id'],
        name: json['name'],
        email: json['email'],
      );
}

enum TaskStatus { backlog, pending, inProgress, review, testing, done, archived }

enum TaskPriority { low, medium, high }

class Task {
  String id;
  String title, description, assignedStudentId;
  DateTime startDate, dueDate;
  TaskPriority priority;
  TaskStatus status;
  String? completionNote;
  DateTime? completionDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedStudentId,
    required this.startDate,
    required this.dueDate,
    required this.priority,
    this.status = TaskStatus.pending,
    this.completionNote,
    this.completionDate,
  });

  bool isOverdue() =>
      DateTime.now().isAfter(dueDate) && status != TaskStatus.done && status != TaskStatus.archived;

  String getRelativeTime() {
    if (status == TaskStatus.done || status == TaskStatus.archived) return 'Done';
    final diff = dueDate.difference(DateTime.now());
    if (diff.isNegative) return '${diff.abs().inDays}d overdue';
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return '${diff.inDays}d left';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w left';
    return '${(diff.inDays / 30).floor()}mo left';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'assignedStudentId': assignedStudentId,
        'startDate': startDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'priority': priority.index,
        'status': status.index,
        'completionNote': completionNote,
        'completionDate': completionDate?.toIso8601String(),
      };
      
  Map<String, dynamic> toApiJson() {
    return {
      'title': title,
      'description': description,
      'assigned_student_id': assignedStudentId,
      'start_date': startDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'priority': _priorityToString(priority),
      'status': _statusToString(status),
      'completion_note': completionNote,
      'completion_date': completionDate?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        assignedStudentId: json['assignedStudentId'],
        startDate: DateTime.parse(json['startDate']),
        dueDate: DateTime.parse(json['dueDate']),
        priority: TaskPriority.values[json['priority']],
        status: TaskStatus.values[json['status']],
        completionNote: json['completionNote'],
        completionDate: json['completionDate'] != null
            ? DateTime.parse(json['completionDate'])
            : null,
      );
      
  factory Task.fromApiJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      assignedStudentId: json['assigned_student_id'],
      startDate: DateTime.parse(json['start_date']),
      dueDate: DateTime.parse(json['due_date']),
      priority: _stringToPriority(json['priority']),
      status: _stringToStatus(json['status']),
      completionNote: json['completion_note'],
      completionDate: json['completion_date'] != null 
          ? DateTime.parse(json['completion_date']) 
          : null,
    );
  }

  static String _priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low: return 'low';
      case TaskPriority.medium: return 'medium';
      case TaskPriority.high: return 'high';
    }
  }
  
  static TaskPriority _stringToPriority(String priority) {
    switch (priority) {
      case 'low': return TaskPriority.low;
      case 'medium': return TaskPriority.medium;
      case 'high': return TaskPriority.high;
      default: return TaskPriority.medium;
    }
  }
  
  static String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog: return 'backlog';
      case TaskStatus.pending: return 'pending';
      case TaskStatus.inProgress: return 'in_progress';
      case TaskStatus.review: return 'review';
      case TaskStatus.testing: return 'testing';
      case TaskStatus.done: return 'done';
      case TaskStatus.archived: return 'archived';
    }
  }
  
  static TaskStatus _stringToStatus(String status) {
    switch (status) {
      case 'backlog': return TaskStatus.backlog;
      case 'pending': return TaskStatus.pending;
      case 'in_progress': return TaskStatus.inProgress;
      case 'review': return TaskStatus.review;
      case 'testing': return TaskStatus.testing;
      case 'done': return TaskStatus.done;
      case 'archived': return TaskStatus.archived;
      default: return TaskStatus.pending;
    }
  }
}

class StorageService {
  static const _studentsKey = 'students', _tasksKey = 'tasks';

  Future<List<Student>> loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_studentsKey);
    if (data == null) return _defaultStudents();
    return (jsonDecode(data) as List).map((e) => Student.fromJson(e)).toList();
  }

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_tasksKey);
    if (data == null) return <Task>[];
    return (jsonDecode(data) as List).map((e) => Task.fromJson(e)).toList();
  }
  
  Future<void> saveTask(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await loadTasks();
    
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    
    await prefs.setString('tasks', jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }
  
  Future<void> deleteTask(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await loadTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await prefs.setString('tasks', jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }
  
  Future<void> syncLocalData() async {
    // This would sync local data with API
    // Implementation depends on your sync strategy
    return;
  }

  List<Student> _defaultStudents() => [
    Student(id: '1', name: 'Alice Johnson', email: 'alice@example.com'),
    Student(id: '2', name: 'Bob Smith', email: 'bob@example.com'),
    Student(id: '3', name: 'Charlie Davis', email: 'charlie@example.com'),
    Student(id: '4', name: 'Diana Miller', email: 'diana@example.com'),
    Student(id: '5', name: 'Ethan Wilson', email: 'ethan@example.com'),
  ];
}