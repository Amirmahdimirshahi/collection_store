import 'dart:convert';

import 'package:http/http.dart' as http;

class ProductService {
  static const String baseUrl = 'http://192.168.1.247:8000';

  final String? accessToken;

  ProductService({this.accessToken});

  Map<String, String> get authHeaders {
    if (accessToken == null || accessToken!.isEmpty) {
      throw Exception('توکن ورود مدیر موجود نیست. دوباره وارد شوید.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('خطا در دریافت محصولات: ${response.body}');
  }

  Future<void> addProduct({
    required String name,
    required String category,
    required String description,
    required int price,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: authHeaders,
      body: jsonEncode({
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('خطا در ثبت محصول: ${response.body}');
    }
  }

  Future<void> updateProduct({
    required int productId,
    required String name,
    required String category,
    required String description,
    required int price,
    required int quantity,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$productId'),
      headers: authHeaders,
      body: jsonEncode({
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('خطا در ویرایش محصول: ${response.body}');
    }
  }

  Future<void> deleteProduct(int productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: authHeaders,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('خطا در حذف محصول: ${response.body}');
    }
  }
}
