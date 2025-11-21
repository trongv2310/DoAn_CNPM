class User {
  final int maTaiKhoan;
  final String tenDangNhap;
  final String hoVaTen;
  final int maQuyen;
  final int entityId; // Đây là MASV (nếu là SV) hoặc MATT/MATK

  User({
    required this.maTaiKhoan,
    required this.tenDangNhap,
    required this.hoVaTen,
    required this.maQuyen,
    required this.entityId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      maTaiKhoan: json['maTaiKhoan'] ?? json['MaTaiKhoan'] ?? 0,
      tenDangNhap: json['tenDangNhap'] ?? json['TenDangNhap'] ?? '',
      hoVaTen: json['hoVaTen'] ?? json['HoVaTen'] ?? 'Người dùng',
      maQuyen: json['maQuyen'] ?? json['MaQuyen'] ?? 4,

      // Dòng này quan trọng nhất để lấy đúng ID Sinh viên
      entityId: json['entityId'] ?? json['EntityId'] ?? json['MaSinhVien'] ?? json['MaThuThu'] ?? 0,
    );
  }
}