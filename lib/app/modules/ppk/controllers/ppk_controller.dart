import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:perjadin_kpu/app/routes/app_pages.dart';

class PpkController extends GetxController {
  final db = FirebaseFirestore.instance;
  var expandedItems = <String, RxBool>{
    'perintah': false.obs,
    'sarana': false.obs,
    'berangkat': false.obs,
    'tujuan': false.obs,
    'tgl_berangkat': false.obs,
    'tgl_kembali': false.obs,
    'peserta_list': false.obs,
  };

  var currentPage = 0.obs;

  void toggleItem(String key) {
    if (expandedItems.containsKey(key)) {
      expandedItems[key]!.toggle();
    }
  }

  void clearExpanded() {
    expandedItems.forEach((key, value) {
      value.value = false;
    });
  }

  void changePage(int index) {
    currentPage.value = index;
  }

  String capitalizeEachWord(String input) {
    return input
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : '',
        )
        .join(' ');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchSuratPerjadin() {
    return db.collection("surat_perjadin").orderBy("readBy.ppk").snapshots();
  }

  void tandaiSudahDibaca(String id) async {
    await FirebaseFirestore.instance
        .collection('surat_perjadin')
        .doc(id)
        .update({'readBy.ppk': true});
    Get.toNamed(Routes.DETAIL_PERJADIN, arguments: id);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getPerjadin(String id) {
    return db.collection("surat_perjadin").doc(id).snapshots();
  }

  void persetujuanPerjadin(String id, bool persetujuan) async {
    if (persetujuan) {
      await FirebaseFirestore.instance
          .collection('surat_perjadin')
          .doc(id)
          .update({"disetujuippk": "true"});
    } else {
      await FirebaseFirestore.instance
          .collection('surat_perjadin')
          .doc(id)
          .update({"disetujuippk": "false"});
    }

    Get.toNamed(Routes.DETAIL_PERJADIN, arguments: id);
  }

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
