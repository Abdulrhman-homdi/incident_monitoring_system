import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ticket_model.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://balady-api.onrender.com/api/tickets';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android) {
      return 'https://balady-api.onrender.com/api/tickets';
    }
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
}
