import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://192.168.1.247:8000';

  Map<String, dynamic> decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {};
    } catch (_) {
      return {};
    }
  }

  String getErrorMessage(
    Map<String, dynamic> responseData,
    String defaultMessage,
  ) {
    return responseData['detail']?.toString() ?? defaultMessage;
  }

  Future<Map<String, dynamic>> checkPhone(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/check-phone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber}),
    );

    final responseData = decodeResponse(response.body);

    if (response.statusCode == 200) {
      return responseData;
    }

    throw Exception(
      getErrorMessage(responseData, 'بررسی شماره موبایل ناموفق بود'),
    );
  }

  Future<void> sendCode(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber}),
    );

    if (response.statusCode != 200) {
      final responseData = decodeResponse(response.body);

      throw Exception(
        getErrorMessage(responseData, 'ارسال کد تأیید ناموفق بود'),
      );
    }
  }

  Future<Map<String, dynamic>> loginWithPassword({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber, 'password': password}),
    );

    final responseData = decodeResponse(response.body);

    if (response.statusCode == 200) {
      return responseData;
    }

    throw Exception(
      getErrorMessage(responseData, 'شماره موبایل یا رمز عبور اشتباه است'),
    );
  }

  Future<Map<String, dynamic>> verifyCode({
    required String phoneNumber,
    required String password,
    required String code,
    String? fullName,
  }) async {
    final Map<String, dynamic> requestBody = {
      'phone_number': phoneNumber,
      'password': password,
      'code': code,
    };

    if (fullName != null && fullName.trim().isNotEmpty) {
      requestBody['full_name'] = fullName.trim();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    final responseData = decodeResponse(response.body);

    if (response.statusCode == 200) {
      return responseData;
    }

    throw Exception(
      getErrorMessage(
        responseData,
        'کد تأیید اشتباه است یا اعتبار آن تمام شده است',
      ),
    );
  }

  Future<void> sendPasswordResetCode(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/send-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber}),
    );

    if (response.statusCode != 200) {
      final responseData = decodeResponse(response.body);

      throw Exception(
        getErrorMessage(responseData, 'دریافت کد بازیابی ناموفق بود'),
      );
    }
  }

  Future<void> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'code': code,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final responseData = decodeResponse(response.body);

      throw Exception(
        getErrorMessage(responseData, 'تغییر رمز عبور ناموفق بود'),
      );
    }
  }
}
