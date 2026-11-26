import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService authService = AuthService();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool codeSent = false;
  bool showPassword = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> sendRecoveryCode() async {
    final phone = phoneController.text.trim();

    if (!RegExp(r'^09\d{9}$').hasMatch(phone)) {
      showMessage('شماره موبایل معتبر وارد کنید.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await authService.sendPasswordResetCode(phone);

      if (!mounted) return;

      setState(() {
        codeSent = true;
      });

      showMessage('کد بازیابی ایجاد شد. ترمینال بک‌اند را بررسی کنید.');
    } catch (e) {
      if (!mounted) return;

      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    final phone = phoneController.text.trim();
    final code = codeController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (code.length != 6) {
      showMessage('کد تأیید باید ۶ رقم باشد.');
      return;
    }

    if (password.length < 8) {
      showMessage('رمز عبور باید حداقل ۸ کاراکتر باشد.');
      return;
    }

    if (password != confirmPassword) {
      showMessage('رمز عبور و تکرار آن یکسان نیستند.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await authService.resetPassword(
        phoneNumber: phone,
        code: code,
        newPassword: password,
      );

      if (!mounted) return;

      showMessage('رمز عبور با موفقیت تغییر کرد.');

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      showMessage(e.toString().replaceFirst('Exception: ', ''));
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
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F3),
        appBar: AppBar(
          title: const Text('بازیابی رمز عبور'),
          centerTitle: true,
          backgroundColor: const Color(0xFF245B45),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Color(0xFF245B45),
                ),

                const SizedBox(height: 24),

                const Text(
                  'بازیابی رمز عبور',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                const Text(
                  'برای تغییر رمز عبور، شماره موبایل خود را وارد کنید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: phoneController,
                  enabled: !codeSent,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'شماره موبایل',
                    hintText: '09123456789',
                    prefixIcon: const Icon(Icons.phone_android),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                if (!codeSent) ...[
                  const SizedBox(height: 24),

                  buildButton(
                    text: 'دریافت کد بازیابی',
                    onPressed: sendRecoveryCode,
                  ),
                ],

                if (codeSent) ...[
                  const SizedBox(height: 20),

                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'کد تأیید ۶ رقمی',
                      prefixIcon: const Icon(Icons.password),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'رمز عبور جدید',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !showPassword,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'تکرار رمز عبور جدید',
                      prefixIcon: const Icon(Icons.lock_reset),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  buildButton(
                    text: 'ثبت رمز عبور جدید',
                    onPressed: resetPassword,
                  ),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              codeSent = false;
                              codeController.clear();
                              passwordController.clear();
                              confirmPasswordController.clear();
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

  Widget buildButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF245B45),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
