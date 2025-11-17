class Sach {
  final int masach;
  final String tensach;
  final String? hinhanh;
  final double giamuon;
  final int soluongton;

  Sach({
    required this.masach,
    required this.tensach,
    this.hinhanh,
    required this.giamuon,
    required this.soluongton,
  });

  factory Sach.fromJson(Map<String, dynamic> json) {
    // API .NET thường trả về JSON dạng camelCase (chữ cái đầu viết thường)
    return Sach(
      masach: json['masach'] ?? 0,
      tensach: json['tensach'] ?? "Sách chưa cập nhật tên",
      hinhanh: json['hinhanh'],
      // Xử lý chuyển đổi an toàn sang double
      giamuon: (json['giamuon'] ?? 0).toDouble(),
      soluongton: json['soluongton'] ?? 0,
    );
  }
}