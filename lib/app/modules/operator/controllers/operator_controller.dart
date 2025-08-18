import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:terbilang_id/terbilang_id.dart';
import 'package:dio/dio.dart';

class OperatorController extends GetxController {
  final peserta = [].obs;
  final suratPerintah = "".obs;
  late TextEditingController maksudPerjalananT;
  late TextEditingController tempatBerangkatT;
  late TextEditingController tempatTujuanT;
  final tanggalBerangkat = Rxn<DateTime>();
  final tanggalKembali = Rxn<DateTime>();
  final noSpd = "".obs;
  final doublePeserta = false.obs;
  var currentPage = 0.obs;
  final persetujuan = "".obs;

  // spj
  late TextEditingController uangHarianT;
  late TextEditingController uangFullBordT;
  late TextEditingController uangPenginapanT;
  late TextEditingController uangTransportasiT;
  late TextEditingController uangTiketPesawatT;
  late TextEditingController representasiT;
  late TextEditingController jumlahHariUangHarianT;
  late TextEditingController jumlahHariFullbordT;
  var totalSpj = 0.obs;
  FirebaseFirestore db = FirebaseFirestore.instance;

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

  void changePage(int index) {
    currentPage.value = index;
  }

  void clearFields() {
    maksudPerjalananT.clear();
    tempatBerangkatT.clear();
    tempatTujuanT.clear();
    suratPerintah.value = "";
    tanggalBerangkat.value = null;
    tanggalKembali.value = null;
    peserta.clear();
    peserta.add(null);
    doublePeserta.value = false;
    noSpd.value = "";
    persetujuan.value = "";
  }

  void clearFieldSPJ() {
    uangHarianT.clear();
    uangFullBordT.clear();
    uangPenginapanT.clear();
    uangTransportasiT.clear();
    uangTiketPesawatT.clear();
    representasiT.clear();
    totalSpj.value = 0;
  }

  int parseCurrency(String value) {
    // Menghapus 'Rp ' dan semua titik
    // return int.tryParse(value.replaceAll('Rp ', '').replaceAll('.', '')) ?? 0;
    String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  void calculateTotal() {
    totalSpj.value =
        (parseCurrency(uangHarianT.text) *
            parseCurrency(jumlahHariUangHarianT.text)) +
        (parseCurrency(uangFullBordT.text) *
            parseCurrency(jumlahHariFullbordT.text)) +
        parseCurrency(uangPenginapanT.text) +
        parseCurrency(uangTransportasiT.text) +
        parseCurrency(uangTiketPesawatT.text) +
        parseCurrency(representasiT.text);
  }

  Stream<List<Map<String, dynamic>>> fetchPegawai() {
    return db
        .collection("users")
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList(),
        );
  }

  void tambahPeserta() {
    peserta.add(null);
  }

  void hapusPeserta(int index) {
    if (peserta.length > 1) peserta.removeAt(index);
  }

  void datePicker(BuildContext context, bool isDeparture) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDeparture ? tanggalBerangkat.value : tanggalKembali.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple, // warna tanggal aktif
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      isDeparture
          ? tanggalBerangkat.value = DateTime(
            picked.year,
            picked.month,
            picked.day,
          )
          : tanggalKembali.value = DateTime(
            picked.year,
            picked.month,
            picked.day,
          );
    }
  }

  Future<String> generateNoSpd() async {
    final counterRef = db.collection('counter').doc('counter_perjadin');
    return await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int currentNo = 0;

      if (snapshot.exists) {
        currentNo = snapshot.data()!['nomor_terakhir'] ?? 0;
      }

      int newNo = currentNo + 1;

      transaction.update(counterRef, {'nomor_terakhir': newNo});

      // Format No SPD sesuai kebutuhan kamu
      String formattedNo =
          '$newNo/SPD/${DateFormat("MM").format(DateTime.now())}/${DateFormat("yyyy").format(DateTime.now())}/HIBAH';

      return formattedNo;
    });
  }

  void simpanPerjadin() async {
    final currentPPK =
        await db.collection("users").where("role", isEqualTo: "ppk").get();
    final currentBendahara =
        await db
            .collection("users")
            .where("jabatan", isEqualTo: "bendahara pengeluaran")
            .get();
    final currentSekretaris =
        await db
            .collection("users")
            .where("jabatan", isEqualTo: "sekretaris kpu")
            .get();
    final currentKetua =
        await db
            .collection("users")
            .where("jabatan", isEqualTo: "ketua kpu")
            .get();

    final docRef = db.collection("surat_perjadin").doc();

    final currentPejabat = await docRef.collection("currentPejabat").add({
      "currentKetua":
          currentKetua.docs.isNotEmpty
              ? {
                "namapegawai":
                    currentKetua.docs.first.data()["namapegawai"] ?? '',
                "nippegawai":
                    currentKetua.docs.first.data()["nippegawai"] ?? '',
                "jabatan": currentKetua.docs.first.data()["jabatan"] ?? '',
                "pangkat": currentKetua.docs.first.data()["pangkat"] ?? '',
              }
              : {},
      "currentPPK":
          currentPPK.docs.isNotEmpty
              ? {
                "namapegawai":
                    currentPPK.docs.first.data()["namapegawai"] ?? '',
                "nippegawai": currentPPK.docs.first.data()["nippegawai"] ?? '',
                "jabatan": currentPPK.docs.first.data()["jabatan"] ?? '',
                "pangkat": currentPPK.docs.first.data()["pangkat"] ?? '',
              }
              : {},

      "currentBendahara":
          currentBendahara.docs.isNotEmpty
              ? {
                "namapegawai":
                    currentBendahara.docs.first.data()["namapegawai"] ?? '',
                "nippegawai":
                    currentBendahara.docs.first.data()["nippegawai"] ?? '',
                "jabatan": currentBendahara.docs.first.data()["jabatan"] ?? '',
                "pangkat": currentBendahara.docs.first.data()["pangkat"] ?? '',
              }
              : {},
      "currentSekretaris":
          currentSekretaris.docs.isNotEmpty
              ? {
                "namapegawai":
                    currentSekretaris.docs.first.data()["namapegawai"] ?? '',
                "nippegawai":
                    currentSekretaris.docs.first.data()["nippegawai"] ?? '',
                "jabatan": currentSekretaris.docs.first.data()["jabatan"] ?? '',
                "pangkat": currentSekretaris.docs.first.data()["pangkat"] ?? '',
              }
              : {},
    });

    final listPeserta = {
      "nospd":
          await generateNoSpd(), // Menggunakan fungsi generateNoSpd() untuk menghasilkan nomor SPD
      "suratperintah": suratPerintah.value.toLowerCase(),
      "peserta": peserta.where((e) => e != null).toList(),
      "maksudperjalanan": maksudPerjalananT.text,
      "sarana": "Kendaraan Dinas/Umum/Udara",
      "tempatberangkat": tempatBerangkatT.text.toLowerCase(),
      "tempattujuan": tempatTujuanT.text.toLowerCase(),
      "tanggalberangkat": tanggalBerangkat.value,
      "tanggalkembali": tanggalKembali.value,
      "createdAt": DateTime.now(),
      "disetujuippk": "none",
      "readBy": {"operator": false, "ppk": false},
      "idCurrentPejabat": currentPejabat.id,
    };

    await docRef.set(listPeserta);

    for (var e in peserta) {
      final nipPeserta = e["nippegawai"];
      await docRef.collection("spj").doc(nipPeserta).set({
        "uang_harian": 0,
        "uang_fullbord": 0,
        "uang_penginapan": 0,
        "uang_transportasi": 0,
        "uang_tiket_pesawat": 0,
        "representasi": 0,
        "jumlahhariuangharian": 0,
        "jumlahharifullbord": 0,
        "total": 0,
      });
    }

    if (currentPPK.docs.first.data()['fcm_token']) {
      final tokenPPK = currentPPK.docs.first.data()['fcm_token'];
      kirimNotifikasiKePPK(docRef.id, tokenPPK);
    }
    Get.snackbar("Berhasil", "Berhasil disimpan.");
    clearFields();
    Get.back();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchSuratPerjadin() {
    return db.collection("surat_perjadin").snapshots();
  }

  void getPerjadin(String id) async {
    final currentPerjadin = await db.collection("surat_perjadin").doc(id).get();
    if (currentPerjadin.exists) {
      final data = currentPerjadin.data()!;
      maksudPerjalananT.text = data['maksudperjalanan'] ?? '';
      tempatBerangkatT.text = data['tempatberangkat'] ?? '';
      tempatTujuanT.text = data['tempattujuan'] ?? '';
      suratPerintah.value = data['suratperintah'] ?? '';
      tanggalBerangkat.value =
          (data['tanggalberangkat'] as Timestamp?)?.toDate();
      tanggalKembali.value = (data['tanggalkembali'] as Timestamp?)?.toDate();
      noSpd.value = data['nospd'] ?? '';

      peserta.clear();
      for (var item in data['peserta']) {
        peserta.add(item);
      }
    }
  }

  void updatePerjadin(String id) async {
    final listPeserta = {
      "suratperintah": suratPerintah.value.toLowerCase(),
      "peserta": peserta.where((e) => e != null).toList(),
      "maksudperjalanan": maksudPerjalananT.text,
      "tempatberangkat": tempatBerangkatT.text.toLowerCase(),
      "tempattujuan": tempatTujuanT.text.toLowerCase(),
      "tanggalberangkat": tanggalBerangkat.value,
      "tanggalkembali": tanggalKembali.value,
      "disetujuippk": "none",
    };
    final docRef = FirebaseFirestore.instance
        .collection('surat_perjadin')
        .doc(id);

    // ambil data lama
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return;

    final List<dynamic> pesertaLama = docSnapshot.data()?['peserta'] ?? [];

    final List<String> nipLama =
        pesertaLama.map((e) => e["nippegawai"] as String).toList();
    final List<String> nipBaru =
        peserta.map((e) => e["nippegawai"] as String).toList();

    // cari peserta yang akan dihapus
    final toDelete = nipLama.where((nip) => !nipBaru.contains(nip)).toList();

    // cari peserta yang akan ditambahkan
    final toAdd = nipBaru.where((nip) => !nipLama.contains(nip)).toList();

    // hapus nip peserta lama pada subcollection spj
    for (var nip in toDelete) {
      await docRef.collection('spj').doc(nip).delete();
    }

    for (var nip in toAdd) {
      await docRef.collection('spj').doc(nip).set({
        "uang_harian": 0,
        "uang_fullbord": 0,
        "uang_penginapan": 0,
        "uang_transportasi": 0,
        "uang_tiket_pesawat": 0,
        "representasi": 0,
        "jumlahhariuangharian": 0,
        "jumlahharifullbord": 0,
        "total": 0,
      });
    }

    // update peserta pada main collection
    await docRef.update(listPeserta);

    final currentPPK =
        await db.collection("users").where("role", isEqualTo: "ppk").get();

    if (currentPPK.docs.first.data()['fcm_token'].isNotEmpty) {
      final tokenPPK = currentPPK.docs.first.data()['fcm_token'];
      kirimNotifikasiKePPK(id, tokenPPK);
    } else {
      print("Token PPK tidak ditemukan atau kosong.");
    }

    clearFields();
    Get.snackbar("Berhasil", "Berhasil diperbarui.");
    Get.back();
  }

  void deletePerjadin(String id) async {
    final docRef = db.collection("surat_perjadin").doc(id);
    final spjDoc = await docRef.collection("spj").get();
    for (var doc in spjDoc.docs) {
      await doc.reference.delete();
    }
    await docRef.delete();
    Get.back();
    Get.snackbar("Berhasil", "Berhasil dihapus.");
  }

  Future<void> cekPersetujuan(String id) async {
    final docRef = await db.collection("surat_perjadin").doc(id).get();
    if (docRef.exists) {
      final data = docRef.data()!;
      if (data['disetujuippk'] == "true") {
        persetujuan.value = "true";
      } else if (data['disetujuippk'] == "false") {
        persetujuan.value = "false";
      } else {
        persetujuan.value = "none";
      }
    }
  }

  String formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: '',
      decimalDigits: 0,
    ).format(value);
  }

  String formatNamaMultiGelar(String input) {
    input = input.trim();

    // Pecah berdasarkan spasi
    List<String> parts = input.split(' ');

    List<String> gelarDepanList = [];
    List<String> namaList = [];
    List<String> gelarBelakangList = [];

    bool isNamaDimulai = false;

    for (var part in parts) {
      if (!isNamaDimulai && part.endsWith('.')) {
        // Kalau belum masuk nama dan masih gelar depan
        gelarDepanList.add(part);
      } else if (!isNamaDimulai) {
        // Ketemu nama
        isNamaDimulai = true;
        namaList.add(part);
      } else if (isNamaDimulai && part.contains('.')) {
        // Jika sudah masuk nama dan ketemu gelar belakang
        gelarBelakangList.add(part);
      } else {
        // Jika masih bagian nama
        namaList.add(part);
      }
    }

    String gelarDepan = gelarDepanList.join(' ');
    String nama = namaList.map((e) => e.toUpperCase()).join(' ');
    String gelarBelakang = gelarBelakangList.join(' ');

    String hasil = '';

    if (gelarDepan.isNotEmpty) hasil += '$gelarDepan ';
    hasil += nama;
    if (gelarBelakang.isNotEmpty) hasil += ' $gelarBelakang';

    return hasil.trim();
  }

  Future<void> generateSPT(String id) async {
    await initializeDateFormatting('id_ID');
    Intl.defaultLocale = 'id_ID';
    final atasPerintah = "".obs;
    final docRef = await db.collection("surat_perjadin").doc(id).get();

    final docPejabat =
        await db
            .collection("surat_perjadin")
            .doc(id)
            .collection("currentPejabat")
            .doc(docRef.data()!["idCurrentPejabat"])
            .get();

    atasPerintah.value =
        docRef.data()!["suratperintah"] == "ketua kpu"
            ? docPejabat.data()!["currentKetua"]["namapegawai"]
            : docPejabat.data()!["currentPPK"]["namapegawai"];

    final pdf = pw.Document();
    final data = docRef.data()!;

    final logoBytes = await rootBundle.load('assets/images/KPU_Logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final lamaWaktu =
        data['tanggalkembali'] != null && data['tanggalberangkat'] != null
            ? data['tanggalkembali']
                .toDate()
                .difference(data['tanggalberangkat'].toDate())
                .inDays
            : 0;

    pdf.addPage(
      pw.Page(
        // pageFormat: PdfPageFormat.a4,
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              docRef.data()!['suratperintah'] == "Ketua KPU"
                  ? pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Image(logoImage, width: 50),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            "KOMISI PEMILIHAN UMUM",
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            "PROVINSI JAMBI",
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Jl. Jend. A. Thalib Nomor.33 Jambi Telp. (0741) 670121, 670771 / Fax. (0741) 670773',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  )
                  : pw.Container(
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Logo di kiri
                        pw.Image(logoImage, width: 50),
                        // Spacer agar teks berada di tengah relatif
                        // pw.Spacer(),
                        // Teks tengah
                        pw.Expanded(
                          flex: 2,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text(
                                'KOMISI PEMILIHAN UMUM',
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                'PROVINSI JAMBI',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                'Jl. Jend. A. Thalib Nomor.33 Jambi Telp. (0741) 670121, 670771 / Fax. (0741) 670773',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        // Spacer kanan (untuk keseimbangan)
                        // pw.Spacer(),
                      ],
                    ),
                  ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "BIAYA OPERASIONAL KPU",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "SURAT PERINTAH TUGAS",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "MODEL KEU.1h",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'PROVINSI : JAMBI',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'KODE UNIT : 654322',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          docRef.data()!["suratperintah"] == "ketua kpu"
                              ? "KETUA KPU PROVINSI"
                              : "SEKRETARIS KPU PROVINSI",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              "NOMOR : ",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              data['nospd'] ?? '',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Center(
                    child: pw.Text(
                      'MEMERINTAHKAN',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),

              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "KEPADA",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: List.generate(5, (index) {
                            if (index < data['peserta'].length) {
                              final peserta = data['peserta'][index];
                              return pw.Text(
                                "${index + 1}. ${peserta['namapegawai'].toUpperCase()}",
                              );
                            } else {
                              return pw.Text("${index + 1}. -");
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "UNTUK MELAKSANAKAN TUGAS",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(data['maksudperjalanan'] ?? ''),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "LAMANYA",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "$lamaWaktu Hari, ${DateFormat('dd MMMM yyyy').format(data['tanggalberangkat'].toDate())} s.d. ${DateFormat('dd MMMM yyyy').format(data['tanggalkembali'].toDate())}",
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "SARANA",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Untuk Melaksanakan tugas ini pejabat di atas menggunakan kendaraan",
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              "Kendaraan Dinas/Umum/Udara",
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "HASIL TUGAS",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "Hasil pelaksanaan tugas ini harus segera dilaporkan kepada yang memberi tugas.",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "PERHATIAN",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "Surat Perintah Tugas ini diberikan untuk dilaksanakan dengan Penuh Tanggung Jawab.",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "DIKELUARKAN DI : JAMBI",
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "TANGGAL :           ${DateFormat('MMMM yyyy').format(data["createdAt"].toDate())}",
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.Divider(),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          docRef.data()!["suratperintah"] == "ketua kpu"
                              ? "KETUA"
                              : "SEKRETARIS",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 50),
                        pw.Text(
                          textAlign: pw.TextAlign.center,
                          docRef.data()!["suratperintah"] == "ketua kpu"
                              ? docPejabat["currentKetua"]["namapegawai"]
                              : docPejabat["currentSekretaris"]["namapegawai"],
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Text('Tembusan disampaikan kepada Yth:'),
              pw.Text("1. Ketua KPU Provinsi Jambi"),
              pw.Text(
                '2. Bendahara Pengeluaran Sekretariat KPU Provinsi Jambi di Jambi',
              ),
              pw.Text('3. Arsip'),
            ],
          );
        },
      ),
    );

    // return pdf.save();

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/SPT.pdf");
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Future<void> generateSPD2(String nipPegawai, String perjadinId) async {
    await initializeDateFormatting('id_ID');
    Intl.defaultLocale = 'id_ID';

    final docPerjadin =
        await db.collection("surat_perjadin").doc(perjadinId).get();
    final dataPerjadin = docPerjadin.data()!;
    Map<String, dynamic> dataUser = {};

    for (var item in dataPerjadin["peserta"]) {
      if (item["nippegawai"] == nipPegawai) {
        dataUser.addAll(item);
      }
    }

    final docCurrentPejabat =
        await db
            .collection("surat_perjadin")
            .doc(perjadinId)
            .collection("currentPejabat")
            .doc(dataPerjadin["idCurrentPejabat"])
            .get();

    final logoBytes = await rootBundle.load('assets/images/KPU_Logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final lamaWaktu =
        dataPerjadin['tanggalkembali'] != null &&
                dataPerjadin['tanggalberangkat'] != null
            ? dataPerjadin['tanggalkembali']
                .toDate()
                .difference(dataPerjadin['tanggalberangkat'].toDate())
                .inDays
            : 0;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Lembar Ke :"),
                      pw.Text("Kode No :"),
                      pw.Text("Nomor  : ${dataPerjadin['nospd']}"),
                    ],
                  ),
                ],
              ),
              pw.Container(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Logo di kiri
                    pw.Image(logoImage, width: 50),

                    // Spacer agar teks berada di tengah relatif
                    // pw.Spacer(),

                    // Teks tengah
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'KOMISI PEMILIHAN UMUM',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'PROVINSI JAMBI',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Spacer kanan (untuk keseimbangan)
                    // pw.Spacer(),
                  ],
                ),
              ),
              pw.Divider(thickness: 2),
              pw.Text(
                "SURAT PERJALANAN DINAS (SPD)",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),

              pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(),
                  top: pw.BorderSide(),
                  right: pw.BorderSide(),
                  bottom: pw.BorderSide(),
                  horizontalInside: pw.BorderSide(),
                  verticalInside: pw.BorderSide(),
                ),
                columnWidths: {
                  0: pw.FlexColumnWidth(0.12),
                  1: const pw.FlexColumnWidth(.9),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("1.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Pejabat yang memberi perintah"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("Pejabat Pembuat Komitmen"),
                            pw.Text("Sekretariat KPU Provinsi Jambi"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("2.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Nama / Pegawai yang diperintahkan"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              formatNamaMultiGelar(dataUser['namapegawai']),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text("NIP. ${dataUser['nippegawai']}"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("3.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("a. Pangkat dan Golongan"),
                            pw.Text("b. Jabatan"),
                            pw.Text("c. Tingkat menurut peraturan perjalanan"),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("a. ${dataUser['pangkat']}"),
                            pw.Text(
                              "b. ${capitalizeEachWord(dataUser['jabatan'])}, ${capitalizeEachWord(dataUser['divisi'])}",
                            ),
                            pw.Text("c. C"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("4.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Maksud Perjalanan Dinas"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          dataPerjadin['maksudperjalanan'] ?? '',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("5.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Alat / Kendaraan yang dipergunakan"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("${dataPerjadin['sarana']}"),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("6.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("a. Tempat Berangkat"),
                            pw.Text("b. Tempat Tujuan"),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "a. ${dataPerjadin['tempatberangkat'].toUpperCase() ?? ''}",
                            ),
                            pw.Text(
                              "b. ${dataPerjadin['tempattujuan'].toUpperCase() ?? ''}",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("7.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("a. Lamanya Perjalanan Dinas"),
                            pw.Text("b. Tanggal Berangkat"),
                            pw.Text("c. Tanggal Kembali"),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("a. $lamaWaktu Hari"),
                            pw.Text(
                              "b. ${DateFormat('dd MMMM yyyy').format(dataPerjadin['tanggalberangkat'].toDate())}",
                            ),
                            pw.Text(
                              "c. ${DateFormat('dd MMMM yyyy').format(dataPerjadin['tanggalkembali'].toDate())}",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("8.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Nama Pengikut"),
                      ),

                      pw.Table(
                        border: pw.TableBorder.all(),
                        columnWidths: {
                          0: pw.FlexColumnWidth(1),
                          1: pw.FlexColumnWidth(1),
                        },
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Center(
                                  child: pw.Text("Tangggal Lahir"),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Center(child: pw.Text("Keterangan")),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(""),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [pw.Text("1."), pw.Text("2.")],
                        ),
                      ),

                      pw.Table(
                        border: pw.TableBorder.all(),
                        columnWidths: {
                          0: pw.FlexColumnWidth(1),
                          1: pw.FlexColumnWidth(1),
                        },
                        children: [
                          pw.TableRow(
                            children: [
                              pw.SizedBox(height: 36),
                              pw.SizedBox(height: 36),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("9", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("Pembebanan Anggaran"),
                            pw.Text("a. Instansi"),
                            pw.Text("b. Mata Anggaran"),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(""),
                            pw.Text("a. Sekretariat KPU Provinsi Jambi"),
                            pw.Text(
                              "b. Dana Hibah Pilgub ${DateFormat('yyyy').format(DateTime.now())}",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("10.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Keterangan lain-lain"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Berdasarkan SPT No."),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 150,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "DIKELUARKAN DI : JAMBI",
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "TANGGAL :           ${DateFormat('MMMM yyyy').format(DateTime.now())}",
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text("______________________"),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 150,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          "Pejabat Pembuat Komitmen",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 40),
                        pw.Text(
                          textAlign: pw.TextAlign.center,
                          formatNamaMultiGelar(
                            docCurrentPejabat
                                .data()!["currentPPK"]["namapegawai"],
                          ),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          textAlign: pw.TextAlign.center,
                          docCurrentPejabat.data()!["currentPPK"]["pangkat"],
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          textAlign: pw.TextAlign.center,
                          "NIP. ${docCurrentPejabat.data()!["currentPPK"]["nippegawai"]}",
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Halaman kedua
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.SizedBox(),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "I. Berangkat dari : ${dataPerjadin["tempatberangkat"]}",
                            ),
                            pw.Text("(Tempat Kedudukan)"),
                            pw.Text("Ke :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 8),
                            pw.Center(
                              child: pw.Text(
                                "Sekretaris",
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.SizedBox(height: 40),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                formatNamaMultiGelar(
                                  docCurrentPejabat
                                      .data()!["currentSekretaris"]["namapegawai"],
                                ),
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP. ${docCurrentPejabat.data()!["currentSekretaris"]["nippegawai"]}",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("II. Tiba dari :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 45),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Berangkat dari : ${dataPerjadin["tempatberangkat"]}",
                            ),
                            pw.Text("Ke :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 40),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("III. Tiba dari :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 45),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Berangkat dari : ${dataPerjadin["tempatberangkat"]}",
                            ),
                            pw.Text("Ke :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 40),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("IV. Tiba dari :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 45),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Berangkat dari : ${dataPerjadin["tempatberangkat"]}",
                            ),
                            pw.Text("Ke :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 40),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("V. Tiba dari :"),
                            pw.Text("(Tempat Kedudukan)"),
                            pw.SizedBox(height: 23),
                            pw.Center(
                              child: pw.Text("Pejabat Pembuat Komitmen"),
                            ),
                            pw.SizedBox(height: 45),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                formatNamaMultiGelar(
                                  docCurrentPejabat["currentPPK"]["namapegawai"],
                                ),
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP. ${docCurrentPejabat["currentPPK"]["nippegawai"]}",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Telah Diperiksa dengan keterangan bahwa Perjalanan tersebut atas perintahnya dan semata-mata untuk Kepentingan Jabatan dalam waktu yang sesingkat-singkatnya.",
                            ),
                            pw.SizedBox(height: 6),
                            pw.Center(
                              child: pw.Text("Pejabat Pembuat Komitmen"),
                            ),
                            pw.SizedBox(height: 45),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                formatNamaMultiGelar(
                                  docCurrentPejabat["currentPPK"]["namapegawai"],
                                ),
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP. ${docCurrentPejabat["currentPPK"]["nippegawai"]}",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Container(
                width: context.page.pageFormat.width,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'VI. Catatan Lain-lain',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
              ),

              pw.Container(
                width: context.page.pageFormat.width,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'VII. Catatan Lain-lain',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        "PPK yang menerbitkan SPD, pegawai yang melakukan perjalanan dinas, para pejabat yang mengesahkan tanggal berangkat/tiba, serta bendahara pengeluaran bertanggung jawab berdasarkan peraturan-peraturan Keuangan Negara apabila Negara menderita rugi akibat kesalahan, kelalaian, dan kealpaannya.",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

          // return pw.Stack(
          //   children: [
          //     // Logo di kiri atas
          //     pw.Positioned(
          //       left: 0,
          //       top: 0,
          //       child: pw.Image(logoImage, width: 50),
          //     ),

          //     // Teks di tengah horizontal atas
          //     pw.Positioned(
          //       top: 0,
          //       left: 0,
          //       right: 0,
          //       child: pw.Center(
          //         child: pw.Column(
          //           children: [
          //             pw.Text(
          //               'KOMISI PEMILIHAN UMUM',
          //               style: pw.TextStyle(
          //                 fontSize: 14,
          //                 fontWeight: pw.FontWeight.bold,
          //               ),
          //             ),
          //             pw.Text(
          //               'PROVINSI JAMBI',
          //               style: pw.TextStyle(
          //                 fontSize: 14,
          //                 fontWeight: pw.FontWeight.bold,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ],
          // );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/SPD_${dataUser["namapegawai"]}.pdf");
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Future<void> generateSPD(String nipPegawai, String id) async {
    await initializeDateFormatting('id_ID');
    Intl.defaultLocale = 'id_ID';
    final docPerjadin = await db.collection("surat_perjadin").doc(id).get();
    final docUser =
        await db
            .collection("users")
            .where("nippegawai", isEqualTo: nipPegawai)
            .get();
    final isPPK =
        await db.collection("users").where("role", isEqualTo: "PPK").get();

    final pdf = pw.Document();
    final dataPerjadin = docPerjadin.data()!;
    final dataUser = docUser.docs.first.data();

    final logoBytes = await rootBundle.load('assets/images/KPU_Logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final lamaWaktu =
        dataPerjadin['tanggalkembali'] != null &&
                dataPerjadin['tanggalberangkat'] != null
            ? dataPerjadin['tanggalkembali']
                .toDate()
                .difference(dataPerjadin['tanggalberangkat'].toDate())
                .inDays
            : 0;

    // Halaman pertama
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Lembar Ke :"),
                      pw.Text("Kode No :"),
                      pw.Text("Nomor  : ${dataPerjadin['nospd']}"),
                    ],
                  ),
                ],
              ),
              pw.Container(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Logo di kiri
                    pw.Image(logoImage, width: 50),

                    // Spacer agar teks berada di tengah relatif
                    // pw.Spacer(),

                    // Teks tengah
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'KOMISI PEMILIHAN UMUM',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'PROVINSI JAMBI',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Spacer kanan (untuk keseimbangan)
                    // pw.Spacer(),
                  ],
                ),
              ),
              pw.Divider(thickness: 2),
              pw.Text(
                "SURAT PERJALANAN DINAS (SPD)",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Table(
                border: pw.TableBorder(
                  left: pw.BorderSide(),
                  top: pw.BorderSide(),
                  right: pw.BorderSide(),
                  bottom: pw.BorderSide(),
                  horizontalInside: pw.BorderSide(),
                  verticalInside: pw.BorderSide(),
                ),
                columnWidths: {
                  0: pw.FlexColumnWidth(0.12),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("1.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          "Pejabat yang berwenang memberi perintah",
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("Pejabat Pembuat Komitmen"),
                            pw.Text("Sekretariat KPU Provinsi Jambi"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("2.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Nama / Pegawai yang diperintahkan"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("${dataUser['namapegawai']}"),
                            pw.Text("NIP. ${dataUser['nippegawai']}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("3.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("a. Pangkat dan Golongan"),
                            pw.Text("b. Jabatan"),
                            pw.Text("c. Tingkat menurut peraturan perjalanan"),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("a. ${dataUser['pangkat']}"),
                            pw.Text("b. Kabag Teknis Partisipasi & Hubmas"),
                            pw.Text("c. C"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("4.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Maksud Perjalanan Dinas"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          dataPerjadin['maksudperjalanan'] ?? '',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("5.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Alat / Kendaraan yang dipergunakan"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("${dataPerjadin['sarana']}"),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("6.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("a. Tempat Berangkat"),
                            pw.Text("b. Tempat Tujuan"),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "a. ${dataPerjadin['tempatberangkat'] ?? ''}",
                            ),
                            pw.Text("b. ${dataPerjadin['tempattujuan'] ?? ''}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("7.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("a. Lamanya Perjalanan Dinas"),
                            pw.Text("b. Tanggal Berangkat"),
                            pw.Text("c. Tanggal Kembali"),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("a. $lamaWaktu Hari"),
                            pw.Text(
                              "b. ${DateFormat('dd MMMM yyyy').format(dataPerjadin['tanggalberangkat'].toDate())}",
                            ),
                            pw.Text(
                              "c. ${DateFormat('dd MMMM yyyy').format(dataPerjadin['tanggalkembali'].toDate())}",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("8.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Nama Pengikut"),
                      ),

                      pw.Table(
                        border: pw.TableBorder.all(),
                        columnWidths: {
                          0: pw.FlexColumnWidth(1),
                          1: pw.FlexColumnWidth(1),
                        },
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Center(
                                  child: pw.Text("Tangggal Lahir"),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Center(child: pw.Text("Keterangan")),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(""),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [pw.Text("1."), pw.Text("2.")],
                        ),
                      ),

                      pw.Table(
                        border: pw.TableBorder.all(),
                        columnWidths: {
                          0: pw.FlexColumnWidth(1),
                          1: pw.FlexColumnWidth(1),
                        },
                        children: [
                          pw.TableRow(
                            children: [
                              pw.SizedBox(height: 36),
                              pw.SizedBox(height: 36),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("9", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("Pembebanan Anggaran"),
                            pw.Text("a. Instansi"),
                            pw.Text("b. Mata Anggaran"),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(""),
                            pw.Text("a. Sekretariat KPU Provinsi Jambi"),
                            pw.Text(
                              "b. Dana Hibah Pilgub ${DateFormat('yyyy').format(DateTime.now())}",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("10.", textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Keterangan lain-lain"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("Berdasarkan SPT No."),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 150,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "DIKELUARKAN DI : JAMBI",
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "TANGGAL :           ${DateFormat('MMMM yyyy').format(DateTime.now())}",
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text("______________________"),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 150,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          "Pejabat Pembuat Komitmen",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 40),
                        pw.Text(
                          textAlign: pw.TextAlign.center,
                          isPPK.docs.isNotEmpty
                              ? capitalizeEachWord(
                                isPPK.docs.first.data()["namapegawai"],
                              )
                              : "",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          textAlign: pw.TextAlign.center,
                          isPPK.docs.isNotEmpty
                              ? isPPK.docs.first.data()["pangkat"]
                              : "",
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          textAlign: pw.TextAlign.center,
                          isPPK.docs.isNotEmpty
                              ? isPPK.docs.first.data()["nippegawai"]
                              : "",
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Halaman kedua
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.SizedBox(),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "I. Berangkat dari : ${dataPerjadin["tempatberangkat"]}",
                            ),
                            pw.Text("(Tempat Kedudukan)"),
                            pw.Text("Ke :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 8),
                            pw.Center(
                              child: pw.Text(
                                "Sekretaris",
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.SizedBox(height: 40),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                isPPK.docs.first.data()["namapegawai"],
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP. ${dataUser["nippegawai"]}",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("II. Tiba dari :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 45),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Berangkat dari : ${dataPerjadin["tempatberangkat"]}",
                            ),
                            pw.Text("Ke :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 40),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("III. Tiba dari :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 45),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Berangkat dari : ${dataPerjadin["tempatberangkat"]}",
                            ),
                            pw.Text("Ke :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 40),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("IV. Tiba dari :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 45),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Berangkat dari : ${dataPerjadin["tempatberangkat"]}",
                            ),
                            pw.Text("Ke :"),
                            pw.Text("Pada Tanggal :"),
                            pw.SizedBox(height: 40),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "(..............................)",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP.                                    ",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("V. Tiba dari :"),
                            pw.Text("(Tempat Kedudukan)"),
                            pw.SizedBox(height: 23),
                            pw.Center(
                              child: pw.Text("Pejabat Pembuat Komitmen"),
                            ),
                            pw.SizedBox(height: 45),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                isPPK.docs.first.data()["namapegawai"],
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP. ${dataUser["nippegawai"]}",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Telah Diperiksa dengan keterangan bahwa Perjalanan tersebut atas perintahnya dan semata-mata untuk Kepentingan Jabatan dalam waktu yang sesingkat-singkatnya.",
                            ),
                            pw.SizedBox(height: 6),
                            pw.Center(
                              child: pw.Text("Pejabat Pembuat Komitmen"),
                            ),
                            pw.SizedBox(height: 45),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                isPPK.docs.first.data()["namapegawai"],
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Center(
                              child: pw.Text(
                                textAlign: pw.TextAlign.center,
                                "NIP. ${dataUser["nippegawai"]}",
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Container(
                width: context.page.pageFormat.width,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'VI. Catatan Lain-lain',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
              ),

              pw.Container(
                width: context.page.pageFormat.width,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'VII. Catatan Lain-lain',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        "PPK yang menerbitkan SPD, pegawai yang melakukan perjalanan dinas, para pejabat yang mengesahkan tanggal berangkat/tiba, serta bendahara pengeluaran bertanggung jawab berdasarkan peraturan-peraturan Keuangan Negara apabila Negara menderita rugi akibat kesalahan, kelalaian, dan kealpaannya.",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

          // return pw.Stack(
          //   children: [
          //     // Logo di kiri atas
          //     pw.Positioned(
          //       left: 0,
          //       top: 0,
          //       child: pw.Image(logoImage, width: 50),
          //     ),

          //     // Teks di tengah horizontal atas
          //     pw.Positioned(
          //       top: 0,
          //       left: 0,
          //       right: 0,
          //       child: pw.Center(
          //         child: pw.Column(
          //           children: [
          //             pw.Text(
          //               'KOMISI PEMILIHAN UMUM',
          //               style: pw.TextStyle(
          //                 fontSize: 14,
          //                 fontWeight: pw.FontWeight.bold,
          //               ),
          //             ),
          //             pw.Text(
          //               'PROVINSI JAMBI',
          //               style: pw.TextStyle(
          //                 fontSize: 14,
          //                 fontWeight: pw.FontWeight.bold,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ],
          // );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/SPD_${dataUser["namapegawai"]}.pdf");
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Stream<Map<String, dynamic>> getSpj(String perjadinId, String nipPegawai) {
    final perjadinQuery = db.collection("surat_perjadin").doc(perjadinId).get();
    return perjadinQuery.asStream().asyncExpand((perjadinSnapshot) {
      if (!perjadinSnapshot.exists) {
        return Stream.value({});
      }

      final perjadinData = perjadinSnapshot.data() ?? {};
      Map<String, dynamic> dataUser = {};

      for (var item in perjadinData['peserta']) {
        if (item['nippegawai'] == nipPegawai) {
          dataUser.addAll(item);
        }
      }

      return db
          .collection("surat_perjadin")
          .doc(perjadinId)
          .collection("spj")
          .doc(nipPegawai)
          .snapshots()
          .map((spjSnapshot) {
            final spjData = spjSnapshot.data() ?? {};
            uangHarianT.text = formatCurrency(spjData["uang_harian"]);
            uangFullBordT.text = formatCurrency(spjData["uang_fullbord"]);
            uangPenginapanT.text = formatCurrency(spjData["uang_penginapan"]);
            uangTransportasiT.text = formatCurrency(
              spjData["uang_transportasi"],
            );
            uangTiketPesawatT.text = formatCurrency(
              spjData["uang_tiket_pesawat"],
            );
            representasiT.text = formatCurrency(spjData["representasi"]);
            jumlahHariUangHarianT.text =
                spjData["jumlahhariuangharian"].toString();
            jumlahHariFullbordT.text = spjData["jumlahharifullbord"].toString();
            totalSpj.value = spjData["total"];
            return {"user": dataUser, "perjadin": perjadinData};
          });
    });

    // final userQuery =
    //     db.collection("users").where("nippegawai", isEqualTo: nipPegawai).get();
    // return userQuery.asStream().asyncExpand((userSnapshot) {

    //   if (userSnapshot.docs.isEmpty) {
    //     return Stream.value({});
    //   }

    //   final perjadinQuery =
    //       db.collection("surat_perjadin").doc(perjadinId).get();
    //   return perjadinQuery.asStream().asyncExpand((perjadinSnapshot) {
    //     if (!perjadinSnapshot.exists) {
    //       return Stream.value({});
    //     }

    //     final userData = userSnapshot.docs.first.data();
    //     final perjadinData = perjadinSnapshot.data() ?? {};

    //     return db
    //         .collection("surat_perjadin")
    //         .doc(perjadinId)
    //         .collection("spj")
    //         .doc(nipPegawai)
    //         .snapshots()
    //         .map((spjSnapshot) {
    //           final spjData = spjSnapshot.data() ?? {};
    //           uangHarianT.text = formatCurrency(spjData["uang_harian"]);
    //           uangFullBordT.text = formatCurrency(spjData["uang_fullbord"]);
    //           uangPenginapanT.text = formatCurrency(spjData["uang_penginapan"]);
    //           uangTransportasiT.text = formatCurrency(
    //             spjData["uang_transportasi"],
    //           );
    //           uangTiketPesawatT.text = formatCurrency(
    //             spjData["uang_tiket_pesawat"],
    //           );
    //           representasiT.text = formatCurrency(spjData["representasi"]);
    //           jumlahHariUangHarianT.text =
    //               spjData["jumlahhariuangharian"].toString();
    //           jumlahHariFullbordT.text =
    //               spjData["jumlahharifullbord"].toString();
    //           totalSpj.value = spjData["total"];
    //           return {
    //             "user": userData,
    //             "spj": spjData,
    //             "perjadin": perjadinData,
    //           };
    //         });
    //   });
    // });
  }

  void updateSpj(String perjadinId, String nipPegawai) {
    final spjData = {
      "uang_harian": parseCurrency(uangHarianT.text),
      "uang_fullbord": parseCurrency(uangFullBordT.text),
      "uang_penginapan": parseCurrency(uangPenginapanT.text),
      "uang_transportasi": parseCurrency(uangTransportasiT.text),
      "uang_tiket_pesawat": parseCurrency(uangTiketPesawatT.text),
      "representasi": parseCurrency(representasiT.text),
      "jumlahhariuangharian": parseCurrency(jumlahHariUangHarianT.text),
      "jumlahharifullbord": parseCurrency(jumlahHariFullbordT.text),
      "total": totalSpj.value,
    };
    try {
      db
          .collection("surat_perjadin")
          .doc(perjadinId)
          .collection("spj")
          .doc(nipPegawai)
          .update(spjData);
      Get.snackbar("Berhasil", "SPJ berhasil disimpan");
    } on FirebaseException catch (e) {
      print(e);
    }
    clearFieldSPJ();
    Get.back();
  }

  Future<void> generateSPJ(String perjadinId, String nipPegawai) async {
    await initializeDateFormatting('id_ID');
    Intl.defaultLocale = 'id_ID';
    final docPerjadin = db.collection("surat_perjadin").doc(perjadinId);
    final perjadinSnapshot = await docPerjadin.get();
    final dataPerjadin = perjadinSnapshot.data()!;

    final userSnapshot = dataPerjadin["peserta"];
    Map<String, dynamic> docUser = {};
    for (var item in userSnapshot) {
      docUser.addAll(item);
    }

    final docCurrentPejabat =
        await docPerjadin
            .collection("currentPejabat")
            .doc(perjadinSnapshot.data()!["idCurrentPejabat"])
            .get();
    final currentPejabatSnapshot = docCurrentPejabat.data()!;

    final docSpj =
        await db
            .collection("surat_perjadin")
            .doc(perjadinId)
            .collection("spj")
            .doc(nipPegawai)
            .get();
    final dataSpj = docSpj.data()!;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'KOMISI PEMILIHAN UMUM PROVINSI JAMBI',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Jl. Jend. A. Thalib Nomor.33 Telanaipura Jambi 36124',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Telp. (0741) 670121',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Fax. (0741) 670772',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.Center(
                child: pw.Text(
                  'RINCIAN PERTANGGUNGJAWABAN',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'BIAYA PERJALANAN DINAS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),

              pw.SizedBox(height: 10),
              pw.Table(
                columnWidths: {
                  0: pw.FixedColumnWidth(15),
                  1: pw.FixedColumnWidth(3),
                  2: pw.FixedColumnWidth(100),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text("Nomor SPD"),
                      pw.Text(":"),
                      pw.Text("${dataPerjadin['nospd']}"),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Text("Tanggal"),
                      pw.Text(":"),
                      pw.Text(
                        "${DateFormat('dd MMMM yyyy').format(dataPerjadin["tanggalberangkat"].toDate())} s.d ${DateFormat('dd MMMM yyyy').format(dataPerjadin["tanggalkembali"].toDate())}",
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder(
                  verticalInside: pw.BorderSide(width: 1),
                  top: pw.BorderSide(width: 1),
                  bottom: pw.BorderSide(width: 1),
                  left: pw.BorderSide(width: 1),
                  right: pw.BorderSide(width: 1),
                ),
                columnWidths: {
                  0: pw.FlexColumnWidth(.3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Container(
                        padding: pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 2)),
                        ),
                        child: pw.Text(
                          "NO",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 2)),
                        ),
                        child: pw.Text(
                          "PERINCIAN BIAYA",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 2)),
                        ),
                        child: pw.Text(
                          "JUMLAH",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 2)),
                        ),
                        child: pw.Text(
                          "KETERANGAN",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "1",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Uang Harian"),
                            pw.Text(
                              "${dataSpj['jumlahhariuangharian']}(Hari) Rp. ${formatCurrency(dataSpj['uang_harian'])},-",
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "Rp. ${formatCurrency(dataSpj['uang_harian'] * dataSpj['jumlahhariuangharian'])}",
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "2",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Uang Fullbord, Helpday"),
                            pw.Text(
                              "${dataSpj['jumlahharifullbord']}(Hari) Rp. ${formatCurrency(dataSpj['uang_fullbord'])}",
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "Rp. ${formatCurrency(dataSpj['uang_fullbord'] * dataSpj['jumlahharifullbord'])}",
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "3",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text("Uang Penginapan"),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "Rp. ${formatCurrency(dataSpj['uang_penginapan'])}",
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "4",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text("Bantuan BBM/Transport Lokal"),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "Rp. ${formatCurrency(dataSpj['uang_transportasi'])}",
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "5",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text("Uang Tiket Pesawat PP"),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "Rp. ${formatCurrency(dataSpj['uang_tiket_pesawat'])}",
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "6",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text("Representasi"),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "Rp. ${formatCurrency(dataSpj['representasi'])}",
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          "",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 2)),
                        ),
                        child: pw.Text(
                          "TOTAL JUMLAH",
                          textAlign: pw.TextAlign.end,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        padding: pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 2)),
                        ),
                        child: pw.Text(
                          "Rp. ${formatCurrency(dataSpj['total'])}",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Container(
                        height: 26,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 2)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Container(
                padding: pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text(
                      "TERBILANG : ",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        "${Terbilang().terbilang(dataSpj['total'].toDouble())} Rupiah",
                        overflow: pw.TextOverflow.visible,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Telah dibayar sejumlah"),
                          pw.Text("Rp. ${formatCurrency(dataSpj['total'])}"),
                          pw.Text('Bendahara Pengeluaran'),
                        ],
                      ),
                      pw.SizedBox(height: 25),
                      pw.Text(
                        formatNamaMultiGelar(
                          currentPejabatSnapshot["currentBendahara"]["namapegawai"],
                        ),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'NIP. ${currentPejabatSnapshot["currentBendahara"]["nippegawai"]}',
                      ),
                    ],
                  ),

                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("JAMBI"),
                          pw.Text("Telah menerima uang sejumlah"),
                          pw.Text("Rp. ${formatCurrency(dataSpj['total'])}"),
                          pw.Text('Yang Menerima'),
                        ],
                      ),
                      pw.SizedBox(height: 25),
                      pw.Text(
                        formatNamaMultiGelar(docUser["namapegawai"]),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.Center(
                child: pw.Text(
                  "PERHITUNGAN SPD RAMPUNG",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(.5),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text("Ditetapkan jumlah"),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(
                          "Rp. ${formatCurrency(dataSpj['total'])}",
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text("Jumlah Total"),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(
                          "Rp. ${formatCurrency(dataSpj['total'])}",
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text("Biaya dalam Pengeluaran Rill"),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text("Rp. 0"),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text("Jumlah Total"),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(
                          "Rp. ${formatCurrency(dataSpj['total'])}",
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text("Terbilang"),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(
                          "${Terbilang().terbilang(dataSpj['total'].toDouble())} Rupiah",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  children: [
                    pw.Text("Pejabat Pembuat Komitmen"),
                    pw.SizedBox(height: 30),
                    pw.Text(
                      formatNamaMultiGelar(
                        currentPejabatSnapshot['currentPPK']['namapegawai'],
                      ),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      "NIP. ${currentPejabatSnapshot['currentPPK']['nippegawai']}",
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                "Catatan: Bukti-bukti perjalanan dinas sepenuhnya menjadi tanggungjawab saya pelaku pelaksana SPD",
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/SPJ_${docUser["namapegawai"]}.pdf");
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Future<void> kirimNotifikasiKePPK(String idPerjadin, String tokenPPK) async {
    final dio = Dio();
    final url = 'https://backendspdin-production.up.railway.app/sendnotif';

    try {
      final response = await dio.post(
        url,
        data: {
          "token": tokenPPK,
          "body": "Operator mengirim pengjuan SPT.",
          "id_perjadin": idPerjadin,
        },
      );
      if (response.statusCode == 200) {
        print(response.data["msg"].toString());
      } else {
        print("Error: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      print(e);
      return;
    }
  }

  @override
  void onInit() {
    super.onInit();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFFFFF), // Background status bar
        statusBarIconBrightness: Brightness.dark, // Ikon gelap
      ),
    );
    maksudPerjalananT = TextEditingController();
    tempatBerangkatT = TextEditingController();
    tempatTujuanT = TextEditingController();
    suratPerintah.value = "";
    peserta.add(null);

    //SPJ
    uangHarianT = TextEditingController();
    uangFullBordT = TextEditingController();
    uangPenginapanT = TextEditingController();
    uangTransportasiT = TextEditingController();
    uangTiketPesawatT = TextEditingController();
    representasiT = TextEditingController();
    jumlahHariUangHarianT = TextEditingController();
    jumlahHariFullbordT = TextEditingController();
  }

  @override
  void onReady() {
    super.onReady();
    peserta.add(null);
  }

  @override
  void onClose() {
    super.onClose();
    maksudPerjalananT.dispose();
    tempatBerangkatT.dispose();
    tempatTujuanT.dispose();
    peserta.clear();
    peserta.value = [];
    suratPerintah.value = "";
    tanggalBerangkat.value = null;
    tanggalKembali.value = null;

    //SPJ
    uangHarianT.dispose();
    uangFullBordT.dispose();
    uangPenginapanT.dispose();
    uangTransportasiT.dispose();
    uangTiketPesawatT.dispose();
    representasiT.dispose();
    jumlahHariUangHarianT.dispose();
    jumlahHariFullbordT.dispose();
    totalSpj.value = 0;
  }
}
