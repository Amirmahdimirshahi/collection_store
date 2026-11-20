
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  static const String baseUrl = 'http://192.168.1.247:8000';


  Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('خطا در دریافت محصولات');
    }
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
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'خطا در ثبت محصول: ${response.statusCode} - ${response.body}',
      );
    }
  }

}
