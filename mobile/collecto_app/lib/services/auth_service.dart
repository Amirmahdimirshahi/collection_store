import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://192.168.1.247:8000';

  Future<void> sendCode(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber}),
    );

    if (response.statusCode != 200) {
      throw Exception('ارسال کد تأیید ناموفق بود');
    }
  }

  Future<Map<String, dynamic>> verifyCode({
    required String phoneNumber,
    required String fullName,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'full_name': fullName,
        'code': code,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(responseData);
    }

    throw Exception(
      responseData['detail']?.toString() ??
          'کد تأیید اشتباه است یا اعتبار آن تمام شده است',
    );
  }
}
