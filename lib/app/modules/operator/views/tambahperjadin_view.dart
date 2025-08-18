import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:perjadin_kpu/app/modules/operator/controllers/operator_controller.dart';

class TambahperjadinView extends GetView<OperatorController> {
  TambahperjadinView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) return;
        if (result == true) {
          controller.simpanPerjadin();
        } else {
          controller.clearFields();
        }
      },
      child: SafeArea(
        top: false,
        child: Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.blue.shade400,
              onPressed: () {
                controller.clearFields();
                Get.back();
              },
            ),
          ),

          body: StreamBuilder(
            stream: controller.fetchPegawai(),
            builder: (context, snapshot) {
              final pegawaiList = snapshot.data;
              return Obx(() {
                return CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText("Surat Perintah"),
                            _dropdown(
                              controller.suratPerintah.value,
                              ["Ketua KPU", "Sekretaris KPU"],
                              (val) {
                                controller.suratPerintah.value = val!;
                              },
                            ),

                            const SizedBox(height: 30),
                            _labelText("Peserta :"),
                            ...List.generate(controller.peserta.length, (
                              index,
                            ) {
                              final isDuplicate = (String? val) {
                                if (val == null) return false;
                                return controller.peserta
                                        .where(
                                          (e) =>
                                              e != null &&
                                              e["namapegawai"] == val,
                                        )
                                        .length >
                                    0;
                              };

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _dropdown(
                                        controller
                                                .peserta[index]?["namapegawai"] ??
                                            "",
                                        pegawaiList
                                                ?.map(
                                                  (e) =>
                                                      e['namapegawai']
                                                          as String,
                                                )
                                                .toList() ??
                                            [],
                                        (val) {
                                          if (isDuplicate(val)) {
                                            controller.doublePeserta.value =
                                                true;
                                          } else {
                                            controller.doublePeserta.value =
                                                false;
                                          }
                                          final selected = pegawaiList!
                                              .firstWhere(
                                                (e) => e['namapegawai'] == val,
                                              );
                                          controller.peserta[index] = selected;
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        if (controller.doublePeserta.value ==
                                            true)
                                          controller.doublePeserta.value =
                                              false;
                                        controller.hapusPeserta(index);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),

                            controller.doublePeserta.value
                                ? const Text(
                                  "Peserta sudah ada",
                                  style: TextStyle(color: Colors.red),
                                )
                                : const SizedBox.shrink(),

                            controller.peserta.length < 5
                                ? ElevatedButton.icon(
                                  onPressed: controller.tambahPeserta,
                                  icon: Icon(Icons.add),
                                  label: Text(
                                    "Tambah Peserta",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    iconColor: Colors.white,
                                    backgroundColor: Color(0xFF78C7FF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                )
                                : SizedBox.shrink(),

                            SizedBox(height: 30),
                            _labelText("Maksud Perjalanan"),
                            TextField(
                              maxLines: 3,
                              controller: controller.maksudPerjalananT,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Maksud Perjalanan",
                              ),
                            ),

                            SizedBox(height: 30),
                            _labelText("Tempat Berangkat"),
                            TextField(
                              controller: controller.tempatBerangkatT,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Tempat Berangkat",
                              ),
                            ),

                            SizedBox(height: 30),
                            _labelText("Tempat Tujuan"),
                            TextField(
                              controller: controller.tempatTujuanT,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Tempat Tujuan",
                              ),
                            ),

                            SizedBox(height: 30),
                            InkWell(
                              onTap: () => controller.datePicker(context, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: "Tanggal Berangkat",
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  controller.tanggalBerangkat.value == null
                                      ? ""
                                      : DateFormat("dd MMMM yyyy").format(
                                        controller.tanggalBerangkat.value!,
                                      ),
                                ),
                              ),
                            ),

                            SizedBox(height: 30),
                            InkWell(
                              onTap:
                                  () => controller.datePicker(context, false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: "Tanggal Pulang",
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  controller.tanggalKembali.value == null
                                      ? ""
                                      : DateFormat("dd MMMM yyyy").format(
                                        controller.tanggalKembali.value!,
                                      ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),
                            SizedBox(
                              width:
                                  context.isLandscape ? 200 : double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF78C7FF),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 50,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => Get.back(result: true),
                                child: const Text(
                                  'Simpan',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _labelText(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _dropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      itemHeight: 50,
      isExpanded: true,
      decoration: InputDecoration(border: OutlineInputBorder()),
      hint: const Text("Pilih"),
      items:
          items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}
