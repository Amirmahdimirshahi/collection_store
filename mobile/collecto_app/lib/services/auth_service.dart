import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.91.225.140:8000';
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

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('کد تأیید اشتباه است یا اعتبار آن تمام شده است');
    }
  }
}
