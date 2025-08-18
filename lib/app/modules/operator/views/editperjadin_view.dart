import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:perjadin_kpu/app/modules/operator/controllers/operator_controller.dart';
import 'package:perjadin_kpu/app/routes/app_pages.dart';

class EditperjadinView extends GetView<OperatorController> {
  EditperjadinView({super.key});
  final perjadinId = Get.arguments;
  @override
  Widget build(BuildContext context) {
    controller.cekPersetujuan(perjadinId);
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) return;

        if (result == true) {
          controller.updatePerjadin(perjadinId);
        } else {
          controller.clearFields();
        }
      },
      child: SafeArea(
        top: false,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF78C7FF),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () {
                Get.back();
              },
            ),
            actionsPadding: const EdgeInsets.only(right: 16),
            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  controller.generateSPT(perjadinId);
                },
                child: Row(
                  children: [
                    const Icon(Icons.file_download),
                    const SizedBox(width: 2),
                    const Text("SPT"),
                  ],
                ),
              ),
            ],
          ),

          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: controller.fetchPegawai(),
            builder: (context, snapshot) {
              final pegawaiList = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return Obx(
                () => CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText("Surat Perintah"),

                            _dropdown(
                              controller.suratPerintah.value,
                              ["Ketua KPU", "Sekretaris KPU"],
                              (val) => controller.suratPerintah.value = val!,
                            ),
                            SizedBox(height: 30),
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
                                    SizedBox(
                                      width: 30,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(Icons.more_vert),
                                        onPressed: () async {
                                          final selected = await showMenu<
                                            String
                                          >(
                                            context: context,
                                            position: RelativeRect.fromLTRB(
                                              100,
                                              0,
                                              0,
                                              0,
                                            ),
                                            items:
                                                controller.persetujuan.value ==
                                                            "true" ||
                                                        controller
                                                                .persetujuan
                                                                .value ==
                                                            "none"
                                                    ? [
                                                      PopupMenuItem(
                                                        value: 'spd',
                                                        child: Text('SPD'),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'spj',
                                                        child: Text('SPJ'),
                                                      ),
                                                    ]
                                                    : [
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        child: Text('Delete'),
                                                      ),
                                                    ],
                                          );

                                          if (selected == 'spd') {
                                            controller.generateSPD2(
                                              controller
                                                  .peserta[index]?["nippegawai"],
                                              perjadinId,
                                            );
                                          } else if (selected == 'spj') {
                                            Get.toNamed(
                                              Routes.SPJ,
                                              arguments: {
                                                "perjadinId": perjadinId,
                                                "nipPegawai":
                                                    controller
                                                        .peserta[index]['nippegawai'],
                                              },
                                            );
                                          } else if (selected == 'delete') {
                                            if (controller
                                                    .doublePeserta
                                                    .value ==
                                                true)
                                              controller.doublePeserta.value =
                                                  false;
                                            controller.hapusPeserta(index);
                                          }
                                        },
                                      ),
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

                            controller.peserta.length < 5 &&
                                    controller.persetujuan.value == "false"
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
                              maxLength: 250,
                              enabled:
                                  controller.persetujuan.value == "true" ||
                                          controller.persetujuan.value == "none"
                                      ? false
                                      : true,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
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
                              enabled:
                                  controller.persetujuan.value == "true" ||
                                          controller.persetujuan.value == "none"
                                      ? false
                                      : true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Tempat Berangkat",
                              ),
                            ),

                            SizedBox(height: 30),
                            _labelText("Tempat Tujuan"),
                            TextField(
                              controller: controller.tempatTujuanT,
                              enabled:
                                  controller.persetujuan.value == "true" ||
                                          controller.persetujuan.value == "none"
                                      ? false
                                      : true,
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
                            controller.persetujuan.value == "false"
                                ? Column(
                                  children: [
                                    Container(
                                      width:
                                          context.isLandscape
                                              ? 200
                                              : double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "SPT ini ditolak.",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width:
                                          context.isLandscape
                                              ? 200
                                              : double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF78C7FF,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 50,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        onPressed: () => Get.back(result: true),
                                        child: const Text(
                                          'Ajukan Kembali',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                : const SizedBox.shrink(),
                            controller.persetujuan.value == "true"
                                ? Container(
                                  width:
                                      context.isLandscape
                                          ? 200
                                          : double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "SPT ini sudah disetujui PPK.",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                                : controller.persetujuan.value == "none"
                                ? Container(
                                  width:
                                      context.isLandscape
                                          ? 200
                                          : double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "SPT ini menunggu persetujuan PPK.",
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
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
    String? value,
    List<String> itemsList,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: true,
        fit: FlexFit.loose,
        constraints: BoxConstraints(minWidth: 300),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            labelText: "cari",
            border: OutlineInputBorder(),
          ),
        ),
      ),
      selectedItem: value!.isEmpty ? null : value.capitalizeFirst,
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(border: OutlineInputBorder()),
      ),
      dropdownBuilder: (context, selectedItem) {
        return Text(
          selectedItem ?? '',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      },
      items: (filter, infiniteScrollProps) {
        if (filter.isEmpty) {
          return itemsList;
        } else {
          return itemsList
              .where(
                (item) => item.toLowerCase().contains(filter.toLowerCase()),
              )
              .toList();
        }
      },
      onChanged: onChanged,
    );
  }
}
