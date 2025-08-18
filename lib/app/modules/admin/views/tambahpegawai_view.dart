import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:perjadin_kpu/app/modules/admin/controllers/admin_controller.dart';
import 'package:perjadin_kpu/app/utils/struktural_kpu.dart';

class TambahpegawaiView extends StatefulWidget {
  const TambahpegawaiView({super.key});

  @override
  State<TambahpegawaiView> createState() => _TambahpegawaiViewState();
}

class _TambahpegawaiViewState extends State<TambahpegawaiView> {
  final controller = Get.put(AdminController());
  List<String> jenjangList = ["Juru", "Pengatur", "Penata", "Pembina"];
  List<String> jabatanList = ["Ketua KPU", "Sekretaris KPU", "Tidak ada"];
  List<String> roleList = ["Admin", "Pegawai", "Operator", "PPK"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.white, // Background status bar
          statusBarIconBrightness: Brightness.dark, // Ikon gelap
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) return;
        if (result == true) {
          await controller.tambahPegawai();
        } else {
          controller.clearAllFields();
        }
      },
      child: Obx(
        () => SafeArea(
          child: Scaffold(
            appBar: AppBar(
              forceMaterialTransparency: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.blue.shade400,
                onPressed: () {
                  Get.back();
                },
              ),
            ),
            body: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _labelText("Nama Pegawai"),
                          _textField(
                            "Masukkan nama pegawai",
                            controller.namaPegawaiT,
                          ),

                          const SizedBox(height: 30),
                          _labelText("Email Pegawai"),
                          _textField(
                            "Masukkan email pegawai",
                            controller.emailPegawai,
                          ),

                          const SizedBox(height: 30),
                          _labelText("NIP Pegawai"),
                          _textField(
                            "Masukkan nip pegawai",
                            controller.nipPegawaiT,
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(child: _labelText("Jabatan")),
                              const SizedBox(width: 10),
                              Expanded(
                                child: dropdown(
                                  controller.jabatan.value,
                                  StrukturKPU.jabatanStruktural,
                                  (val) {
                                    controller.jabatan.value = val!;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(child: _labelText("Divisi")),
                              const SizedBox(width: 10),
                              Expanded(
                                child: dropdown(
                                  controller.divisi.value,
                                  StrukturKPU.divisi,
                                  (val) {
                                    controller.divisi.value = val!;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(
                                child: _labelText("Pangkat / Golongan Pegawai"),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: dropdown(
                                  controller.pangkat.value,
                                  StrukturKPU.golongan,
                                  (val) {
                                    controller.pangkat.value = val!;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(child: _labelText("Role")),
                              const SizedBox(width: 10),
                              Expanded(
                                child: dropdown(
                                  controller.role.value,
                                  StrukturKPU.role,
                                  (val) => controller.role.value = val!,
                                ),
                              ),
                            ],
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 30),
                              _labelText("Password Pegawai"),
                              _textField(
                                "Masukkan password pegawai",
                                controller.passwordT,
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),
                          SizedBox(
                            width: context.isLandscape ? 200 : double.infinity,
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
                ),
              ],
            ),
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

  Widget _textField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: hint == "Masukkan password pegawai" ? true : false,
      keyboardType:
          hint == "Masukkan nip pegawai" ? TextInputType.number : null,

      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget dropdown(
    String? value,
    List<String> itemsList,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      width: 50,
      child: DropdownSearch<String>(
        popupProps: PopupProps.menu(
          showSearchBox: true,
          fit: FlexFit.loose,
          constraints: BoxConstraints(minWidth: 300),
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              labelText: "Cari",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            label: Text("Pilih"),
            border: OutlineInputBorder(),
          ),
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
      ),
    );
  }
}
