import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ticket_model.dart';

class ApiService {
  static String get baseUrl {
    return 'https://balady-api.onrender.com/api/tickets';
  }

  static Future<List<Ticket>> fetchTickets() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] as List<dynamic>;
      return data
          .map((item) => Ticket.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('فشل تحميل البلاغات - ${response.statusCode}');
  }

  static Future<Ticket> fetchTicketById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return Ticket.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception('فشل تحميل البلاغ - ${response.statusCode}');
  }

  static Future<Ticket> performAction({
    required String id,
    required String action,
    String details = '',
    String assignee = '',
    String escalationReason = '',
    String targetEntity = '',
  }) async {
    final payload = {
      'action': action,
      'details': details,
      'assignee': assignee,
    };
    if (action == 'تصعيد') {
      payload['escalationReason'] = escalationReason;
      payload['targetEntity'] = targetEntity;
    }
    final response = await http.put(
      Uri.parse('$baseUrl/action/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return Ticket.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception('فشل تنفيذ الإجراء - ${response.statusCode}');
  }

  static Future<Ticket> addProgress({
    required String id,
    required String action,
    String details = '',
    String assignee = '',
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/progress/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': action,
        'details': details,
        'assignee': assignee,
      }),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return Ticket.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception('فشل تحديث سجل التقدم - ${response.statusCode}');
  }

  static Future<Ticket> updateStatus({
    required String id,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update-status/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return Ticket.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception('فشل تحديث الحالة - ${response.statusCode}');
  }
}
