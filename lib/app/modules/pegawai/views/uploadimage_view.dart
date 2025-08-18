import 'dart:io';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';
import 'package:perjadin_kpu/app/modules/pegawai/controllers/pegawai_controller.dart';
import 'package:perjadin_kpu/app/modules/pegawai/views/fullimage_view.dart';

class UploadimageView extends GetView<PegawaiController> {
  UploadimageView({super.key});
  final idPerjadin = Get.arguments['perjadinId'];
  final pegawaiNip = Get.arguments['nipPegawai'];
  @override
  Widget build(BuildContext context) {
    controller.loadExistingImages(
      perjadinId: idPerjadin,
      nipPegawai: pegawaiNip,
    );
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;
        if (result == true) {
          await controller.uploadMultipleImages(
            perjadinId: idPerjadin,
            nipPegawai: pegawaiNip,
          );
        } else {
          controller.pickerController.clearImages();
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
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Expanded(
                  child: MultiImagePickerView(
                    controller: controller.pickerController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    builder: (context, imageFile) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image:
                                  imageFile.hasPath
                                      ? DecorationImage(
                                        image: FileImage(File(imageFile.path!)),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                !imageFile.hasPath
                                    ? const Icon(Icons.image)
                                    : null,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap:
                                  () => controller.pickerController.removeImage(
                                    imageFile,
                                  ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    addMoreButton: DefaultAddMoreWidget(
                      icon: const Icon(Icons.add_photo_alternate),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2),
                    ),
                    initialWidget: DefaultInitialWidget(
                      centerWidget: const Icon(Icons.image_search),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.05),
                    ),
                  ),
                ),
              ),
              Obx(() {
                return controller.isUploading.value
                    ? const CircularProgressIndicator()
                    : SizedBox(
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
                          'Upload Gambar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
              }),

              Expanded(
                child: Obx(() {
                  if (controller.uploadedImageUrls.isEmpty) {
                    return const Center(child: Text('Belum ada gambar'));
                  }
                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: controller.uploadedImageUrls.length,
                      itemBuilder: (context, index) {
                        final url = controller.uploadedImageUrls[index];
                        return GestureDetector(
                          onTap:
                              () => Get.to(() => FullimageView(imageUrl: url)),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(url),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap:
                                      () => controller.removeImage(
                                        perjadinId: idPerjadin,
                                        nipPegawai: pegawaiNip,
                                        imageUrl: url,
                                      ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
