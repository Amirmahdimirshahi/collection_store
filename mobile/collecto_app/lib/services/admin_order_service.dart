import 'dart:convert';

import 'package:http/http.dart' as http;

class AdminOrderService {
  static const String baseUrl = 'http://192.168.1.247:8000';

  final String accessToken;

  AdminOrderService({required this.accessToken});

  Map<String, String> get headers {
    if (accessToken.isEmpty) {
      throw Exception('توکن ورود مدیر موجود نیست. دوباره وارد شوید.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final response = await http
        .get(Uri.parse('$baseUrl/admin/orders'), headers: headers)
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final orders = data['orders'] as List;
      return orders.map((order) => Map<String, dynamic>.from(order)).toList();
    }

    throw Exception(
      data['detail']?.toString() ?? 'دریافت سفارش‌ها ناموفق بود.',
    );
  }

  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/admin/orders/$orderId/status'),
          headers: headers,
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(
        data['detail']?.toString() ?? 'تغییر وضعیت سفارش ناموفق بود.',
      );
    }
  }
}
