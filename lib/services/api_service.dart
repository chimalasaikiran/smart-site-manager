import 'package:dio/dio.dart';

import '../models/task.dart';

class ApiService {
  final Dio _dio = Dio();

  ApiService() {
    _dio.options.baseUrl = 'https://smart-site-manager.onrender.com/api';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // ignore: avoid_print
          print(' ${options.method} ${options.path}');
          return handler.next(options);
        },
        onError: (error, handler) {
          // ignore: avoid_print
          print(' API Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<List<Task>> getTasks({Map<String, dynamic>? filters}) async {
    try {
      final response = await _dio.get('/tasks', queryParameters: filters);
      final tasksData = response.data['tasks'];
      if (tasksData == null || tasksData is! List) {
        return [];
      }
      return tasksData.map<Task>((json) => Task.fromJson(json)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('getTasks error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> classify(
      String title, String description) async {
    final response = await _dio.post('/tasks/classify', data: {
      'title': title,
      'description': description,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createTask(Task task) async {
    final response = await _dio.post('/tasks', data: task.toJson());
    return {
      'task': Task.fromJson(response.data['task']),
      'classification': response.data['classification'],
    };
  }

  Future<Task> updateTask(Task task) async {
    final response = await _dio.put('/tasks/${task.id}', data: task.toJson());
    return Task.fromJson(response.data['task']);
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete('/tasks/$id');
  }
}
