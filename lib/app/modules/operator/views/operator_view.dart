import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get/get.dart';
import 'package:perjadin_kpu/app/modules/auth/controllers/auth_controller.dart';
import 'package:perjadin_kpu/app/modules/operator/views/perjadin_view.dart';
import 'package:perjadin_kpu/app/modules/pegawai/views/perjadinku_view.dart';
import 'package:perjadin_kpu/app/routes/app_pages.dart';

import '../controllers/operator_controller.dart';

class OperatorView extends GetView<OperatorController> {
  OperatorView({super.key});
  final authC = Get.find<AuthController>();
  final List<Widget> pages = [PerjadinView(), PerjadinkuView()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Obx(() => pages[controller.currentPage.value]),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: Icon(Icons.work),
            label: 'Daftar Perjadin',
            onTap: () => controller.changePage(0),
          ),
          SpeedDialChild(
            child: Icon(Icons.work_history),
            label: 'SPJ',
            onTap: () => controller.changePage(1),
          ),
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Tambah Perjadin',
            onTap: () => Get.toNamed(Routes.TAMBAH_PERJADIN),
          ),
        ],
      ),
      // FloatingActionButton(
      //   onPressed: () => Get.toNamed(Routes.TAMBAH_PERJADIN),
      //   backgroundColor: Colors.blue.shade400,
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }
}
