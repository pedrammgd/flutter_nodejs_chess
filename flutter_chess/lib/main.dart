import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/theme.dart';
import 'app/routes.dart';

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Chess Online',
      theme: appTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.pages,
    );
  }
}
