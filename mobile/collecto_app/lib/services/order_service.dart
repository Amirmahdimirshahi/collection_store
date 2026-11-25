import 'dart:convert';

import 'package:http/http.dart' as http;

class OrderService {
  static const String baseUrl = 'http://10.91.225.140:8000';

  final String accessToken;

  OrderService({required this.accessToken});

  Map<String, String> get authHeaders {
    if (accessToken.isEmpty) {
      throw Exception('توکن ورود موجود نیست. لطفاً دوباره وارد شوید.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, int>> items,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/orders'),
          headers: authHeaders,
          body: jsonEncode({'items': items}),
        )
        .timeout(const Duration(seconds: 15));

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(responseData);
    }

    throw Exception(
      responseData['detail']?.toString() ?? 'ثبت سفارش با خطا مواجه شد.',
    );
  }

  Future<List<Map<String, dynamic>>> getUserOrders({
    required int userId,
  }) async {
    final response = await http
        .get(Uri.parse('$baseUrl/users/$userId/orders'), headers: authHeaders)
        .timeout(const Duration(seconds: 15));

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final orders = responseData['orders'] as List;

      return orders.map((order) => Map<String, dynamic>.from(order)).toList();
    }

    throw Exception(
      responseData['detail']?.toString() ??
          'دریافت تاریخچه سفارش‌ها ناموفق بود.',
    );
  }
}
