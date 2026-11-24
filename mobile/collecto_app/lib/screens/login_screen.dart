import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  final AuthService authService = AuthService();

  bool isLoading = false;

  Future<void> sendCode() async {
    final phone = phoneController.text.trim();

    if (!RegExp(r'^09\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شماره موبایل معتبر وارد کنید')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await authService.sendCode(phone);

      if (!mounted) return;

      final user = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) {
            return OtpScreen(phoneNumber: phone);
          },
        ),
      );

      if (!mounted) return;

      if (user != null) {
        Navigator.pop(context, user);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ورود به کالکتو'), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 90,
                color: Color(0xFF245B45),
              ),

              const SizedBox(height: 24),

              const Text(
                'به کالکتو خوش آمدید',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Text('شماره موبایل خود را وارد کنید'),

              const SizedBox(height: 24),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'شماره موبایل',
                  hintText: '09123456789',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : sendCode,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('دریافت کد تأیید'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
