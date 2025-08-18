import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:perjadin_kpu/app/modules/operator/controllers/operator_controller.dart';
import 'package:perjadin_kpu/app/routes/app_pages.dart';

class SpjView extends GetView<OperatorController> {
  SpjView({super.key});
  final perjadinId = Get.arguments["perjadinId"];
  final nipPegawai = Get.arguments["nipPegawai"];
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) return;
        if (result == true) {
          controller.updateSpj(perjadinId, nipPegawai);
        } else {
          controller.clearFieldSPJ();
        }
      },

      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF78C7FF),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () => Get.back(),
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
              onPressed: () => controller.generateSPJ(perjadinId, nipPegawai),
              child: Row(
                children: [
                  const Icon(Icons.file_download),
                  const SizedBox(width: 2),
                  const Text("SPJ"),
                ],
              ),
            ),
          ],
        ),
        body: StreamBuilder<Map<String, dynamic>>(
          stream: controller.getSpj(perjadinId, nipPegawai),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final user = data["user"];
            final perjadin = data["perjadin"];
            final tanggalBerangkat = DateFormat(
              "dd MMMM yyyy",
            ).format(perjadin["tanggalberangkat"].toDate());
            final tanggalKembali = DateFormat(
              "dd MMMM yyyy",
            ).format(perjadin["tanggalkembali"].toDate());

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nomor SPD : ${perjadin['nospd']}"),
                  Text("Atas Nama : ${user['namapegawai']}"),
                  Text("Tanggal : $tanggalBerangkat - $tanggalKembali"),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText("Uang Harian"),
                            uangField(controller.uangHarianT),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText("Berapa hari?"),
                            uangField(controller.jumlahHariUangHarianT),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText("Uang Fullbord"),
                            uangField(controller.uangFullBordT),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText("Berapa hari?"),
                            uangField(controller.jumlahHariFullbordT),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText("Uang Penginapan"),
                            uangField(controller.uangPenginapanT),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText("Uang Transportasi"),
                            uangField(controller.uangTransportasiT),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText("Uang Tiket Pesawat PP"),
                            uangField(controller.uangTiketPesawatT),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText("Representasi"),
                            uangField(controller.representasiT),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Obx(() {
                    return Text(
                      "Total : ${controller.formatCurrency(controller.totalSpj.value)}",
                    );
                  }),

                  SizedBox(height: 30),
                  SizedBox(
                    width: context.isLandscape ? 200 : double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF78C7FF),
                        padding: const EdgeInsets.symmetric(horizontal: 50),
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

                  SizedBox(
                    width: context.isLandscape ? 200 : double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF78C7FF),
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed:
                          () => Get.toNamed(
                            Routes.UPLOAD_SPJ,
                            arguments: {
                              "perjadinId": perjadinId,
                              "nipPegawai": nipPegawai,
                            },
                          ),
                      child: const Text(
                        'Bukti',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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

  Widget uangField(TextEditingController textController) {
    return TextField(
      controller: textController,
      keyboardType: TextInputType.number,

      decoration: InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        prefixText:
            textController == controller.jumlahHariFullbordT ||
                    textController == controller.jumlahHariUangHarianT
                ? ""
                : "Rp ",
      ),
      inputFormatters: [
        CurrencyInputFormatter(
          thousandSeparator: ThousandSeparator.Period,
          useSymbolPadding: false,
          mantissaLength: 0,
        ),
      ],
      onChanged: (_) {
        controller.calculateTotal();
        controller.update();
      },
    );
  }
}
