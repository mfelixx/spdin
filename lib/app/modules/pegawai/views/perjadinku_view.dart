import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:perjadin_kpu/app/modules/auth/controllers/auth_controller.dart';
import 'package:perjadin_kpu/app/modules/pegawai/controllers/pegawai_controller.dart';
import 'package:perjadin_kpu/app/routes/app_pages.dart';

class PerjadinkuView extends GetView {
  PerjadinkuView({super.key});
  final pegawaiC = Get.put(PegawaiController());
  final authC = Get.find<AuthController>();
  @override
  Widget build(BuildContext context) {
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
        StreamBuilder<List<QueryDocumentSnapshot>>(
          stream: pegawaiC.fetchPegawai(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data!;
              if (data.isEmpty) {
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
                    final perjadinId = data[index];
                    final perjadin = data[index].data() as Map<String, dynamic>;

                    final peserta = perjadin['peserta'] as List<dynamic>;
                    final currentUser = peserta.firstWhere(
                      (p) => p['nippegawai'] == authC.currentUser.value,
                      orElse: () => null,
                    );

                    // Ambil nippegawai jika ditemukan
                    final nipPegawai =
                        currentUser != null ? currentUser['nippegawai'] : '';

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
                          perjadin["nospd"],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "${DateFormat("dd MMMM yyyy").format(perjadin["tanggalberangkat"].toDate())} - ${DateFormat("dd MMMM yyyy").format(perjadin["tanggalkembali"].toDate())}",
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        onTap:
                            () => Get.toNamed(
                              Routes.UPLOAD_SPJ,
                              arguments: {
                                "perjadinId": perjadinId.id,
                                "nipPegawai": nipPegawai,
                              },
                            ),
                      ),
                    );
                  }, childCount: data.length),
                ),
              );
            } else if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(child: Text("Tidak ada perjadin yang sesuai")),
              );
            }

            return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ],
    );
  }
}
