import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> requestPhotoPermission() async {
    if (await Permission.photos.isGranted ||
        await Permission.storage.isGranted ||
        await Permission.mediaLibrary.isGranted ||
        await Permission.manageExternalStorage.isGranted ||
        await Permission.videos.isGranted) {
      return true;
    }

    // Minta izin ke user
    // var status = await Permission.photos.request();
    // if (status.isGranted) return true;

    // Untuk Android < 13
    // status = await Permission.storage.request();
    // return status.isGranted;

    if (await Permission.photos.request().isGranted) return true;
    if (await Permission.storage.request().isGranted) return true;
    if (await Permission.mediaLibrary.request().isGranted) return true;
    if (await Permission.manageExternalStorage.request().isGranted) return true;

    return false;
  }

  static Future<bool> requestCameraPermission() async {
    if (await Permission.camera.isGranted) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}
