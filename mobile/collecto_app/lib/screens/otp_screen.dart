import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final bool requiresName;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.requiresName = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final AuthService authService = AuthService();

  bool isLoading = false;
  bool showPassword = false;

  Future<void> verifyCode() async {
    final code = codeController.text.trim();
    final fullName = nameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (widget.requiresName && fullName.isEmpty) {
      showMessage('نام و نام خانوادگی را وارد کنید.');
      return;
    }

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
      final response = await authService.verifyCode(
        phoneNumber: widget.phoneNumber,
        fullName: widget.requiresName ? fullName : null,
        password: password,
        code: code,
      );

      final user = response['user'];
      final accessToken = response['access_token']?.toString();

      if (user == null || user['id'] == null) {
        throw Exception('اطلاعات کاربر از سرور دریافت نشد.');
      }

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('توکن ورود از سرور دریافت نشد.');
      }

      final userData = <String, dynamic>{
        'id': int.parse(user['id'].toString()),
        'full_name': user['full_name']?.toString() ?? fullName,
        'phone_number': user['phone_number']?.toString() ?? widget.phoneNumber,
        'role': user['role']?.toString() ?? 'customer',
        'access_token': accessToken,
      };

      if (!mounted) return;

      Navigator.pop(context, userData);
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

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    codeController.dispose();
    nameController.dispose();
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
          title: const Text('تأیید شماره موبایل'),
          centerTitle: true,
          backgroundColor: const Color(0xFF245B45),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 75,
                  color: Color(0xFF245B45),
                ),

                const SizedBox(height: 24),

                Text(
                  widget.requiresName
                      ? 'ساخت حساب کاربری'
                      : 'تکمیل ورود به حساب',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'کد تأیید را وارد کنید و رمز عبور خود را تعیین کنید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),

                const SizedBox(height: 12),

                Text(
                  widget.phoneNumber,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                if (widget.requiresName) ...[
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'نام و نام خانوادگی',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],

                TextField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
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
                        showPassword ? Icons.visibility_off : Icons.visibility,
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
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'تکرار رمز عبور',
                    prefixIcon: const Icon(Icons.lock_reset),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

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

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : verifyCode,
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
                        : const Text(
                            'تأیید و ورود',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
