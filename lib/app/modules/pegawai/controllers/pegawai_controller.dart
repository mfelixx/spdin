import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';
import 'package:perjadin_kpu/app/modules/auth/controllers/auth_controller.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class PegawaiController extends GetxController {
  final db = FirebaseFirestore.instance;
  final _authC = Get.find<AuthController>();

  RxList<String> uploadedImageUrls = <String>[].obs;
  final isUploading = false.obs;
  late MultiImagePickerController pickerController;

  final dio = Dio();

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

  Stream<List<QueryDocumentSnapshot>> fetchPegawai() {
    return db.collection("surat_perjadin").snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        if (doc.data().toString().contains("peserta")) {
          List<dynamic> peserta = doc["peserta"];
          return peserta.any(
            (p) => p["nippegawai"] == _authC.currentUser.value,
          );
        }
        return false;
      }).toList();
    });
  }

  @override
  void onInit() {
    super.onInit();
    pickerController = MultiImagePickerController(
      maxImages: 12,
      picker: (int pickCount, Object? params) async {
        final picked = await ImagePicker().pickMultiImage();
        if (picked.isEmpty) return [];

        final existing = pickerController.images.map((e) => e.path).toSet();
        final newFiles =
            picked.where((e) => !existing.contains(e.path)).toList();

        return newFiles.map((e) {
          final name = path.basename(e.path);
          final ext = name.split('.').last;
          return ImageFile(
            UniqueKey().toString(), // Wajib, untuk key image
            name: name,
            extension: ext,
            path: e.path,
          );
        }).toList();
      },
    );
  }

  Future<String?> uploadImageToCloudinary({
    required File imageFile,
    required String idPerjadin,
    required String nipPegawai,
  }) async {
    try {
      String cloudName = 'dyftcc4nj';
      String uploadPreset = 'perjadin';
      String url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

      // String timestamp = DateFormat('yyyyMMdd_HHmmsss').format(DateTime.now());
      String uniqueId = Uuid().v4();

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
        'upload_preset': uploadPreset,
        'folder': "spj/$idPerjadin/$nipPegawai",
        'public_id': '${nipPegawai}_$uniqueId',
      });

      final res = await dio
          .post(url, data: formData)
          .timeout(Duration(seconds: 30));

      if (res.statusCode == 200 &&
          res.data != null &&
          res.data['secure_url'] != null) {
        return res.data["secure_url"];
      } else {
        print('Upload gagal: ${res.statusCode} - ${res.data}');
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> uploadMultipleImages({
    required String perjadinId,
    required String nipPegawai,
  }) async {
    if (pickerController.images.isEmpty) return;

    isUploading.value = true;

    List<Future<String?>> uploadTasks = [];

    for (var imageFile in pickerController.images) {
      File file = File(imageFile.path!);
      uploadTasks.add(
        uploadImageToCloudinary(
          imageFile: file,
          idPerjadin: perjadinId,
          nipPegawai: nipPegawai,
        ),
      );
    }

    // Tunggu semua upload selesai
    final results = await Future.wait(uploadTasks);

    // Ambil hanya url yang tidak null
    final imageUrl = results.whereType<String>().toList();

    print(imageUrl);

    if (imageUrl.isNotEmpty) {
      final docRef =
          await db
              .collection('surat_perjadin')
              .doc(perjadinId)
              .collection('spj')
              .doc(nipPegawai)
              .get();

      List<dynamic> existingImages = [];

      if (docRef.exists && docRef.data()!.containsKey('buktiperjalanan')) {
        existingImages = docRef.data()!['buktiperjalanan'] ?? [];
      }

      // Gabungkan gambar lama dengan gambar baru
      List<String> updatedImages = [
        ...existingImages.map(
          (e) => e.toString(),
        ), // pastikan semua dalam format String
        ...imageUrl,
      ];

      await db
          .collection('surat_perjadin')
          .doc(perjadinId)
          .collection('spj')
          .doc(nipPegawai)
          .update({'buktiperjalanan': updatedImages});

      uploadedImageUrls.assignAll(updatedImages);
      Get.snackbar('Berhasil', 'Semua gambar berhasil diupload');
    } else {
      Get.snackbar('Gagal', 'Tidak ada gambar yang berhasil diupload');
    }

    isUploading.value = false;
    pickerController.clearImages();
  }

  Future<void> loadExistingImages({
    required String perjadinId,
    required String nipPegawai,
  }) async {
    final snapshot =
        await db
            .collection('surat_perjadin')
            .doc(perjadinId)
            .collection('spj')
            .doc(nipPegawai)
            .get();

    if (snapshot.exists && snapshot.data()!.containsKey('buktiperjalanan')) {
      List<dynamic> existingImages = snapshot.data()!['buktiperjalanan'] ?? [];
      uploadedImageUrls.assignAll(existingImages.cast<String>());
    } else {
      uploadedImageUrls.clear();
    }
  }

  Future<void> removeImage({
    required String perjadinId,
    required String nipPegawai,
    required String imageUrl,
  }) async {
    final docRef = db
        .collection('surat_perjadin')
        .doc(perjadinId)
        .collection('spj')
        .doc(nipPegawai);

    final snapshot = await docRef.get();

    if (snapshot.exists && snapshot.data()!.containsKey('buktiperjalanan')) {
      List<dynamic> existingImages = snapshot.data()!['buktiperjalanan'] ?? [];
      existingImages.remove(imageUrl);

      await docRef.update({'buktiperjalanan': existingImages});
      uploadedImageUrls.assignAll(existingImages.cast<String>());

      Get.snackbar('Berhasil', 'Gambar berhasil dihapus');
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    pickerController.dispose();
  }
}
