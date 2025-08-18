import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:perjadin_kpu/app/modules/admin/views/pegawai_view.dart';
import 'package:perjadin_kpu/app/modules/admin/views/perjadin_view.dart';
import 'package:perjadin_kpu/app/modules/auth/controllers/auth_controller.dart';
import 'package:perjadin_kpu/app/modules/pegawai/views/perjadinku_view.dart';

import '../controllers/admin_controller.dart';

class AdminView extends GetView<AdminController> {
  AdminView({super.key});
  final authC = Get.find<AuthController>();

  final List<Widget> _pages = [PerjadinView(), PegawaiView(), PerjadinkuView()];
  final icons = [
    Icons.airplane_ticket_outlined,
    Icons.person_outline,
    Icons.work_history_outlined,
    Icons.logout,
  ];
  final labels = ['Perjadin', 'Pegawai', 'Perjalananku', 'Keluar'];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
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
        ),
        body: IndexedStack(
          index: controller.currentTab.value,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.symmetric(
              horizontal: BorderSide(color: Colors.black12, width: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(icons.length, (index) {
                final isSelected = controller.currentTab.value == index;
                final isLogout = index == 3;

                return buildBottomNavBarItem(index, isSelected, isLogout);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBottomNavBarItem(int i, bool isSelected, bool isLogout) {
    return GestureDetector(
      onTap: () {
        if (isLogout) {
          authC.logout();
        } else {
          controller.currentTab.value = i;
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              size: 30,
              icons[i],
              color:
                  isSelected && !isLogout
                      ? Colors.blue.shade400
                      : Colors.black45,
            ),
            const SizedBox(height: 4),
            Text(
              labels[i],
              style: TextStyle(
                fontSize: 12,
                color:
                    isSelected && !isLogout
                        ? Colors.blue.shade400
                        : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
