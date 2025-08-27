import 'package:get/get.dart';
import 'package:perjadin_kpu/app/modules/pegawai/views/uploadimage_view.dart';

import '../modules/admin/bindings/admin_binding.dart';
import '../modules/admin/views/admin_view.dart';
import '../modules/admin/views/editpegawai_view.dart';
import '../modules/admin/views/tambahpegawai_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/auth/views/splashscreen_view.dart';
import '../modules/operator/bindings/operator_binding.dart';
import '../modules/operator/views/editperjadin_view.dart';
import '../modules/operator/views/operator_view.dart';
import '../modules/operator/views/pdfpreview_view.dart';
import '../modules/operator/views/spj_view.dart';
import '../modules/operator/views/tambahperjadin_view.dart';
import '../modules/pegawai/bindings/pegawai_binding.dart';
import '../modules/pegawai/views/pegawai_view.dart';
import '../modules/ppk/bindings/ppk_binding.dart';
import '../modules/ppk/views/detailppk_view.dart';
import '../modules/ppk/views/ppk_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = [
    // Auth
    GetPage(name: _Paths.AUTH, page: () => AuthView(), binding: AuthBinding()),
    GetPage(name: _Paths.SPLASHSCREEN, page: () => SplashscreenView()),

    // Admin
    GetPage(
      name: _Paths.ADMIN,
      page: () => AdminView(),
      binding: AdminBinding(),
    ),

    GetPage(
      name: _Paths.ADMIN_TAMBAHPEGAWAI,
      page: () => TambahpegawaiView(),
      binding: AdminBinding(),
    ),
    GetPage(
      name: _Paths.ADMIN_EDITPEGAWAI,
      page: () => EditpegawaiView(),
      binding: AdminBinding(),
    ),

    // Operator
    GetPage(
      name: _Paths.OPERATOR,
      page: () => OperatorView(),
      binding: OperatorBinding(),
    ),
    GetPage(
      name: _Paths.TAMBAH_PERJADIN,
      page: () => TambahperjadinView(),
      binding: OperatorBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_PERJADIN,
      page: () => EditperjadinView(),
      binding: OperatorBinding(),
    ),
    GetPage(
      name: _Paths.SPJ,
      page: () => SpjView(),
      binding: OperatorBinding(),
    ),

    // PPK
    GetPage(name: _Paths.PPK, page: () => PpkView(), binding: PpkBinding()),
    GetPage(
      name: _Paths.DETAIL_PERJADIN,
      page: () => DetailppkView(),
      binding: PpkBinding(),
    ),
    GetPage(
      name: _Paths.PDF_PREVIEW,
      page: () => PdfpreviewView(),
      binding: OperatorBinding(),
    ),

    GetPage(
      name: _Paths.PEGAWAI,
      page: () => PegawaiView(),
      binding: PegawaiBinding(),
    ),
    GetPage(
      name: _Paths.UPLOAD_SPJ,
      page: () => UploadimageView(),
      binding: PegawaiBinding(),
    ),
  ];
}
