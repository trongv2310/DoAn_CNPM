import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sach.dart';
import '../models/user.dart';
import '../models/borrowed_book_history.dart'; // Đảm bảo bạn đã có file model này từ nhánh Đăng

// DTO: Class dùng để gửi yêu cầu mượn (Lấy từ nhánh Đăng)
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
  // LƯU Ý: Đổi 10.0.2.2 thành IP máy tính nếu chạy máy thật (VD: 192.168.1.x)
  static const String baseUrl = "http://10.0.2.2:5008/api";
  static const String imageBaseUrl = "http://10.0.2.2:5008/images";

  static String getImageUrl(String? imageName) {
    if (imageName == null || imageName.isEmpty) return "";
    if (imageName.startsWith('http')) return imageName;
    // Ghép link: http://10.0.2.2:5008/images/hp1.jpg
    return "$imageBaseUrl/$imageName";
  }

  // ============================================================
  // 1. XÁC THỰC (AUTH) - Dùng chung
  // ============================================================
  Future<User?> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/Auth/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Username": username, "Password": password}),
      );
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Lỗi login: $e");
      return null;
    }
  }

  Future<bool> doiMatKhau(int maTaiKhoan, String matKhauCu, String matKhauMoi) async {
    final url = Uri.parse('$baseUrl/Auth/doi-mat-khau');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"MaTaiKhoan": maTaiKhoan, "MatKhauCu": matKhauCu, "MatKhauMoi": matKhauMoi}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // 2. QUẢN LÝ SÁCH - Dùng chung
  // ============================================================
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

  Future<List<Sach>> searchSaches(String keyword) async {
    final url = Uri.parse('$baseUrl/Sach/timkiem?keyword=$keyword');
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

  // ============================================================
  // 3. CHỨC NĂNG ĐỘC GIẢ (Mượn/Trả) - Từ nhánh Đăng
  // ============================================================
  Future<Map<String, dynamic>> muonNhieuSachFull(
      int maSinhVien,
      List<SachMuonRequest> sachCanMuon,
      DateTime ngayHenTra) async {

    final url = Uri.parse('$baseUrl/PhieuMuon');

    // Kiểm tra an toàn: Nếu chưa có mã sinh viên thì báo lỗi ngay
    if (maSinhVien <= 0) {
      return {"success": false, "message": "Lỗi: Không tìm thấy Mã sinh viên. Hãy đăng nhập lại!"};
    }

    try {
      final body = jsonEncode({
        "MaTaiKhoan": maSinhVien, // Lưu ý: Backend đang đặt tên biến là MaTaiKhoan nhưng thực chất cần MASV
        "SachMuon": sachCanMuon.map((e) => e.toJson()).toList(),
        "NgayHenTra": ngayHenTra.toIso8601String()
      });

      print("LOG GỬI: $body"); // In ra để debug

      final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: body
      );

      print("LOG NHẬN (${response.statusCode}): ${response.body}");

      // --- SỬA LỖI FORMAT EXCEPTION TẠI ĐÂY ---
      // 1. Kiểm tra nếu body rỗng -> Trả về lỗi server thay vì crash app
      if (response.body.isEmpty) {
        return {"success": false, "message": "Server trả về rỗng (Mã: ${response.statusCode})"};
      }

      // 2. Chỉ decode khi có dữ liệu
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "maPhieuMuon": data['maPhieuMuon'], "message": data['message']};
      } else {
        return {"success": false, "message": data['message'] ?? "Lỗi server ${response.statusCode}"};
      }
    } catch (e) {
      print("Lỗi Exception: $e");
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  Future<List<BorrowedBookHistory>> fetchLichSuMuon(int maTaiKhoan) async {
    final url = Uri.parse('$baseUrl/PhieuMuon/History/$maTaiKhoan');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => BorrowedBookHistory.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> traSach(int maPhieuMuon, int maSach) async {
    final url = Uri.parse('$baseUrl/PhieuTra');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"MaPhieuMuon": maPhieuMuon, "MaSach": maSach}),
      );

      // Luôn cố gắng decode JSON trả về
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Thành công
        return {
          "success": true,
          "message": data['message'] ?? "Trả sách thành công!",
          "data": data // Chứa các thông tin phụ như tiền phạt (nếu có)
        };
      } else {
        // Thất bại (Lỗi logic từ server trả về)
        return {
          "success": false,
          "message": data['message'] ?? "Lỗi trả sách từ server"
        };
      }
    } catch (e) {
      // Lỗi kết nối hoặc lỗi code
      return {
        "success": false,
        "message": "Lỗi kết nối: $e"
      };
    }
  }

  Future<Map<String, dynamic>> giaHanSach(int maPhieuMuon, int maSach, DateTime ngayMoi) async {
    final url = Uri.parse('$baseUrl/PhieuMuon/Extend/$maPhieuMuon');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"MaSach": maSach, "NgayHenTraMoi": ngayMoi.toIso8601String()}),
      );
      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "message": data['message']};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối"};
    }
  }

  // ============================================================
  // 4. CHỨC NĂNG THỦ KHO (Nhập/Thanh lý) - Từ nhánh Trọng
  // ============================================================
  Future<bool> nhapHang(int maThuKho, List<Map<String, dynamic>> chiTiet) async {
    final url = Uri.parse('$baseUrl/ThuKho/nhap-hang');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"MaThuKho": maThuKho, "ChiTiet": chiTiet}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> thanhLySach(int maThuKho, List<Map<String, dynamic>> chiTiet) async {
    final url = Uri.parse('$baseUrl/ThuKho/thanh-ly');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"MaThuKho": maThuKho, "ChiTiet": chiTiet}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> fetchLichSuNhap(int maThuKho) async {
    final url = Uri.parse('$baseUrl/ThuKho/lich-su-nhap/$maThuKho');
    try {
      final response = await http.get(url);
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchBaoCaoTaiChinh(int nam) async {
    final url = Uri.parse('$baseUrl/ThuKho/thong-ke/$nam');
    try {
      final response = await http.get(url);
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // 5. TƯƠNG TÁC (Hỏi đáp/Góp ý) - Từ nhánh Trọng
  // ============================================================
  Future<bool> guiCauHoi(int maSV, String cauHoi) async {
    final url = Uri.parse('$baseUrl/TuongTac/gui-cau-hoi');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"MaSinhVien": maSV, "CauHoi": cauHoi}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> layLichSuHoiDap(int maSV) async {
    final url = Uri.parse('$baseUrl/TuongTac/lich-su-hoi-dap/$maSV');
    try {
      final response = await http.get(url);
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> guiGopY(int maSV, String noiDung, String loai) async {
    final url = Uri.parse('$baseUrl/TuongTac/gui-gop-y');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"MaSinhVien": maSV, "NoiDung": noiDung, "LoaiGopY": loai}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> layDanhGiaMoi() async {
    final url = Uri.parse('$baseUrl/TuongTac/danh-gia-moi');
    try {
      final response = await http.get(url);
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) {
      return [];
    }
  }
}