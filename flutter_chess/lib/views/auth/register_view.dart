import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../app/theme.dart';

class RegisterView extends GetView<AuthController> {
  final _username = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();

  RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Icon(Icons.person_add_outlined, size: 64, color: AppColors.gold),
              const SizedBox(height: 32),
              TextField(controller: _username,
                  decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline, color: AppColors.grey))),
              const SizedBox(height: 16),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AppColors.grey))),
              const SizedBox(height: 16),
              TextField(controller: _password, obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline, color: AppColors.grey))),
              const SizedBox(height: 32),

              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null
                      : () => controller.register(_username.text.trim(), _email.text.trim(), _password.text),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
