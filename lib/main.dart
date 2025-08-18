import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:perjadin_kpu/app/controllers/internet_controller.dart';
import 'package:perjadin_kpu/app/modules/auth/controllers/auth_controller.dart';
import 'package:perjadin_kpu/app/modules/auth/controllers/setupfcm_controller.dart';
import 'package:perjadin_kpu/firebase_options.dart';
// import 'package:get_storage/get_storage.dart';
import 'app/routes/app_pages.dart';

void main() async {
  Get.put(InternetController());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put(AuthController());
  Get.put(SetupfcmController());
  // await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final authC = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.SPLASHSCREEN,
      getPages: AppPages.routes,
      theme: ThemeData(
        fontFamily: 'Lato',
        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}
