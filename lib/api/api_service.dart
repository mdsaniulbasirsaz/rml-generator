import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.100:8000/api/v1';
  static const Duration timeout = Duration(seconds: 10);
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  Future<http.Response> _makeRequest(
    String method,
    String endpoint,
    dynamic data,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    try {
      switch (method) {
        case 'GET':
          return await http.get(url, headers: headers).timeout(timeout);
        case 'POST':
          return await http.post(
            url,
            headers: headers,
            body: jsonEncode(data),
          ).timeout(timeout);
        case 'PUT':
          return await http.put(
            url,
            headers: headers,
            body: jsonEncode(data),
          ).timeout(timeout);
        case 'PATCH':
          return await http.patch(
            url,
            headers: headers,
            body: jsonEncode(data),
          ).timeout(timeout);
        case 'DELETE':
          return await http.delete(url, headers: headers).timeout(timeout);
        default:
          throw Exception('Invalid HTTP method');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException {
      throw Exception('Failed to connect to server');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Student endpoints
  Future<List<dynamic>> getStudents() async {
    final response = await _makeRequest('GET', '/students/', null);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load students: ${response.statusCode}');
    }
  }
  
  Future<dynamic> createStudent(Map<String, dynamic> data) async {
    final response = await _makeRequest('POST', '/students/', data);
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create student: ${response.statusCode}');
    }
  }
  
  Future<dynamic> updateStudent(String id, Map<String, dynamic> data) async {
    final response = await _makeRequest('PUT', '/students/$id', data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update student: ${response.statusCode}');
    }
  }
  
  Future<void> deleteStudent(String id) async {
    final response = await _makeRequest('DELETE', '/students/$id', null);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete student: ${response.statusCode}');
    }
  }
  
  // Task endpoints
  Future<List<dynamic>> getTasks({
    String? status,
    String? studentId,
    String? priority,
  }) async {
    String query = '';
    if (status != null) query += 'status=$status&';
    if (studentId != null) query += 'student_id=$studentId&';
    if (priority != null) query += 'priority=$priority&';
    
    final endpoint = query.isNotEmpty ? '/tasks/?${query.substring(0, query.length - 1)}' : '/tasks/';
    final response = await _makeRequest('GET', endpoint, null);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load tasks: ${response.statusCode}');
    }
  }
  
  Future<dynamic> createTask(Map<String, dynamic> data) async {
    final response = await _makeRequest('POST', '/tasks/', data);
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create task: ${response.statusCode}');
    }
  }
  
  Future<dynamic> updateTask(String id, Map<String, dynamic> data) async {
    final response = await _makeRequest('PUT', '/tasks/$id', data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update task: ${response.statusCode}');
    }
  }
  
  Future<dynamic> updateTaskStatus(String id, String status) async {
    final response = await _makeRequest('PATCH', '/tasks/$id/status', {'status': status});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update task status: ${response.statusCode}');
    }
  }
  
  Future<void> deleteTask(String id) async {
    final response = await _makeRequest('DELETE', '/tasks/$id', null);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete task: ${response.statusCode}');
    }
  }
  
  Future<Map<String, dynamic>> getTaskStatistics() async {
    final response = await _makeRequest('GET', '/tasks/statistics/overview', null);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load statistics: ${response.statusCode}');
    }
  }
}