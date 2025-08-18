import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:perjadin_kpu/app/data/models/users_model.dart';

class AdminController extends GetxController {
  final currentTab = 0.obs;
  late TextEditingController namaPegawaiT;
  late TextEditingController emailPegawai;
  late TextEditingController nipPegawaiT;
  late TextEditingController passwordT;

  final jabatan = "".obs;
  final jenjang = "".obs;
  final pangkat = "".obs;
  final divisi = "".obs;
  final role = "".obs;
  final isi = [].obs;
  var initQuery = [].obs;
  var tempSearch = [].obs;
  var tempSearchPerjadin = [].obs;

  var users = UsersModel().obs;

  final FirebaseFirestore db = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  void changeTab(int index) {
    currentTab.value = index;
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

  void clearAllFields() {
    jabatan.value = "";
    divisi.value = "";
    pangkat.value = "";
    role.value = "";
    passwordT.clear();
    nipPegawaiT.clear();
    namaPegawaiT.clear();
    emailPegawai.clear();
  }

  Future<void> tambahPegawai() async {
    CollectionReference collectionUsers = db.collection("users");

    // Inisialisasi Secondary FirebaseApp
    final FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: Firebase.app().options,
    );

    // Gunakan Auth dari secondary app
    final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(
      app: secondaryApp,
    );

    final querySnap =
        await collectionUsers
            .where("emailpegawai", isEqualTo: emailPegawai.text)
            .get();

    final result = {
      "emailpegawai": emailPegawai.text,
      "namapegawai": namaPegawaiT.text,
      "nippegawai": nipPegawaiT.text,
      "jabatan": jabatan.value,
      "divisi": divisi.value,
      "pangkat": pangkat.value,
      "role": role.value.toLowerCase(),
      "password": passwordT.text,
    };

    if (querySnap.docs.isEmpty) {
      try {
        final UserCredential userCredential = await secondaryAuth
            .createUserWithEmailAndPassword(
              email: emailPegawai.text,
              password: passwordT.text,
            );

        final String uid = userCredential.user!.uid;

        await db.collection("users").doc(uid).set(result);
        Get.snackbar("Sukses", "Pegawai berhasil ditambahkan");
      } on FirebaseAuthException catch (e) {
        Get.snackbar("Gagal", "$e");
      } finally {
        await secondaryAuth.signOut();
        await secondaryApp.delete();
      }
    } else {
      Get.snackbar("Gagal", "Email sudah terdaftar");
    }
    clearAllFields();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchSuratPerjadin() {
    return db.collection("surat_perjadin").snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return db.collection("users").orderBy("namapegawai").snapshots();
  }

  void getUser(String id) async {
    final doc = await db.collection("users").doc(id).get();

    if (doc.exists) {
      final currentUser = doc.data()!;
      emailPegawai.text = currentUser["emailpegawai"];
      namaPegawaiT.text = currentUser["namapegawai"];
      nipPegawaiT.text = currentUser["nippegawai"];
      jabatan.value = currentUser["jabatan"].toLowerCase();
      divisi.value = currentUser["divisi"];
      pangkat.value = currentUser["pangkat"];
      role.value = currentUser["role"].toLowerCase();
      passwordT.text = currentUser["password"];
    }
  }

  void updatePegawai(String id) async {
    final result = {
      "namapegawai": namaPegawaiT.text,
      "nippegawai": nipPegawaiT.text,
      "jabatan": jabatan.value.toLowerCase(),
      "divisi": divisi.value,
      "pangkat": pangkat.value,
      "role": role.value.toLowerCase(),
    };
    try {
      await db.collection("users").doc(id).update(result);
      Get.snackbar("Sukses", "Pegawai berhasil diupdate");
    } on FirebaseException catch (e) {
      Get.snackbar("Gagal", "Terjadi kesalahan");
    }
    clearAllFields();
  }

  void searchUser(String query) async {
    query = query.trim().toLowerCase();
    if (query.isEmpty) {
      tempSearch.clear();
      return;
    }

    try {
      final result = await db.collection("users").orderBy("namapegawai").get();

      tempSearch.value =
          result.docs
              .map((e) {
                final data = e.data();
                return <String, dynamic>{
                  "id": e.id,
                  ...(data is Map<String, dynamic>
                      ? data
                      : <String, dynamic>{}),
                };
              })
              .where(
                (doc) => (doc["namapegawai"].toString().toLowerCase()).contains(
                  query,
                ),
              )
              .toList();
    } catch (e) {
      print("Error searchUser: $e");
      tempSearch.clear();
    }
  }

  void searchPerjadin(String query) async {
    query = query.trim().toLowerCase();
    if (query.isEmpty) {
      tempSearchPerjadin.clear();
      return;
    }

    try {
      final result =
          await db.collection("surat_perjadin").orderBy("nospd").get();

      tempSearchPerjadin.value =
          result.docs
              .map((e) {
                final data = e.data();
                return <String, dynamic>{
                  "id": e.id,
                  ...(data is Map<String, dynamic>
                      ? data
                      : <String, dynamic>{}),
                };
              })
              .where((doc) {
                final nospd = (doc["nospd"] ?? "").toString().toLowerCase();

                // Cek semua peserta
                final pesertaList = (doc["peserta"] ?? []) as List;
                final pesertaMatch = pesertaList.any((p) {
                  final nama =
                      (p["namapegawai"] ?? "").toString().toLowerCase();
                  return nama.contains(query);
                });

                return nospd.contains(query) || pesertaMatch;
              })
              .toList();
    } catch (e) {
      print("Error searchPerjadi: $e");
      tempSearchPerjadin.clear();
    }
  }

  void deletePegawai(String id) async {
    final doc = await db.collection("users").doc(id).get();
    final currentUser = doc.data()!;

    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: Firebase.app().options,
    );

    FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      UserCredential userCred = await secondaryAuth.signInWithEmailAndPassword(
        email: currentUser["emailpegawai"],
        password: currentUser["password"],
      );
      await userCred.user!.delete();
      await db.collection("users").doc(id).delete();
      Get.snackbar("Sukses", "Pegawai berhasil dihapus");
    } on FirebaseAuthException catch (e) {
      print('Gagal menghapus akun: $e');
    } finally {
      await secondaryAuth.signOut();
      await secondaryApp.delete();
    }
  }

  @override
  void onInit() {
    super.onInit();
    emailPegawai = TextEditingController();
    namaPegawaiT = TextEditingController();
    nipPegawaiT = TextEditingController();
    passwordT = TextEditingController();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    namaPegawaiT.dispose();
    nipPegawaiT.dispose();
    passwordT.dispose();
    emailPegawai.dispose();
    jabatan.close();
    divisi.close();
    pangkat.close();
    role.close();
    super.onClose();
  }
}
