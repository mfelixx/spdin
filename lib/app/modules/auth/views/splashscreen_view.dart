import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:perjadin_kpu/app/modules/auth/controllers/auth_controller.dart';

class SplashscreenView extends GetView {
  SplashscreenView({super.key});
  final splashC = Get.put(SplashscreenController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: splashC.fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/KPU_Logo.png', width: 120),
              const SizedBox(height: 20),
              const Text(
                "Komisi Pemilihan Umum",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const Text(
                "Aplikasi Perjalanan Dinas",
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
