import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:perjadin_kpu/app/modules/operator/controllers/operator_controller.dart';
// import 'package:printing/printing.dart';

class PdfpreviewView extends GetView<OperatorController> {
  PdfpreviewView({super.key});
  // final perjadinId = Get.arguments['perjadinId'] ?? "";
  // final nipPegawai = Get.arguments['nipPegawai'] ?? "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: PdfPreview(
      //   build:
      //       (format) => controller.generateSPD2(format, nipPegawai, perjadinId),
      //   allowPrinting: true,
      //   allowSharing: false,
      //   canChangeOrientation: true,
      //   canChangePageFormat: true,
      // ),
    );
  }
}
