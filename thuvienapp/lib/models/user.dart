class User {
  final int maTaiKhoan;
  final String tenDangNhap;
  final String hoVaTen; // Tên hiển thị ("Xin chào ...")
  final int maQuyen;

  User({
    required this.maTaiKhoan,
    required this.tenDangNhap,
    required this.hoVaTen,
    required this.maQuyen,
  });

  // Hàm này map đúng các key JSON trả về từ AuthController.cs
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      maTaiKhoan: json['maTaiKhoan'] ?? 0,
      tenDangNhap: json['tenDangNhap'] ?? '',
      hoVaTen: json['hoVaTen'] ?? 'Người dùng',
      maQuyen: json['maQuyen'] ?? 4,
    );
  }
}