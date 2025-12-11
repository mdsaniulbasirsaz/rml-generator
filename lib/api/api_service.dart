import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://rml-generator-server.onrender.com/api/v1';
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
  
  // ============================================================================
  // STUDENT ENDPOINTS
  // ============================================================================
  
  /// GET /api/v1/students/ - Read Students with pagination
  /// Parameters:
  /// - skip: Number of records to skip (default: 0, min: 0)
  /// - limit: Maximum number of records to return (default: 100, min: 1, max: 1000)
  Future<List<dynamic>> getStudents({int skip = 0, int limit = 100}) async {
    // Validate parameters
    if (skip < 0) skip = 0;
    if (limit < 1) limit = 1;
    if (limit > 1000) limit = 1000;
    
    final endpoint = '/students/?skip=$skip&limit=$limit';
    final response = await _makeRequest('GET', endpoint, null);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = _tryParseBody(response.body);
      throw ApiException(response.statusCode, body);
    }
  }
  
  /// GET /api/v1/students/{student_id} - Read single Student
  /// Returns detailed information about a specific student
  Future<Map<String, dynamic>> getStudent(String studentId) async {
    final response = await _makeRequest('GET', '/students/$studentId', null);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = _tryParseBody(response.body);
      throw ApiException(response.statusCode, body);
    }
  }
  
  /// POST /api/v1/students/ - Create Student
  /// Required fields in data:
  /// - name: string
  /// - email: string (valid email format)
  /// Returns 201 with created student details
  Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) async {
    final response = await _makeRequest('POST', '/students/', data);
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final body = _tryParseBody(response.body);
      throw ApiException(response.statusCode, body);
    }
  }
  
  /// PUT /api/v1/students/{student_id} - Update Student
  /// Required fields in data:
  /// - name: string
  /// - email: string (valid email format)
  /// Returns 200 with updated student details
  Future<Map<String, dynamic>> updateStudent(
    String studentId,
    Map<String, dynamic> data,
  ) async {
    final response = await _makeRequest('PUT', '/students/$studentId', data);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = _tryParseBody(response.body);
      throw ApiException(response.statusCode, body);
    }
  }
  
  /// DELETE /api/v1/students/{student_id} - Delete Student
  /// Returns 204 No Content on success
  Future<void> deleteStudent(String studentId) async {
    final response = await _makeRequest('DELETE', '/students/$studentId', null);
    
    if (response.statusCode == 204) {
      return; // Success
    } else {
      final body = _tryParseBody(response.body);
      throw ApiException(response.statusCode, body);
    }
  }
  
  // ============================================================================
  // TASK ENDPOINTS
  // ============================================================================
  
  /// GET /api/v1/tasks/ - Get tasks with optional filters
  Future<List<dynamic>> getTasks({
    String? status,
    String? studentId,
    String? priority,
  }) async {
    String query = '';
    if (status != null) query += 'status=$status&';
    if (studentId != null) query += 'student_id=$studentId&';
    if (priority != null) query += 'priority=$priority&';
    
    final endpoint = query.isNotEmpty 
        ? '/tasks/?${query.substring(0, query.length - 1)}' 
        : '/tasks/';
    
    final response = await _makeRequest('GET', endpoint, null);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = _tryParseBody(response.body);
      throw ApiException(response.statusCode, body);
    }
  }
  
  /// POST /api/v1/tasks/ - Create Task
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final response = await _makeRequest('POST', '/tasks/', data);
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final body = _tryParseBody(response.body);
      throw ApiException(response.statusCode, body);
    }
  }
  
  /// PUT /api/v1/tasks/{task_id} - Update Task
  Future<Map<String, dynamic>> updateTask(
    String taskId,
    Map<String, dynamic> data,
  ) async {
    final response = await _makeRequest('PUT', '/tasks/$taskId', data);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = _tryParseBody(response.body);
      throw ApiException(response.statusCode, body);
    }
  }
  
  /// PATCH /api/v1/tasks/{task_id}/status - Update Task Status
  Future<Map<String, dynamic>> updateTaskStatus(
    String taskId,
    String status,
  ) async {
    final endpoint = '/tasks/$taskId/status?status=${Uri.encodeQueryComponent(status)}';
    final response = await _makeRequest('PATCH', endpoint, null);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = _tryParseBody(response.body);
      throw ApiException(response.statusCode, body);
    }
  }
  
  /// DELETE /api/v1/tasks/{task_id} - Delete Task
  Future<void> deleteTask(String taskId) async {
    final response = await _makeRequest('DELETE', '/tasks/$taskId', null);
    
    if (response.statusCode == 204) {
      return; // Success
    } else {
      final body = _tryParseBody(response.body);
      throw ApiException(response.statusCode, body);
    }
  }
  
  /// GET /api/v1/tasks/statistics/overview - Get Task Statistics
  Future<Map<String, dynamic>> getTaskStatistics() async {
    final response = await _makeRequest('GET', '/tasks/statistics/overview', null);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = _tryParseBody(response.body);
      throw ApiException(response.statusCode, body);
    }
  }
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Attempts to parse response body as JSON, returns original string if fails
  dynamic _tryParseBody(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
  
  /// Format validation errors from 422 responses
  String formatValidationErrors(dynamic errorBody) {
    if (errorBody is Map && errorBody['detail'] is List) {
      final details = errorBody['detail'] as List;
      return details
          .map((d) {
            final loc = d['loc'] is List ? (d['loc'] as List).join(' -> ') : '';
            final msg = d['msg'] ?? 'Unknown error';
            return loc.isNotEmpty ? '$loc: $msg' : msg;
          })
          .join('\n');
    } else if (errorBody is Map && errorBody['detail'] is String) {
      return errorBody['detail'];
    }
    return errorBody.toString();
  }
  
  /// Get human-readable error message from ApiException
  String getErrorMessage(ApiException e) {
    switch (e.statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict. This resource already exists.';
      case 422:
        return formatValidationErrors(e.body);
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      default:
        return 'An error occurred: ${e.statusCode}';
    }
  }
}

// ============================================================================
// API EXCEPTION CLASS
// ============================================================================

class ApiException implements Exception {
  final int statusCode;
  final dynamic body;
  
  ApiException(this.statusCode, this.body);
  
  @override
  String toString() {
    if (body is Map && body['detail'] != null) {
      return 'ApiException($statusCode): ${body['detail']}';
    }
    return 'ApiException($statusCode): $body';
  }
  
  /// Check if this is a validation error (422)
  bool get isValidationError => statusCode == 422;
  
  /// Check if this is a not found error (404)
  bool get isNotFound => statusCode == 404;
  
  /// Check if this is a conflict error (409)
  bool get isConflict => statusCode == 409;
  
  /// Check if this is a server error (5xx)
  bool get isServerError => statusCode >= 500 && statusCode < 600;
}