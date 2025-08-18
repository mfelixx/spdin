import 'package:get/get.dart';

import '../controllers/ppk_controller.dart';

class PpkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PpkController>(
      () => PpkController(),
    );
  }
}
