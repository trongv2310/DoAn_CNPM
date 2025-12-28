# 📚 Hệ Thống Quản Lý Thư Viện (Library Management System)

![Banner](images/banner.jpg)

> **Đồ án Công Nghệ Phần Mềm** > Một giải pháp toàn diện để quản lý thư viện trường học, bao gồm ứng dụng di động cho độc giả/nhân viên và hệ thống Backend quản trị mạnh mẽ.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![.NET](https://img.shields.io/badge/.NET-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)

---

## 📖 Giới thiệu

Dự án này là hệ thống quản lý thư viện được xây dựng với kiến trúc **Client-Server**. Hệ thống giúp tự động hóa quy trình mượn trả sách, quản lý kho sách, và cung cấp trải nghiệm hiện đại cho độc giả thông qua ứng dụng di động tích hợp Chatbot AI.

## 🚀 Tính Năng Chính

Hệ thống được phân quyền chặt chẽ cho 4 đối tượng người dùng:

### 👤 1. Độc Giả (Sinh viên/Giảng viên)
* **Tìm kiếm sách:** Tra cứu sách theo tên, thể loại, tác giả.
* **Mượn sách:** Thêm sách vào giỏ và gửi yêu cầu mượn trực tuyến.
* **Lịch sử:** Xem lịch sử mượn trả, sách đang mượn.
* **Tương tác:** Đánh giá, bình luận sách, Chatbot hỗ trợ trả lời câu hỏi tự động.
* **Cá nhân:** Quản lý thông tin tài khoản, đổi mật khẩu.

### 📚 2. Thủ Kho
* **Quản lý sách:** Nhập sách mới, cập nhật thông tin, hình ảnh bìa sách.
* **Kiểm kê:** Xem danh sách tồn kho, báo cáo nhập sách.
* **Thanh lý:** Xử lý các sách hư hỏng hoặc mất.

### 📝 3. Thủ Thư
* **Duyệt mượn:** Xác nhận hoặc từ chối yêu cầu mượn từ độc giả.
* **Trả sách:** Xử lý trả sách, tính phí phạt (nếu quá hạn hoặc hư hỏng).
* **Gia hạn:** Duyệt yêu cầu gia hạn sách.

### 🛡️ 4. Admin (Quản trị viên)
* **Quản lý người dùng:** Thêm, sửa, khóa tài khoản nhân viên và độc giả.
* **Nhật ký hệ thống:** Theo dõi toàn bộ hoạt động trong hệ thống.
* **Báo cáo thống kê:** Xem biểu đồ tổng quan về tình hình hoạt động.

---

## 🛠️ Công Nghệ Sử Dụng

### Backend (`/API_ThuVien`)
| Công nghệ | Mô tả |
| :--- | :--- |
| **ASP.NET Core Web API** | Framework chính để xây dựng RESTful API. |
| **Entity Framework Core** | ORM để làm việc với Database. |
| **SQL Server** | Hệ quản trị cơ sở dữ liệu. |
| **Swagger UI** | Tài liệu hóa và test API trực quan. |

### Mobile App (`/thuvienapp`)
| Công nghệ | Mô tả |
| :--- | :--- |
| **Flutter** | Framework phát triển ứng dụng đa nền tảng (Android/iOS). |
| **Provider** | Quản lý trạng thái (State Management). |
| **Http / Dio** | Xử lý kết nối mạng và gọi API. |
| **Image Picker** | Xử lý upload ảnh bìa sách. |

---

## 📸 Hình Ảnh Demo

| Màn hình chính | Chi tiết sách | Giỏ hàng |
| :---: | :---: | :---: |
| <img src="images/hp1.jpg" width="200"> | <img src="images/ts.jpg" width="200"> | <img src="images/alc.jpg" width="200"> |


---

## ⚙️ Cài Đặt & Hướng Dẫn Chạy

### Yêu cầu tiên quyết
* [Visual Studio 2022](https://visualstudio.microsoft.com/) (có workload .NET Desktop & Web).
* [SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-downloads).
* [Flutter SDK](https://docs.flutter.dev/get-started/install).
* [VS Code](https://code.visualstudio.com/) hoặc Android Studio.

### Bước 1: Cấu hình Cơ Sở Dữ Liệu
1.  Mở SQL Server Management Studio (SSMS).
2.  Chạy file script `ThuVienDB.sql` nằm ở thư mục gốc để tạo Database và dữ liệu mẫu.
3.  Lấy **Connection String** của máy bạn.

### Bước 2: Chạy Backend (API)
1.  Mở thư mục `API_ThuVien` bằng Visual Studio.
2.  Mở file `appsettings.json`, cập nhật dòng `ConnectionStrings` với thông tin SQL của bạn:
    ```json
    "ConnectionStrings": {
      "DefaultConnection": "Server=YOUR_SERVER_NAME;Database=ThuVienDB;Trusted_Connection=True;TrustServerCertificate=True;"
    }
    ```
3.  Nhấn **F5** hoặc nút **Run** để khởi chạy Server. (Mặc định API chạy tại `http://localhost:5xxx`).

### Bước 3: Chạy Mobile App
1.  Mở thư mục `thuvienapp` bằng Android Studio.
2.  Mở file cấu hình API (thường là `lib/providers/api_service.dart`) và cập nhật địa chỉ IP:
    ```dart
    // Thay localhost bằng IP LAN của máy tính nếu chạy trên điện thoại thật
    const String baseUrl = "[http://192.168.](http://192.168.)x.x:5xxx/api"; 
    ```
3.  Chạy lệnh cài đặt thư viện:
    ```bash
    flutter pub get
    ```
4.  Khởi chạy ứng dụng:
    ```bash
    flutter run
    ```

---
