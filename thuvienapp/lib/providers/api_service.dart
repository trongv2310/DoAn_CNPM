import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sach.dart';
import '../models/user.dart';

class ApiService {
  // LƯU Ý: Kiểm tra kỹ PORT này.
  // Nếu bạn chạy Backend thấy hiện "Listening on ...:5008" thì đúng.
  // Nếu thấy 5000 hay số khác, hãy sửa lại số 5008 bên dưới.
  static const String baseUrl = "http://10.0.2.2:5008/api";

  // 1. ĐĂNG NHẬP
  Future<User?> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/Auth/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Username": username, // SỬA LỖI: Viết hoa chữ U để khớp với AuthController.cs
          "Password": password  // SỬA LỖI: Viết hoa chữ P
        }),
      );

      if (response.statusCode == 200) {
        print("Login thành công: ${response.body}");
        return User.fromJson(jsonDecode(response.body));
      } else {
        print("Login thất bại: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Lỗi kết nối đăng nhập: $e");
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
      } else {
        print("Lỗi lấy sách: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Exception lấy sách: $e");
      return [];
    }
  }

// 3. CHỨC NĂNG THỦ KHO: Nhập Hàng
  Future<bool> nhapHang(int maThuKho, List<Map<String, dynamic>> chiTiet) async {
    // Lỗi của bạn là do dòng dưới này không thấy biến baseUrl
    final url = Uri.parse('$baseUrl/ThuKho/nhap-hang');
    try {
      final body = jsonEncode({
        "MaThuKho": maThuKho,
        "ChiTiet": chiTiet
      });

      print("Đang gửi nhập hàng: $body");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Lỗi nhập hàng: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception nhập hàng: $e");
      return false;
    }
  }
  // 4. CHỨC NĂNG THỦ KHO: Thanh Lý
  Future<bool> thanhLySach(int maThuKho, List<Map<String, dynamic>> chiTiet) async {
    final url = Uri.parse('$baseUrl/ThuKho/thanh-ly');
    try {
      final body = jsonEncode({
        "MaThuKho": maThuKho,
        "ChiTiet": chiTiet
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Lỗi thanh lý: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception thanh lý: $e");
      return false;
    }
  }

  // 5. Lấy lịch sử nhập hàng
  Future<List<dynamic>> fetchLichSuNhap(int maThuKho) async {
    final url = Uri.parse('$baseUrl/ThuKho/lich-su-nhap/$maThuKho');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print("Lỗi lấy lịch sử: $e");
      return [];
    }
  }

  // 6. Lấy thống kê báo cáo (Thủ kho)
  Future<List<dynamic>> fetchBaoCaoTaiChinh(int nam) async {
    final url = Uri.parse('$baseUrl/ThuKho/thong-ke/$nam');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print("Lỗi thống kê: $e");
      return [];
    }
  }

  // 7. Đổi mật khẩu (Chung)
  Future<bool> doiMatKhau(int maTaiKhoan, String matKhauCu, String matKhauMoi) async {
    final url = Uri.parse('$baseUrl/Auth/doi-mat-khau');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "MaTaiKhoan": maTaiKhoan,
          "MatKhauCu": matKhauCu,
          "MatKhauMoi": matKhauMoi
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Lỗi đổi pass: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception đổi pass: $e");
      return false;
    }
  }
}
