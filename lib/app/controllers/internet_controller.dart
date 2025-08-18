import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class InternetController extends GetxController {
  var isConnected = true.obs;
  final Connectivity _connectivity = Connectivity();
  Timer? _cooldownTimer;
  final GetConnect _getConnect = GetConnect();

  Future<void> _checkInternetAccess() async {
    try {
      final response = await _getConnect
          .get('https://www.google.com')
          .timeout(Duration(seconds: 3));
      bool connected = response.statusCode == 200;

      if (connected != isConnected.value) {
        isConnected.value = connected;
        _showToast(connected);
      }
    } catch (_) {
      if (isConnected.value != false) {
        isConnected.value = false;
        _showToast(false);
      }
    }
  }

  void _showToast(bool isConnected) {
    if (_cooldownTimer?.isActive ?? false) return;

    Fluttertoast.showToast(
      msg:
          isConnected
              ? "Koneksi Internet Tersambung"
              : "Tidak Ada Koneksi Internet",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor:
          isConnected ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 16.0,
    );

    _cooldownTimer = Timer(Duration(seconds: 3), () {});
  }

  @override
  void onInit() {
    super.onInit();
    _checkInternetAccess(); // Cek awal
    _connectivity.onConnectivityChanged.listen((_) {
      _checkInternetAccess(); // Cek ulang setiap koneksi berubah
    });
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
