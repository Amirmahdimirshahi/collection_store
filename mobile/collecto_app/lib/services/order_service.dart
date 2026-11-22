
import 'dart:convert';

import 'package:http/http.dart' as http;

class OrderService {
  static const String baseUrl = 'http://10.137.47.140:8000';

  Future<Map<String, dynamic>> createOrder({
    required int userId,
    required List<Map<String, int>> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'items': items,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(responseData);
    }

    throw Exception(
      responseData['detail']?.toString() ??
          'ثبت سفارش با خطا مواجه شد.',
    );
  }
}
