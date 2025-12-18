import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sach.dart';
import '../models/user.dart';
import '../models/borrowed_book_history.dart';

// DTO: Class dùng để gửi yêu cầu mượn
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
  // 1. XÁC THỰC (AUTH)
  // ============================================================
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/Auth/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Username": username, "Password": password}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Đăng nhập thành công
        return {
          "success": true,
          "user": User.fromJson(body)
        };
      } else {
        // Đăng nhập thất bại (Sai pass hoặc Bị khóa)
        // Lấy message từ Backend trả về
        return {
          "success": false,
          "message": body['message'] ?? "Đăng nhập thất bại"
        };
      }
    } catch (e) {
      print("Lỗi login: $e");
      return {
        "success": false,
        "message": "Lỗi kết nối đến máy chủ: $e"
      };
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
  // 2. QUẢN LÝ SÁCH
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
  // 3. CHỨC NĂNG ĐỘC GIẢ (Mượn/Trả)
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
  // 4. CHỨC NĂNG THỦ KHO (Nhập/Thanh lý)
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
  // 5. TƯƠNG TÁC (Hỏi đáp/Góp ý)
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

  // ============================================================
  // 6. CHỨC NĂNG ADMIN (Quản lý tài khoản)
  // ============================================================

  // Lấy danh sách tất cả tài khoản
  Future<List<dynamic>> getAllUsers() async {
    final url = Uri.parse('$baseUrl/Admin/users');
    try {
      final response = await http.get(url);
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) {
      print("Lỗi get users: $e");
      return [];
    }
  }

  // Thêm tài khoản mới
  Future<bool> addUser(Map<String, dynamic> userData) async {
    final url = Uri.parse('$baseUrl/Admin/add-user');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi add user: $e");
      return false;
    }
  }

  // Cập nhật trạng thái (Khóa/Mở khóa)
  Future<bool> updateUserStatus(int id, String status) async {
    // API: api/Admin/update-status/{id}?status=...
    final url = Uri.parse('$baseUrl/Admin/update-status/$id?status=$status');
    try {
      final response = await http.post(url);
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi update status: $e");
      return false;
    }
  }

  // Xóa tài khoản
  Future<bool> deleteUser(int id) async {
    final url = Uri.parse('$baseUrl/Admin/delete-user/$id');
    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi delete user: $e");
      return false;
    }
  }

  // --- ADMIN: NHẬT KÝ HỆ THỐNG ---
  Future<List<dynamic>> getSystemLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Admin/logs-system'));
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getTransactionLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Admin/logs-transaction'));
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getViolationLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Admin/logs-violation'));
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) { return []; }
  }

  // --- ADMIN: BÁO CÁO ---
  Future<Map<String, dynamic>> getLibrarianReport() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Admin/report-librarian'));
      return response.statusCode == 200 ? json.decode(response.body) : {};
    } catch (e) { return {}; }
  }

  Future<Map<String, dynamic>> getStorekeeperReport() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Admin/report-storekeeper'));
      return response.statusCode == 200 ? json.decode(response.body) : {};
    } catch (e) { return {}; }
  }

  // ============================================================
  // 7. CHỨC NĂNG THỦ THƯ (LIBRARIAN)
  // ============================================================

  // 1. Lấy danh sách phiếu chờ duyệt
  Future<List<dynamic>> getPendingBorrowRequests() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/PhieuMuon/pending'));
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) { return []; }
  }

  // 2. Duyệt phiếu mượn
  Future<bool> approveRequest(int maPhieu, int maThuThu) async {
    // API backend đã có sẵn: /PhieuMuon/approve/{mapm}?maThuThuDuyet=...
    final url = Uri.parse('$baseUrl/PhieuMuon/approve/$maPhieu?maThuThuDuyet=$maThuThu');
    try {
      final response = await http.post(url);
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // 3. Lấy danh sách câu hỏi hỗ trợ
  Future<List<dynamic>> getAllQuestions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/TuongTac/all-questions'));
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) { return []; }
  }

  // 4. Trả lời câu hỏi
  Future<bool> replyQuestion(int maHoiDap, int maThuThu, String answer) async {
    final url = Uri.parse('$baseUrl/TuongTac/tra-loi');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "MaHoiDap": maHoiDap,
          "MaThuThu": maThuThu,
          "NoiDungTraLoi": answer
        }),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }



  // Lấy danh sách đang mượn để trả sách
  Future<List<dynamic>> getBorrowedBooks() async {
    final url = Uri.parse('$baseUrl/PhieuMuon/borrowed-books');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Lỗi getBorrowedBooks: $e");
      return [];
    }
  }

  // Độc giả gửi yêu cầu trả
  Future<Map<String, dynamic>> requestReturnBook(int maPhieu, int maSach) async {
    final url = Uri.parse('$baseUrl/PhieuMuon/request-return');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        // Backend chỉ cần MaPhieuMuon để update trạng thái phiếu
        body: jsonEncode({"MaPhieuMuon": maPhieu, "MaSach": maSach}),
      );
      final data = jsonDecode(response.body);
      return {"success": response.statusCode == 200, "message": data['message']};
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }

  // Lấy thống kê duyệt mượn
  Future<Map<String, int>> getApprovalStats() async {
    final url = Uri.parse('$baseUrl/PhieuMuon/approval-stats');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'choDuyet': data['ChoDuyet'] ?? 0,
          'daDuyet': data['DaDuyet'] ?? 0,
          'tuChoi': data['TuChoi'] ?? 0,
        };
      }
      return {'choDuyet': 0, 'daDuyet': 0, 'tuChoi': 0};
    } catch (e) {
      return {'choDuyet': 0, 'daDuyet': 0, 'tuChoi': 0};
    }
  }

  // Lấy danh sách lịch sử duyệt (type: 'approved' hoặc 'rejected')
  Future<List<dynamic>> getHistoryRequests(String type) async {
    final url = Uri.parse('$baseUrl/PhieuMuon/history-by-type?type=$type');
    try {
      final response = await http.get(url);
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

// Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/Auth/register');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": body['message']};
      } else {
        return {"success": false, "message": body['message'] ?? "Đăng ký thất bại"};
      }
    } catch (e) {
      return {"success": false, "message": "Lỗi kết nối: $e"};
    }
  }
  Future<bool> thanhToanPhat(int maPhieu) async {
    final url = Uri.parse('$baseUrl/PhieuMuon/thanh-toan-phat/$maPhieu');
    try {
      final response = await http.post(url);
      // Nếu thành công (200), trả về true
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi thanh toán: $e");
      return false;
    }
  }
  Future<List<dynamic>> getExtensionRequests() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/PhieuMuon/extension-requests'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print("Lỗi lấy yêu cầu gia hạn: $e");
      return [];
    }
  }

  // 2. Duyệt hoặc Từ chối gia hạn
  Future<bool> processExtension(int maPhieu, int maSach, bool dongY) async {
    final url = Uri.parse('$baseUrl/PhieuMuon/process-extension');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "MaPhieu": maPhieu,
          "MaSach": maSach,
          "DongY": dongY
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi xử lý gia hạn: $e");
      return false;
    }
  }
  Future<Map<String, int>> getLibrarianStats() async {
    final url = Uri.parse('$baseUrl/PhieuMuon/librarian-stats');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // SỬA LỖI: Sử dụng int.parse hoặc ép kiểu an toàn
        return {
          'choDuyet': (data['choDuyet'] as num?)?.toInt() ?? 0,
          'yeuCauTra': (data['yeuCauTra'] as num?)?.toInt() ?? 0,
          'cauHoiMoi': (data['cauHoiMoi'] as num?)?.toInt() ?? 0,
          // Thêm dòng này để lấy số liệu gia hạn
          'yeuCauGiaHan': (data['yeuCauGiaHan'] ?? data['YeuCauGiaHan'] as num?)?.toInt() ?? 0,
        };
      }
      return {'choDuyet': 0, 'yeuCauTra': 0, 'cauHoiMoi': 0, 'yeuCauGiaHan': 0};
    } catch (e) {
      print("Lỗi lấy thống kê: $e");
      return {'choDuyet': 0, 'yeuCauTra': 0, 'cauHoiMoi': 0, 'yeuCauGiaHan': 0};
    }
  }
  // Hủy yêu cầu mượn (khi còn chờ duyệt)
  Future<bool> huyYeuCauMuon(int maPhieu) async {
    final url = Uri.parse('$baseUrl/PhieuMuon/cancel/$maPhieu');
    try {
      final response = await http.post(url);

      // Nếu xóa thành công (status 200)
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi hủy yêu cầu: $e");
      return false;
    }
  }

  Future<List<dynamic>> fetchList(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load stats');
    }
  }

  Future<List<dynamic>> fetchNewBooksNews() async {
    return fetchList('/Admin/news-new-books');
  }
}