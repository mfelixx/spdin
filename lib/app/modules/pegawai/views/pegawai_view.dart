import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:perjadin_kpu/app/modules/auth/controllers/auth_controller.dart';
import 'package:perjadin_kpu/app/modules/pegawai/views/perjadinku_view.dart';

import '../controllers/pegawai_controller.dart';

class PegawaiView extends GetView<PegawaiController> {
  PegawaiView({super.key});
  final authC = Get.find<AuthController>();
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
      },
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'SPDinApp',
            style: TextStyle(
              color: Colors.blue.shade400,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.blue.shade400),
              onPressed: () => authC.logout(),
            ),
          ],
        ),
        body: PerjadinkuView(),
      ),
    );
  }
}
