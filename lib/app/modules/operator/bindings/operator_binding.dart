import 'package:get/get.dart';

import '../controllers/operator_controller.dart';

class OperatorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OperatorController>(
      () => OperatorController(),
    );
  }
}
