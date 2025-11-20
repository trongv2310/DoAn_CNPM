import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sach.dart';
import '../models/user.dart';
import '../models/borrowed_book_history.dart';

// DTO gửi đi
class SachMuonRequest {
  final int maSach;
  final int soLuong;

  SachMuonRequest({required this.maSach, required this.soLuong});

  Map<String, dynamic> toJson() {
    return {
      'MaSach': maSach,
      'SoLuong': soLuong,
    };
  }
}

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5008/api";
  static const String imageBaseUrl = "http://10.0.2.2:5008/images";

  static String getImageUrl(String? imageName) {
    if (imageName == null || imageName.isEmpty) return "";
    if (imageName.startsWith('http')) return imageName;
    return "$imageBaseUrl/$imageName";
  }

  // --- HÀM MƯỢN SÁCH (CÓ NGÀY HẸN TRẢ & TRẢ VỀ MÃ PHIẾU) ---
  Future<Map<String, dynamic>> muonNhieuSachFull(
      int maTaiKhoan,
      List<SachMuonRequest> sachCanMuon,
      DateTime ngayHenTra // <--- Nhận ngày hẹn trả
      ) async {
    final url = Uri.parse('$baseUrl/PhieuMuon');

    try {
      List<Map<String, dynamic>> listSachJson = sachCanMuon.map((sach) => sach.toJson()).toList();

      // Body gửi đi (Khớp với DTO C#)
      final body = jsonEncode({
        "MaTaiKhoan": maTaiKhoan,
        "SachMuon": listSachJson,
        "NgayHenTra": ngayHenTra.toIso8601String() // Gửi ngày dạng ISO
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Thành công: Lấy Mã Phiếu Mượn
        return {
          "success": true,
          "maPhieuMuon": data['maPhieuMuon'] ?? 0,
          "message": data['message']
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Lỗi từ máy chủ"
        };
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      return {"success": false, "message": "Lỗi kết nối đến máy chủ."};
    }
  }

  // (Các hàm login, fetchSaches, fetchLichSuMuon giữ nguyên...)
  // 1. ĐĂNG NHẬP
  Future<User?> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/Auth/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Username": username,
          "Password": password
        }),
      );
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 2. LẤY SÁCH
  Future<List<Sach>> fetchSaches() async {
    final url = Uri.parse('$baseUrl/Sach');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Sach.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 3. LẤY LỊCH SỬ
  Future<List<BorrowedBookHistory>> fetchLichSuMuon(int maTaiKhoan) async {
    final url = Uri.parse('$baseUrl/PhieuMuon/History/$maTaiKhoan');
    try {
      final response = await http.get(url);

      // --- THÊM DÒNG NÀY ĐỂ DEBUG ---
      print("📥 API Response Code: ${response.statusCode}");
      print("📥 API Response Body: ${response.body}");
      // -----------------------------

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => BorrowedBookHistory.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Lỗi kết nối lịch sử: $e"); // Xem có lỗi gì ở đây không
      return [];
    }
  }
  // 4. TRẢ SÁCH
  Future<bool> traSach(int maPhieuMuon, int maSach) async { // Thêm mã sách để biết trả cuốn nào
    final url = Uri.parse('$baseUrl/PhieuTra');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "MaPhieuMuon": maPhieuMuon,
          "MaSach": maSach // Cần biết trả sách nào vì 1 phiếu có thể mượn nhiều sách
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Lỗi trả sách: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception trả sách: $e");
      return false;
    }
  }
  // 5. TÌM KIẾM SÁCH
  Future<List<Sach>> searchSaches(String keyword) async {
    // Gọi endpoint vừa tạo
    final url = Uri.parse('$baseUrl/Sach/timkiem?keyword=$keyword');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Sach.fromJson(e)).toList();
      } else {
        // Nếu 404 hoặc lỗi khác thì trả về danh sách rỗng
        return [];
      }
    } catch (e) {
      print("Lỗi tìm kiếm: $e");
      return [];
    }
  }
  // 6. GIA HẠN SÁCH (CÓ CHỌN NGÀY + MÃ SÁCH)
  Future<Map<String, dynamic>> giaHanSach(int maPhieuMuon, int maSach, DateTime ngayMoi) async {
    final url = Uri.parse('$baseUrl/PhieuMuon/Extend/$maPhieuMuon');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "MaSach": maSach, // <-- Gửi thêm mã sách
          "NgayHenTraMoi": ngayMoi.toIso8601String()
        }),
      );
      // ... giữ nguyên phần xử lý response
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": data['message']};
      } else {
        return {"success": false, "message": data['message'] ?? "Lỗi khi gia hạn"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối máy chủ"};
    }
  }
}