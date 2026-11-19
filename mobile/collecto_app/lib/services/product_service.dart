
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
}
