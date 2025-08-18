import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:perjadin_kpu/app/modules/ppk/controllers/ppk_controller.dart';

class DetailppkView extends GetView<PpkController> {
  DetailppkView({super.key});
  final idPerjadin = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            "Detail Perjalanan",
            style: TextStyle(color: Colors.blue.shade400, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.blue.shade400,
            onPressed: () {
              controller.clearExpanded();
              Get.back();
            },
          ),
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: controller.getPerjadin(idPerjadin),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data?.data() == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data()!;
            final pesertaList = data["peserta"] as List<dynamic>? ?? [];

            final pesertaWidgets =
                pesertaList.map<Widget>((peserta) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade400,
                          child: Text(
                            "${peserta["namapegawai"]?.substring(0, 1).toUpperCase() ?? ""}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.capitalizeEachWord(
                                  peserta["namapegawai"] ?? "",
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text("NIP. ${peserta["nippegawai"] ?? ""}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  // ListTile(
                  //   contentPadding: EdgeInsets.zero,
                  //   leading: CircleAvatar(
                  //     backgroundColor: Colors.blue.shade400,
                  //     child: Text(
                  //       "${peserta["namapegawai"]?.substring(0, 1).toUpperCase() ?? ""}",
                  //       style: const TextStyle(color: Colors.white),
                  //     ),
                  //   ),
                  //   title: Text(
                  //     controller.capitalizeEachWord(
                  //       peserta["namapegawai"] ?? "",
                  //     ),
                  //     style: const TextStyle(fontWeight: FontWeight.w600),
                  //   ),
                  //   subtitle: Text("NIP. ${peserta["nip"] ?? ""}"),
                  // );
                }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  expandedInfoTile(
                    "Atas Perintah",
                    "${data["suratperintah"].toUpperCase()}",
                    "perintah",
                    Icons.assignment,
                  ),
                  expandedInfoTile(
                    "Maksud Perjalanan",
                    "${data["maksudperjalanan"]}",
                    "tujuan",
                    Icons.directions_car,
                  ),
                  expandedInfoTile(
                    "Sarana",
                    "${data["sarana"]}",
                    "sarana",
                    Icons.car_rental,
                  ),
                  expandedInfoTile(
                    "Lokasi",
                    "${data["tempatberangkat"].toUpperCase()} - ${data["tempattujuan"].toUpperCase()}",
                    "berangkat",
                    Icons.place,
                  ),
                  expandedInfoTile(
                    "Tanggal Berangkat",
                    DateFormat(
                      "dd MMMM yyyy",
                    ).format((data["tanggalberangkat"] as Timestamp).toDate()),
                    "tgl_berangkat",
                    Icons.calendar_month,
                  ),
                  expandedInfoTile(
                    "Tanggal Kembali",
                    DateFormat(
                      "dd MMMM yyyy",
                    ).format((data["tanggalkembali"] as Timestamp).toDate()),
                    "tgl_kembali",
                    Icons.calendar_month,
                  ),
                  expandedInfoTile(
                    "Peserta",
                    "",
                    "peserta_list",
                    Icons.people,
                    detail: pesertaWidgets,
                  ),
                  data["disetujuippk"] == "true" ||
                          data["disetujuippk"] == "false"
                      ? data["disetujuippk"] == "true"
                          ? Container(
                            width: Get.width,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "SPT ini telah disetujui",
                              style: TextStyle(
                                color: Colors.green,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                          : Container(
                            width: Get.width,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "SPT ini ditolak",
                              style: TextStyle(
                                color: Colors.red,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade400,
                              side: BorderSide(color: Colors.blue.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              controller.persetujuanPerjadin(idPerjadin, true);
                            },
                            child: const Text('Setujui'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade400,
                              side: BorderSide(color: Colors.red.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              controller.persetujuanPerjadin(idPerjadin, false);
                            },
                            child: const Text('Tolak'),
                          ),
                        ],
                      ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget expandedInfoTile(
    String label,
    String value,
    String key,
    IconData icon, {
    List<Widget>? detail,
  }) {
    return Obx(() {
      final isExpanded =
          controller.expandedItems.putIfAbsent(key, () => false.obs).value;

      return Column(
        children: [
          InkWell(
            onTap: () => controller.toggleItem(key),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade400,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(10),
                  bottom: Radius.circular(isExpanded ? 0 : 10),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.expand_more, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState:
                isExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: detail ?? [Text(value)],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
        ],
      );
    });
  }
}
