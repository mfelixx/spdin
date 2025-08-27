import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:perjadin_kpu/app/modules/admin/views/pegawai_view.dart';
import 'package:perjadin_kpu/app/modules/auth/controllers/auth_controller.dart';
import 'package:perjadin_kpu/app/modules/operator/controllers/operator_controller.dart';
import 'package:perjadin_kpu/app/modules/pegawai/views/perjadinku_view.dart';
import 'package:perjadin_kpu/app/routes/app_pages.dart';

import '../controllers/admin_controller.dart';

class AdminView extends GetView<AdminController> {
  AdminView({super.key});
  final authC = Get.find<AuthController>();
  final operatorC = Get.put(OperatorController());

  final icons = [
    Icons.airplane_ticket_outlined,
    Icons.person_outline,
    Icons.work_history_outlined,
    Icons.logout,
  ];
  final labels = ['Perjadin', 'Pegawai', 'SPJ Saya', 'Keluar'];

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      perjadinView(),
      PegawaiView(),
      PerjadinkuView(),
    ];
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

  Widget perjadinView() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.blue.shade400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari perjadin...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        controller.searchPerjadin(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(
            () =>
                controller.tempSearchPerjadin.isNotEmpty
                    ? SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade200,
                                child: Icon(
                                  Icons.work_history_rounded,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              title: Text(
                                controller.capitalizeEachWord(
                                  controller
                                      .tempSearchPerjadin[index]['peserta'][0]["namapegawai"],
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                "No.SPD : ${controller.tempSearchPerjadin[index]['nospd']}",
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              onTap: () {
                                operatorC.getPerjadin(
                                  controller.tempSearchPerjadin[index].id,
                                );
                                Get.toNamed(
                                  Routes.EDIT_PERJADIN,
                                  arguments:
                                      controller.tempSearchPerjadin[index].id,
                                );
                              },
                            ),
                          );
                        }, childCount: controller.tempSearchPerjadin.length),
                      ),
                    )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: controller.fetchSuratPerjadin(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'Terjadi kesalahan: ${snapshot.error}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          );
                        }

                        final data = snapshot.data!;
                        if (data.docs.isEmpty) {
                          return SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'Tidak ada perjadin yang tersedia',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          );
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final perjadin = data.docs;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade200,
                                    child: Icon(
                                      Icons.work_history_rounded,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  title: Text(
                                    controller.capitalizeEachWord(
                                      perjadin[index]['peserta'][0]["namapegawai"],
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "No.SPD : ${perjadin[index]['nospd']}",
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  onTap: () {
                                    operatorC.getPerjadin(perjadin[index].id);
                                    Get.toNamed(
                                      Routes.EDIT_PERJADIN,
                                      arguments: perjadin[index].id,
                                    );
                                  },
                                ),
                              );
                            }, childCount: data.docs.length),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(Routes.TAMBAH_PERJADIN),
        backgroundColor: Colors.blue.shade400,
        child: const Icon(Icons.add, color: Colors.white),
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
