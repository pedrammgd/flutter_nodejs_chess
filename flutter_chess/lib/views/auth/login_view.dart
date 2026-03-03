import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';

class LoginView extends GetView<AuthController> {
  final _email    = TextEditingController();
  final _password = TextEditingController();

  LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                const Icon(Icons.sports_esports, size: 80, color: AppColors.gold),
                const SizedBox(height: 12),
                const Text('Chess Online', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Play. Compete. Improve.', style: TextStyle(color: AppColors.grey)),
                const SizedBox(height: 48),

                TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AppColors.grey))),
                const SizedBox(height: 16),
                TextField(controller: _password, obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline, color: AppColors.grey))),
                const SizedBox(height: 28),

                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null
                        : () => controller.login(_email.text.trim(), _password.text),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.register),
                  child: const Text("Don't have an account? Register", style: TextStyle(color: AppColors.gold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
