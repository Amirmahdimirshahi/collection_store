
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

  Future<List<Map<String, dynamic>>> getUserOrders({
    required int userId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/orders'),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final orders = responseData['orders'] as List;

      return orders
          .map((order) => Map<String, dynamic>.from(order))
          .toList();
    }

    throw Exception(
      responseData['detail']?.toString() ??
          'دریافت تاریخچه سفارش‌ها ناموفق بود.',
    );
  }
}
