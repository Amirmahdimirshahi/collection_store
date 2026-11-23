
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController codeController =
      TextEditingController();

  final TextEditingController nameController =
      TextEditingController();

  final AuthService authService = AuthService();

  bool isLoading = false;

  Future<void> verifyCode() async {
    final code = codeController.text.trim();
    final fullName = nameController.text.trim();

    if (code.length != 6 || fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('نام و کد ۶ رقمی را وارد کنید'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await authService.verifyCode(
        phoneNumber: widget.phoneNumber,
        fullName: fullName,
        code: code,
      );

      final user = response['user'];

      if (user == null || user['id'] == null) {
        throw Exception('اطلاعات کاربر از سرور دریافت نشد.');
      }

      final userData = <String, dynamic>{
        'id': int.parse(user['id'].toString()),
        'full_name': user['full_name']?.toString() ?? fullName,
        'phone_number':
            user['phone_number']?.toString() ?? widget.phoneNumber,
      };

      if (!mounted) return;

      Navigator.pop(context, userData);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تأیید شماره موبایل'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'کد تأیید ارسال‌شده را وارد کنید',
              ),

              const SizedBox(height: 12),

              Text(
                widget.phoneNumber,
                textDirection: TextDirection.ltr,
              ),

              const SizedBox(height: 24),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'نام و نام خانوادگی',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'کد تأیید ۶ رقمی',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyCode,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('تأیید و ورود'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
