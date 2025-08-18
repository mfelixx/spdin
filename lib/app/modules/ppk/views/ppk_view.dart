import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:get/get.dart';
import 'package:perjadin_kpu/app/modules/auth/controllers/auth_controller.dart';
import 'package:perjadin_kpu/app/modules/pegawai/views/perjadinku_view.dart';

import '../controllers/ppk_controller.dart';

class PpkView extends GetView<PpkController> {
  PpkView({super.key});
  final authC = Get.find<AuthController>();
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
      body: Obx(
        () =>
            controller.currentPage.value == 0
                ? _listPerjadin()
                : PerjadinkuView(),
      ),
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
        ],
      ),
    );
  }

  Widget _listPerjadin() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black12,
              //     blurRadius: 8,
              //     offset: const Offset(0, 4),
              //   ),
              // ],
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
                  ),
                ),
              ],
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: controller.fetchSuratPerjadin(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
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
                  delegate: SliverChildBuilderDelegate((context, index) {
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
                        trailing:
                            perjadin[index]['readBy']['ppk'] == false
                                ? Icon(Icons.fiber_new, color: Colors.red)
                                : null,
                        subtitle: Text(
                          "No.SPD : ${perjadin[index]['nospd']}",
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        onTap: () {
                          controller.tandaiSudahDibaca(perjadin[index].id);
                        },

                        // onLongPress:
                        //     () => Get.defaultDialog(
                        //       title: 'Konfirmasi',
                        //       content: Text(
                        //         'Apakah anda yakin ingin menghapus?',
                        //       ),
                        //       textCancel: 'Batal',
                        //       textConfirm: 'Ya',
                        //       onConfirm: () {
                        //         // controller.deletePerjadin(perjadin[index].id);
                        //         Get.back();
                        //       },
                        //     ),
                      ),
                    );
                  }, childCount: data.docs.length),
                ),
              );
            } else if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            }
            return SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ],
    );
  }
}
