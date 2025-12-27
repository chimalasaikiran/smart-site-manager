import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Task> _tasks = [];
  bool _loading = false;
  String? _error;
  bool _hasNetwork = true;

  List<Task> get tasks => _tasks;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasNetwork => _hasNetwork;

  TaskProvider(this._apiService);

  Future<void> loadTasks({Map<String, dynamic>? filters}) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final tasks = await _apiService.getTasks(filters: filters);
      _tasks = tasks;
      _hasNetwork = true;
    } catch (e) {
      _error = e.toString();
      _hasNetwork = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      _loading = true;
      notifyListeners();

      final result = await _apiService.createTask(task);
      final newTask = result['task'] as Task;
      _tasks.insert(0, newTask);
      _hasNetwork = true;
      notifyListeners();
      return newTask;
    } catch (e) {
      _error = e.toString();
      _hasNetwork = false;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      _loading = true;
      notifyListeners();

      final updatedTask = await _apiService.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      _hasNetwork = true;
      notifyListeners();
      return updatedTask;
    } catch (e) {
      _error = e.toString();
      _hasNetwork = false;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      _loading = true;
      notifyListeners();

      await _apiService.deleteTask(id);
      _tasks.removeWhere((task) => task.id == id);
      _hasNetwork = true;
    } catch (e) {
      _error = e.toString();
      _hasNetwork = false;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
