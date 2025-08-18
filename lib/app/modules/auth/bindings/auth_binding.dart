import 'package:get/get.dart';

import 'package:perjadin_kpu/app/modules/auth/controllers/setupfcm_controller.dart';

import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SetupfcmController>(
      () => SetupfcmController(),
    );
    Get.lazyPut<AuthController>(
      () => AuthController(),
    );
  }
}
