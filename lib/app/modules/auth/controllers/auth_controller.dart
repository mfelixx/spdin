import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:perjadin_kpu/app/routes/app_pages.dart';

class AuthController extends GetxController {
  late TextEditingController emailT;
  late TextEditingController passwordT;
  final isObscureText = true.obs;
  final authError = false.obs;
  var isAuth = false.obs;
  var role = "".obs;
  var currentUser = "".obs;
  var currentRoute;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  bool validationEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  Future<void> login(String email, String password) async {
    if (!validationEmail(email)) {
      authError.value = true;
      return;
    }

    authError.value = false;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      isAuth.value = true;

      final userId = _auth.currentUser!.uid;
      final doc = await db.collection("users").doc(userId).get();
      if (doc.exists) {
        final currentUser = doc.data()!;
        role.value = currentUser["role"];
      }
      Get.snackbar("Sukses", "Berhasil masuk");
      currentUser.value = doc.data()!["nippegawai"];
      print(currentUser.value);
      _navigateBasedOnRole();
    } catch (e) {
      Get.snackbar("Terjadi kesalahan", "Email atau kata sandi salah");
    }
    isObscureText.value = true;
    emailT.clear();
    passwordT.clear();
  }

  Future<void> simpanFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (token != null && uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcm_token': token,
      });
    }
  }

  void _navigateBasedOnRole() {
    if (role.value == "admin") {
      Get.offAllNamed(Routes.ADMIN);
      currentRoute = Routes.ADMIN;
    } else if (role.value == "operator") {
      Get.offAllNamed(Routes.OPERATOR);
      currentRoute = Routes.OPERATOR;
    } else if (role.value == "ppk") {
      simpanFcmToken();
      Get.offAllNamed(Routes.PPK);
      currentRoute = Routes.PPK;
    } else if (role.value == "pegawai") {
      Get.offAllNamed(Routes.PEGAWAI);
    }
  }

  Future<void> autoLogin() async {
    final user = _auth.currentUser;

    if (user != null) {
      final doc = await db.collection("users").doc(user.uid).get();

      if (doc.exists) {
        role.value = doc.data()!["role"];
        currentUser.value = doc.data()!["nippegawai"];
        _navigateBasedOnRole();
      } else {
        Get.offAllNamed(Routes.AUTH);
      }
    } else {
      // Kalau belum login, arahkan ke login
      Get.offAllNamed(Routes.AUTH);
    }
  }

  Future<void> logout() async {
    await Get.defaultDialog(
      title: 'Konfirmasi',
      content: Text('Apakah Anda yakin ingin keluar?'),
      textCancel: 'Batal',
      textConfirm: 'Ya',
      onConfirm: () {
        _auth.signOut();
        isAuth.value = false;
        role.value = "";
        currentUser.value = "";
        currentRoute = Routes.AUTH;
        Get.offAllNamed(Routes.AUTH);
      },
      onCancel: () => Get.back(),
    );
  }

  @override
  void onInit() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    emailT = TextEditingController();
    passwordT = TextEditingController();
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    emailT.dispose();
    passwordT.dispose();
    super.onClose();
  }
}

class SplashscreenController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  final authC = Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeIn),
    );

    animationController.forward();

    // Delay 3 detik sebelum autoLogin
    Timer(const Duration(seconds: 3), () {
      authC.autoLogin();
    });
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
