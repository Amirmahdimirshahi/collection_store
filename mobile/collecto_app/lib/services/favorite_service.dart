import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_model.dart';
import 'product_service.dart';

class FavoriteService {
  final String accessToken;

  FavoriteService({required this.accessToken});

  Map<String, String> get authHeaders {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  Future<List<ProductModel>> getFavorites() async {
    final response = await http.get(
      Uri.parse('${ProductService.baseUrl}/favorites'),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> favorites = data['favorites'];

      return favorites.map((item) => ProductModel.fromJson(item)).toList();
    }

    throw Exception('خطا در دریافت علاقه‌مندی‌ها: ${response.body}');
  }

  Future<void> addFavorite(int productId) async {
    final response = await http.post(
      Uri.parse('${ProductService.baseUrl}/favorites/$productId'),
      headers: authHeaders,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('خطا در افزودن علاقه‌مندی: ${response.body}');
    }
  }

  Future<void> removeFavorite(int productId) async {
    final response = await http.delete(
      Uri.parse('${ProductService.baseUrl}/favorites/$productId'),
      headers: authHeaders,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('خطا در حذف علاقه‌مندی: ${response.body}');
    }
  }
}
