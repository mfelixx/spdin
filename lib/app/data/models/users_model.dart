class UsersModel {
  String? uid;
  String? namapegawai;
  String? emailpegawai;
  String? nippegawai;
  String? password;
  String? jabatan;
  String? jenjang;
  String? pangkat;
  String? role;

  UsersModel({
    this.uid,
    this.namapegawai,
    this.emailpegawai,
    this.nippegawai,
    this.password,
    this.jabatan,
    this.jenjang,
    this.pangkat,
    this.role,
  });

  factory UsersModel.fromJson(String id, Map<String, dynamic> json) {
    return UsersModel(
      uid: id,
      namapegawai: json["namapegawai"] ?? "",
      emailpegawai: json["emailpegawai"] ?? "",
      nippegawai: json["nippegawai"] ?? "",
      password: json["password"] ?? "",
      jabatan: json["jabatan"] ?? "",
      jenjang: json["jenjang"] ?? "",
      pangkat: json["pangkat"] ?? "",
      role: json["role"] ?? "",
    );
  }
}
