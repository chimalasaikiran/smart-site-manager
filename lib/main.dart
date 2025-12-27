import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'models/task.dart';
import 'providers/task_provider.dart';
import 'services/api_service.dart';

// Models
// Task class moved to models/task.dart

// State Management with Provider
// TaskProvider moved to providers/task_provider.dart

// Updated ApiService with Dio interceptors
// ApiService moved to services/api_service.dart

// Utility Functions
class TaskUtils {
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'scheduling':
        return const Color(0xFF007AFF);
      case 'finance':
        return const Color(0xFF34C759);
      case 'technical':
        return const Color(0xFFFF9500);
      case 'safety':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFFF3B30);
      case 'medium':
        return const Color(0xFFFF9500);
      case 'low':
        return const Color(0xFF34C759);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9500);
      case 'in_progress':
        return const Color(0xFF007AFF);
      case 'completed':
        return const Color(0xFF34C759);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'scheduling':
        return Icons.calendar_today;
      case 'finance':
        return Icons.attach_money;
      case 'technical':
        return Icons.computer;
      case 'safety':
        return Icons.security;
      default:
        return Icons.task;
    }
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TaskProvider(ApiService()),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Site Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A1A),
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedStatus = 'all';
  final String _selectedCategory = 'all';
  final String _selectedPriority = 'all';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadTasks() {
    final Map<String, dynamic> filters = {};

    if (_selectedStatus != 'all') {
      filters['status'] = _selectedStatus;
    }
    if (_selectedCategory != 'all') {
      filters['category'] = _selectedCategory;
    }
    if (_selectedPriority != 'all') {
      filters['priority'] = _selectedPriority;
    }
    if (_searchController.text.isNotEmpty) {
      filters['search'] = _searchController.text;
    }

    Provider.of<TaskProvider>(
      context,
      listen: false,
    ).loadTasks(filters: filters);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Task Manager',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskDialog(),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // Show network error
          if (!taskProvider.hasNetwork) {
            return _buildNoNetworkWidget();
          }

          // Show loading
          if (taskProvider.loading && taskProvider.tasks.isEmpty) {
            return _buildLoadingWidget();
          }

          // Show error
          if (taskProvider.error != null) {
            return _buildErrorWidget(taskProvider.error!);
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Quick Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('All Status', 'all', _selectedStatus, (v) {
                      setState(() => _selectedStatus = v);
                      _loadTasks();
                    }),
                    _buildFilterChip('Pending', 'pending', _selectedStatus, (
                      v,
                    ) {
                      setState(() => _selectedStatus = v);
                      _loadTasks();
                    }),
                    _buildFilterChip(
                      'In Progress',
                      'in_progress',
                      _selectedStatus,
                      (v) {
                        setState(() => _selectedStatus = v);
                        _loadTasks();
                      },
                    ),
                    _buildFilterChip(
                      'Completed',
                      'completed',
                      _selectedStatus,
                      (v) {
                        setState(() => _selectedStatus = v);
                        _loadTasks();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Summary Cards
              _buildSummaryCards(taskProvider.tasks),

              const SizedBox(height: 16),

              // Tasks List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadTasks(),
                  child: taskProvider.tasks.isEmpty
                      ? _buildEmptyWidget()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: taskProvider.tasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _buildTaskCard(taskProvider.tasks[i]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String selectedValue,
    ValueChanged<String> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedValue == value,
        onSelected: (_) => onSelected(value),
        backgroundColor: Colors.grey[100],
        selectedColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: selectedValue == value
              ? const Color(0xFF007AFF)
              : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<Task> tasks) {
    final pendingCount = tasks.where((t) => t.status == 'pending').length;
    final inProgressCount =
        tasks.where((t) => t.status == 'in_progress').length;
    final completedCount = tasks.where((t) => t.status == 'completed').length;
    final totalCount = tasks.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Status Summary
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Pending',
                    pendingCount,
                    TaskUtils.getStatusColor('pending'),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFF2F2F7),
                  ),
                  _buildSummaryItem(
                    'In Progress',
                    inProgressCount,
                    TaskUtils.getStatusColor('in_progress'),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFF2F2F7),
                  ),
                  _buildSummaryItem(
                    'Completed',
                    completedCount,
                    TaskUtils.getStatusColor('completed'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category and Priority Summary
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF007AFF),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Tasks',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        '$totalCount',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF34C759),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'High Priority',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        '${tasks.where((t) => t.priority == 'high').length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openTaskDialog(task: task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Category and Priority
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TaskUtils.getCategoryColor(
                          task.category,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            TaskUtils.getCategoryIcon(task.category),
                            size: 12,
                            color: TaskUtils.getCategoryColor(task.category),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: TaskUtils.getCategoryColor(task.category),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TaskUtils.getPriorityColor(
                          task.priority,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        task.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: TaskUtils.getPriorityColor(task.priority),
                        ),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: Color(0xFF8E8E93),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 18,
                                color: Color(0xFF007AFF),
                              ),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                size: 18,
                                color: Color(0xFFFF3B30),
                              ),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _openTaskDialog(task: task);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(task);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                if (task.description.isNotEmpty)
                  Text(
                    task.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Footer
                Row(
                  children: [
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TaskUtils.getStatusColor(
                          task.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        task.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: TaskUtils.getStatusColor(task.status),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Due Date
                    if (task.dueDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d').format(task.dueDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 12),

                    // Assigned To
                    if (task.assignedTo != null)
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            task.assignedTo!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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

  Widget _buildLoadingWidget() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: const ListTile(
            title: SizedBox(height: 20, child: ColoredBox(color: Colors.grey)),
            subtitle: SizedBox(
              height: 16,
              child: ColoredBox(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF3B30)),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadTasks,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoNetworkWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your network settings',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first task',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<TaskProvider>(
                context,
                listen: false,
              ).deleteTask(task.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openTaskDialog({Task? task}) {
    final isEditing = task != null;
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    final assignedController = TextEditingController(
      text: task?.assignedTo ?? '',
    );

    String category = task?.category ?? 'general';
    String priority = task?.priority ?? 'low';
    String status = task?.status ?? 'pending';
    DateTime? dueDate = task?.dueDate;

    Map<String, dynamic>? classificationResult;
    bool isClassifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Edit Task' : 'New Task',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Classify Button (Smart Feature)
                      if (!isEditing)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isClassifying
                                ? null
                                : () async {
                                    if (titleController.text.isEmpty &&
                                        descController.text.isEmpty) {
                                      return;
                                    }
                                    setState(() => isClassifying = true);
                                    try {
                                      final result = await ApiService()
                                          .classify(titleController.text,
                                              descController.text);
                                      setState(() {
                                        classificationResult = result;
                                        category = result['category'];
                                        priority = result['priority'];
                                        isClassifying = false;
                                      });
                                    } catch (e) {
                                      setState(() => isClassifying = false);
                                    }
                                  },
                            icon: isClassifying
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: const Text('Smart Classify'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF007AFF),
                              side: const BorderSide(color: Color(0xFF007AFF)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                      if (classificationResult != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF007AFF).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF007AFF)
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🤖 Smart Classification',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Category: ${category.toUpperCase()}',
                                style: TextStyle(
                                  color: TaskUtils.getCategoryColor(category),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Priority: ${priority.toUpperCase()}',
                                style: TextStyle(
                                  color: TaskUtils.getPriorityColor(priority),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (classificationResult!['suggested_actions'] !=
                                  null) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Suggested Actions:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                ...(classificationResult!['suggested_actions']
                                        as List)
                                    .take(3)
                                    .map((a) => Text('• $a')),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Assigned To
                      TextField(
                        controller: assignedController,
                        decoration: const InputDecoration(
                          labelText: 'Assigned To',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Due Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => dueDate = date);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dueDate != null
                                    ? DateFormat('MMM d, yyyy').format(dueDate!)
                                    : 'Select date',
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Category Selection
                      const Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          'scheduling',
                          'finance',
                          'technical',
                          'safety',
                          'general'
                        ].map((cat) {
                          return ChoiceChip(
                            label:
                                Text(cat[0].toUpperCase() + cat.substring(1)),
                            selected: category == cat,
                            onSelected: (_) => setState(() => category = cat),
                            backgroundColor: Colors.grey[100],
                            selectedColor:
                                const Color(0xFF007AFF).withValues(alpha: 0.1),
                            labelStyle: TextStyle(
                              color: category == cat
                                  ? const Color(0xFF007AFF)
                                  : Colors.grey[600],
                              fontWeight: category == cat
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Priority Selection
                      const Text(
                        'Priority',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['high', 'medium', 'low'].map((pri) {
                          return ChoiceChip(
                            label:
                                Text(pri[0].toUpperCase() + pri.substring(1)),
                            selected: priority == pri,
                            onSelected: (_) => setState(() => priority = pri),
                            backgroundColor: Colors.grey[100],
                            selectedColor:
                                const Color(0xFF007AFF).withValues(alpha: 0.1),
                            labelStyle: TextStyle(
                              color: priority == pri
                                  ? const Color(0xFF007AFF)
                                  : Colors.grey[600],
                              fontWeight: priority == pri
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Status Selection
                      const Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            ['pending', 'in_progress', 'completed'].map((st) {
                          return ChoiceChip(
                            label: Text(st.replaceAll('_', ' ').toUpperCase()),
                            selected: status == st,
                            onSelected: (_) => setState(() => status = st),
                            backgroundColor: Colors.grey[100],
                            selectedColor:
                                const Color(0xFF007AFF).withValues(alpha: 0.1),
                            labelStyle: TextStyle(
                              color: status == st
                                  ? const Color(0xFF007AFF)
                                  : Colors.grey[600],
                              fontWeight: status == st
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: Provider.of<TaskProvider>(context).loading
                              ? null
                              : () async {
                                  if (titleController.text.isEmpty ||
                                      descController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Title and description are required'),
                                        backgroundColor: Color(0xFFFF3B30),
                                      ),
                                    );
                                    return;
                                  }

                                  final newTask = Task(
                                    id: task?.id ?? '',
                                    title: titleController.text,
                                    description: descController.text,
                                    category: category,
                                    priority: priority,
                                    status: status,
                                    assignedTo:
                                        assignedController.text.isNotEmpty
                                            ? assignedController.text
                                            : null,
                                    dueDate: dueDate,
                                    createdAt:
                                        task?.createdAt ?? DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );

                                  try {
                                    if (isEditing) {
                                      await Provider.of<TaskProvider>(context,
                                              listen: false)
                                          .updateTask(newTask);
                                    } else {
                                      await Provider.of<TaskProvider>(context,
                                              listen: false)
                                          .createTask(newTask);
                                    }
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor:
                                            const Color(0xFFFF3B30),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Provider.of<TaskProvider>(context).loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(isEditing ? 'Update Task' : 'Create Task'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChip(
    String label,
    String value,
    String selectedValue,
    Function(String) onSelected,
    Function(void Function()) setState,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedValue == value,
      onSelected: (_) {
        onSelected(value);
      },
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color:
            selectedValue == value ? const Color(0xFF007AFF) : Colors.grey[600],
        fontWeight:
            selectedValue == value ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
