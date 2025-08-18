import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:perjadin_kpu/app/routes/app_pages.dart';
import 'package:permission_handler/permission_handler.dart';

class SetupfcmController extends GetxController {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void setupFCM() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    await FirebaseMessaging.instance.requestPermission();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Navigasi dari notifikasi
        final payload = response.payload;
        if (payload != null && payload.startsWith("id=")) {
          final id = payload.replaceFirst("id=", "");
          Get.toNamed(Routes.DETAIL_PERJADIN, arguments: id);
        }
      },
    );

    // saat foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id', // harus sesuai dengan channel yang diset di AndroidManifest
              'Notifikasi SPJ',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload:
              message.data['id_perjadin'] != null
                  ? 'id=${message.data['id_perjadin']}'
                  : null,
        );
      }
    });

    // saat background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['id_perjadin'] != null) {
        final id = message.data['id_perjadin'];
        Get.toNamed(Routes.DETAIL_PERJADIN, arguments: id);
      }
    });

    // saat terminated
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null && message.data['id_perjadin'] != null) {
        final id = message.data['id_perjadin'];
        Get.toNamed(Routes.DETAIL_PERJADIN, arguments: id);
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    setupFCM();
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
