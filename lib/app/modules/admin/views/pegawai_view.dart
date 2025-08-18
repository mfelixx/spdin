import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:perjadin_kpu/app/modules/admin/controllers/admin_controller.dart';
import 'package:perjadin_kpu/app/routes/app_pages.dart';

class PegawaiView extends GetView {
  PegawaiView({super.key});
  final _adminC = Get.find<AdminController>();
  @override
  Widget build(BuildContext context) {
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
                        hintText: 'Cari pegawai...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _adminC.searchUser(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Obx(
            () =>
                _adminC.tempSearch.isNotEmpty
                    ? SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, i) {
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
                                  Icons.people_alt,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              title: Text(
                                _adminC.capitalizeEachWord(
                                  _adminC.tempSearch[i]['namapegawai'],
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                "NIP. ${_adminC.tempSearch[i]['nippegawai']}",
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              onTap: () {
                                final userId = _adminC.tempSearch[i]['id'];
                                if (userId.isNotEmpty) {
                                  _adminC.getUser("$userId");
                                  Get.toNamed(
                                    Routes.ADMIN_EDITPEGAWAI,
                                    arguments: userId,
                                  );
                                }
                              },
                              onLongPress:
                                  () => Get.defaultDialog(
                                    title: 'Konfirmasi',
                                    content: Text(
                                      'Apakah anda yakin ingin menghapus?',
                                    ),
                                    textCancel: 'Batal',
                                    textConfirm: 'Ya',
                                    onConfirm: () {
                                      _adminC.deletePegawai(
                                        _adminC.tempSearch[i]['id'],
                                      );
                                      Get.back();
                                    },
                                  ),
                            ),
                          );
                        }, childCount: _adminC.tempSearch.length),
                      ),
                    )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _adminC.getAllUsers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.blue.shade400,
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
                            delegate: SliverChildBuilderDelegate((context, i) {
                              final user = snapshot.data!.docs;
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
                                      Icons.people_alt,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  title: Text(
                                    _adminC.capitalizeEachWord(
                                      user[i]['namapegawai'],
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "NIP. ${user[i]['nippegawai']}",
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  onTap: () {
                                    final userId = user[i].id;
                                    if (userId.isNotEmpty) {
                                      _adminC.getUser("$userId");
                                      Get.toNamed(
                                        Routes.ADMIN_EDITPEGAWAI,
                                        arguments: userId,
                                      );
                                    }
                                  },

                                  onLongPress:
                                      () => Get.defaultDialog(
                                        title: 'Konfirmasi',
                                        content: Text(
                                          'Apakah anda yakin ingin menghapus?',
                                        ),
                                        textCancel: 'Batal',
                                        textConfirm: 'Ya',
                                        onConfirm: () {
                                          _adminC.deletePegawai(user[i].id);
                                          Get.back();
                                        },
                                      ),
                                ),
                              );
                            }, childCount: snapshot.data!.docs.length),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(Routes.ADMIN_TAMBAHPEGAWAI);
        },
        backgroundColor: Colors.blue.shade400,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
