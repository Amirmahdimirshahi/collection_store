import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'otp_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();

  bool isLoading = false;
  bool hasPassword = false;

  Future<void> continueLogin() async {
    final phone = phoneController.text.trim();

    if (!RegExp(r'^09\d{9}$').hasMatch(phone)) {
      showMessage('شماره موبایل معتبر وارد کنید');
      return;
    }

    if (hasPassword) {
      await loginWithPassword(phone);
    } else {
      await registerOrSetPassword(phone);
    }
  }

  Future<void> loginWithPassword(String phone) async {
    final password = passwordController.text;

    if (password.isEmpty) {
      showMessage('رمز عبور را وارد کنید');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await authService.loginWithPassword(
        phoneNumber: phone,
        password: password,
      );

      if (!mounted) return;

      final user = buildUserData(response);
      Navigator.pop(context, user);
    } catch (e) {
      if (!mounted) return;
      showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> registerOrSetPassword(String phone) async {
    setState(() => isLoading = true);

    try {
      final phoneInfo = await authService.checkPhone(phone);

      if (!mounted) return;

      final accountHasPassword = phoneInfo['has_password'] == true;

      if (accountHasPassword) {
        setState(() {
          hasPassword = true;
          isLoading = false;
        });
        return;
      }

      await authService.sendCode(phone);

      if (!mounted) return;

      final requiresName = phoneInfo['has_account'] != true;

      final user = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OtpScreen(phoneNumber: phone, requiresName: requiresName),
        ),
      );

      if (!mounted) return;

      if (user != null) {
        Navigator.pop(context, user);
      }
    } catch (e) {
      if (!mounted) return;
      showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> openForgotPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  Map<String, dynamic> buildUserData(Map<String, dynamic> response) {
    final user = Map<String, dynamic>.from(response['user']);

    return {
      'id': user['id'],
      'full_name': user['full_name'],
      'phone_number': user['phone_number'],
      'role': user['role'],
      'access_token': response['access_token'],
    };
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

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
                  enabled: !hasPassword,
                  decoration: const InputDecoration(
                    labelText: 'شماره موبایل',
                    hintText: '09123456789',
                    border: OutlineInputBorder(),
                  ),
                ),

                if (hasPassword) ...[
                  const SizedBox(height: 20),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'رمز عبور',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: isLoading ? null : openForgotPassword,
                    child: const Text('رمز عبور را فراموش کرده‌ام'),
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : continueLogin,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : Text(hasPassword ? 'ورود به حساب' : 'ادامه'),
                  ),
                ),

                if (hasPassword) ...[
                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              hasPassword = false;
                              passwordController.clear();
                            });
                          },
                    child: const Text('تغییر شماره موبایل'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
