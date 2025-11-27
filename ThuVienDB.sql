-- =======================================================================================
-- SCRIPT HỢP NHẤT CƠ SỞ DỮ LIỆU THƯ VIỆN (MERGED VERSION)
-- TÍCH HỢP:
-- 1. Chức năng Mượn/Trả, Gia hạn, Giỏ hàng (Branch Dang)
-- 2. Chức năng Thủ kho, Nhập/Thanh lý, Tương tác, Báo cáo (Branch Trong)
-- =======================================================================================

USE ThuVienDB;
GO
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'ThuVienDB')
BEGIN
    ALTER DATABASE ThuVienDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ThuVienDB;
END
GO

CREATE DATABASE ThuVienDB;
GO

USE ThuVienDB;
GO

-- =============================================
-- 1) BẢNG PHÂN QUYỀN
-- =============================================
CREATE TABLE PHANQUYEN (
    MAQUYEN INT IDENTITY(1,1) PRIMARY KEY,
    TENQUYEN NVARCHAR(50) UNIQUE NOT NULL  -- Admin / ThuThu / ThuKho / DocGia
);
GO

-- =============================================
-- 2) BẢNG TÀI KHOẢN
-- =============================================
CREATE TABLE TAIKHOAN (
    MATAIKHOAN INT IDENTITY(1,1) PRIMARY KEY,
    TENDANGNHAP NVARCHAR(50) UNIQUE NOT NULL,
    MATKHAU NVARCHAR(255) NOT NULL, 
    TRANGTHAI NVARCHAR(20) DEFAULT N'Hoạt động' CHECK (TRANGTHAI IN (N'Hoạt động', N'Ngừng hoạt động')),
    MAQUYEN INT NOT NULL,

    CONSTRAINT FK_TAIKHOAN_PHANQUYEN FOREIGN KEY (MAQUYEN) REFERENCES PHANQUYEN(MAQUYEN)
);
GO

-- =============================================
-- 3) BẢNG THỦ THƯ
-- =============================================
CREATE TABLE THUTHU (
    MATT INT IDENTITY(1,1) PRIMARY KEY,
    MATAIKHOAN INT UNIQUE NOT NULL,
    HOVATEN NVARCHAR(100),
    GIOITINH NVARCHAR(5),
    NGAYSINH DATE,
    SDT VARCHAR(15),
    EMAIL VARCHAR(50) UNIQUE,

    CONSTRAINT FK_THUTHU_TAIKHOAN FOREIGN KEY (MATAIKHOAN) REFERENCES TAIKHOAN(MATAIKHOAN)
);
GO

-- =============================================
-- 4) BẢNG THỦ KHO
-- =============================================
CREATE TABLE THUKHO (
    MATK INT IDENTITY(1,1) PRIMARY KEY,
    MATAIKHOAN INT UNIQUE NOT NULL,
    HOVATEN NVARCHAR(100),
    GIOITINH NVARCHAR(5),
    NGAYSINH DATE,
    SDT VARCHAR(15),
    EMAIL VARCHAR(50) UNIQUE,

    CONSTRAINT FK_THUKHO_TAIKHOAN FOREIGN KEY (MATAIKHOAN) REFERENCES TAIKHOAN(MATAIKHOAN)
);
GO

-- =============================================
-- 5) BẢNG SINH VIÊN
-- =============================================
CREATE TABLE SINHVIEN (
    MASV INT IDENTITY(1,1) PRIMARY KEY,
    MATAIKHOAN INT UNIQUE NOT NULL,
    HOVATEN NVARCHAR(100),
    GIOITINH NVARCHAR(5),
    NGAYSINH DATE,
    SDT VARCHAR(15),
    EMAIL VARCHAR(50) UNIQUE,

    CONSTRAINT FK_SINHVIEN_TAIKHOAN FOREIGN KEY (MATAIKHOAN) REFERENCES TAIKHOAN(MATAIKHOAN)
);
GO

-- =========================================================
-- 6) BẢNG TÁC GIẢ
-- =========================================================
CREATE TABLE TACGIA (
    MATG INT IDENTITY(1,1) PRIMARY KEY,
    TENTG NVARCHAR(50) NOT NULL,
    QUOCTICH NVARCHAR(30) NULL,
    MOTA NVARCHAR(200) NULL
);
GO

-- =========================================================
-- 7) BẢNG NHÀ XUẤT BẢN
-- =========================================================
CREATE TABLE NHAXUATBAN (
    MANXB INT IDENTITY(1,1) PRIMARY KEY,
    TENNXB NVARCHAR(100) NOT NULL,
    DIACHI NVARCHAR(100),
    SDT VARCHAR(15) NULL
);
GO

-- =========================================================
-- 8) BẢNG SÁCH
-- =========================================================
CREATE TABLE SACH (
    MASACH INT IDENTITY(1,1) PRIMARY KEY,
    TENSACH NVARCHAR(100) NOT NULL,
    MATG INT NOT NULL,
    MANXB INT NOT NULL,
    HINHANH VARCHAR(255),
    THELOAI NVARCHAR(50),
    MOTA NVARCHAR(255),
    GIAMUON DECIMAL(10,2) NOT NULL CHECK (GIAMUON >= 0),
    SOLUONGTON INT NOT NULL DEFAULT 0 CHECK (SOLUONGTON >= 0),
    TRANGTHAI NVARCHAR(30) NOT NULL DEFAULT N'Có sẵn' CHECK (TRANGTHAI IN (N'Có sẵn', N'Đã hết')),

    CONSTRAINT FK_SACH_TACGIA FOREIGN KEY (MATG) REFERENCES TACGIA(MATG),
    CONSTRAINT FK_SACH_NXB FOREIGN KEY (MANXB) REFERENCES NHAXUATBAN(MANXB)
);
GO

-- =========================================================
-- 9) PHIẾU MƯỢN (MERGED: Thêm trạng thái Chờ duyệt/Từ chối & Số lần gia hạn)
-- =========================================================
CREATE TABLE PHIEUMUON (
    MAPM INT IDENTITY(1,1) PRIMARY KEY,
    MASV INT NOT NULL,
    MATT INT NOT NULL,
    NGAYLAPPHIEUMUON DATE NOT NULL,
    HANTRA DATE NOT NULL,
    
    -- [UPDATE] Thêm các trạng thái mới từ nhánh Dang để hỗ trợ quy trình mượn online
    TRANGTHAI NVARCHAR(30) NOT NULL DEFAULT N'Đang mượn',
    
    -- [UPDATE] Thêm cột đếm số lần gia hạn (nếu quản lý theo phiếu)
    SOLANGIAHAN INT DEFAULT 0,

    CONSTRAINT FK_PM_SV FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV),
    CONSTRAINT FK_PM_TT FOREIGN KEY (MATT) REFERENCES THUTHU(MATT),
    CONSTRAINT CK_PM_Ngay CHECK (NGAYLAPPHIEUMUON <= HANTRA),
    
    -- Ràng buộc trạng thái
    CONSTRAINT CK_PM_TRANGTHAI CHECK (TRANGTHAI IN (N'Chờ duyệt', N'Đang mượn', N'Chờ trả', N'Đã trả', N'Quá hạn', N'Thiếu', N'Quá hạn và Thiếu', N'Từ chối'))
);
GO

-- =========================================================
-- 10) CHI TIẾT PHIẾU MƯỢN (MERGED: Thêm Hạn trả riêng & Số lần gia hạn riêng)
-- =========================================================
CREATE TABLE CHITIETPHIEUMUON (
    MAPM INT NOT NULL,
    MASACH INT NOT NULL,
    SOLUONG INT DEFAULT 0 CHECK (SOLUONG >= 0),
    
    -- [UPDATE] Hỗ trợ gia hạn từng cuốn sách riêng biệt
    HANTRA DATE,
    SOLANGIAHAN INT DEFAULT 0,

    CONSTRAINT PK_CTPM PRIMARY KEY (MAPM, MASACH),
    CONSTRAINT FK_CTPM_PM FOREIGN KEY (MAPM) REFERENCES PHIEUMUON(MAPM),
    CONSTRAINT FK_CTPM_SACH FOREIGN KEY (MASACH) REFERENCES SACH(MASACH)
);
GO

-- =========================================================
-- 11) PHIẾU TRẢ
-- =========================================================
CREATE TABLE PHIEUTRA (
    MAPT INT IDENTITY(1,1) PRIMARY KEY,
    MAPM INT NOT NULL,
    MATT INT NOT NULL,
    NGAYLAPPHIEUTRA DATE NOT NULL,
    SONGAYQUAHAN INT DEFAULT 0 CHECK (SONGAYQUAHAN >= 0),
    TONGTIENPHAT FLOAT DEFAULT 0 CHECK (TONGTIENPHAT >= 0),

    CONSTRAINT FK_PT_PM FOREIGN KEY (MAPM) REFERENCES PHIEUMUON(MAPM),
    CONSTRAINT FK_PT_TT FOREIGN KEY (MATT) REFERENCES THUTHU(MATT)
);
GO

-- =========================================================
-- 12) CHI TIẾT PHIẾU TRẢ
-- =========================================================
CREATE TABLE CHITIETPHIEUTRA (
    MAPT INT NOT NULL,
    MASACH INT NOT NULL,
    SOLUONGTRA INT CHECK (SOLUONGTRA >= 0),
    NGAYTRA DATE,

    CONSTRAINT PK_CTPT PRIMARY KEY (MAPT, MASACH),
    CONSTRAINT FK_CTPT_PT FOREIGN KEY (MAPT) REFERENCES PHIEUTRA(MAPT),
    CONSTRAINT FK_CTPT_SACH FOREIGN KEY (MASACH) REFERENCES SACH(MASACH)
);
GO

-- =========================================================
-- 13) PHIẾU NHẬP (Chức năng Thủ kho)
-- =========================================================
CREATE TABLE PHIEUNHAP (
    MAPN INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    MATK INT NOT NULL,
    NGAYNHAP DATE NOT NULL,
    TONGTIEN DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (TONGTIEN >= 0),

    CONSTRAINT FK_PN_TK FOREIGN KEY (MATK) REFERENCES THUKHO(MATK)
);
GO

-- =========================================================
-- 14) CHI TIẾT PHIẾU NHẬP
-- =========================================================
CREATE TABLE CHITIETPHIEUNHAP (
    MAPN INT NOT NULL,
    MASACH INT NOT NULL,
    SOLUONG INT CHECK (SOLUONG > 0),
    GIANHAP DECIMAL(10,2) NOT NULL CHECK (GIANHAP >= 0),
    THANHTIEN AS (SOLUONG * GIANHAP) PERSISTED,

    CONSTRAINT PK_CTPN PRIMARY KEY (MAPN, MASACH),
    CONSTRAINT FK_CTPN_PN FOREIGN KEY (MAPN) REFERENCES PHIEUNHAP(MAPN),
    CONSTRAINT FK_CTPN_SACH FOREIGN KEY (MASACH) REFERENCES SACH(MASACH)
);
GO

-- =========================================================
-- 15) BẢNG THANH LÝ (Chức năng Thủ kho)
-- =========================================================
CREATE TABLE THANHLY (
    MATL INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    MATK INT NOT NULL,
    NGAYLAP DATE NOT NULL,
    TONGTIEN DECIMAL(12,2) DEFAULT 0 CHECK (TONGTIEN >= 0),

    CONSTRAINT FK_TL_TK FOREIGN KEY (MATK) REFERENCES THUKHO(MATK)
);
GO

-- =========================================================
-- 16) CHI TIẾT THANH LÝ
-- =========================================================
CREATE TABLE CHITIETTHANHLY (
    MATL INT NOT NULL,
    MASACH INT NOT NULL,
    SOLUONG INT NOT NULL CHECK (SOLUONG > 0),
    DONGIA DECIMAL(10,2) NOT NULL CHECK (DONGIA >= 0),
    THANHTIEN AS (SOLUONG * DONGIA) PERSISTED,

    CONSTRAINT PK_CTTL PRIMARY KEY (MATL, MASACH),
    CONSTRAINT FK_CTTL_TL FOREIGN KEY (MATL) REFERENCES THANHLY(MATL),
    CONSTRAINT FK_CTTL_SACH FOREIGN KEY (MASACH) REFERENCES SACH(MASACH)
);
GO

-- =========================================================
-- 17) BẢNG HỎI ĐÁP (Chức năng Tương tác - Mới)
-- =========================================================
CREATE TABLE HOIDAP (
    MAHOIDAP INT IDENTITY(1,1) PRIMARY KEY,
    MASV INT NOT NULL,
    CAUHOI NVARCHAR(MAX) NOT NULL,
    TRALOI NVARCHAR(MAX),
    MATT INT,
    THOIGIANHOI DATETIME DEFAULT GETDATE(),
    THOIGIANTRALOI DATETIME,
    TRANGTHAI NVARCHAR(50) DEFAULT N'Chờ trả lời',

    CONSTRAINT FK_HOIDAP_SV FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV),
    CONSTRAINT FK_HOIDAP_TT FOREIGN KEY (MATT) REFERENCES THUTHU(MATT)
);
GO

-- =========================================================
-- 18) BẢNG GÓP Ý (Chức năng Tương tác - Mới)
-- =========================================================
CREATE TABLE GOPY (
    MAGOPY INT IDENTITY(1,1) PRIMARY KEY,
    MASV INT NOT NULL,
    NOIDUNG NVARCHAR(MAX) NOT NULL,
    LOAIGOPY NVARCHAR(50),
    THOIGIANGUI DATETIME DEFAULT GETDATE(),
    TRANGTHAI NVARCHAR(50) DEFAULT N'Mới tiếp nhận',

    CONSTRAINT FK_GOPY_SV FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV)
);
GO

-- =========================================================
-- 19) BẢNG ĐÁNH GIÁ SÁCH 
-- =========================================================
CREATE TABLE DANHGIASACH (
    MADANHGIA INT IDENTITY(1,1) PRIMARY KEY,
    MASACH INT NOT NULL,
    MASV INT NOT NULL,
    DIEM INT CHECK (DIEM >= 1 AND DIEM <= 5),
    NHANXET NVARCHAR(MAX),
    THOIGIAN DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_DGS_SACH FOREIGN KEY (MASACH) REFERENCES SACH(MASACH),
    CONSTRAINT FK_DGS_SV FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV)
);
GO

-- =========================================================
-- 20) BẢNG NHẬT KÝ HOẠT ĐỘNG (Bổ sung do thiếu sót khi merge)
-- =========================================================
CREATE TABLE NHATKYHOATDONG (
    MANHATKY INT IDENTITY(1,1) PRIMARY KEY,
    MATAIKHOAN INT NOT NULL,
    HANHDONG NVARCHAR(255) NOT NULL,
    THOIGIAN DATETIME DEFAULT GETDATE(),
    GHICHU NVARCHAR(MAX),

    CONSTRAINT FK_NK_TK FOREIGN KEY (MATAIKHOAN) REFERENCES TAIKHOAN(MATAIKHOAN)
);
GO

-- =====================================================================================================================
-- ||                                               TRIGGER (HỢP NHẤT)                                                ||
-- =====================================================================================================================

-- 1. CẬP NHẬT SỐ LƯỢNG TỒN KHI NHẬP
GO
CREATE TRIGGER TG_CAPNHATSLTONCUASACH_CTPN
ON CHITIETPHIEUNHAP
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE S
    SET S.SOLUONGTON = ISNULL(S.SOLUONGTON, 0) + ISNULL(I.SL_NHAP, 0) - ISNULL(D.SL_GIAM, 0)
    FROM SACH S
    LEFT JOIN (SELECT MASACH, SUM(ISNULL(SOLUONG, 0)) AS SL_NHAP FROM inserted GROUP BY MASACH) I ON S.MASACH = I.MASACH
    LEFT JOIN (SELECT MASACH, SUM(ISNULL(SOLUONG, 0)) AS SL_GIAM FROM deleted GROUP BY MASACH) D ON S.MASACH = D.MASACH
    WHERE S.MASACH IN (SELECT MASACH FROM inserted UNION SELECT MASACH FROM deleted);
END;
GO

-- 2. CẬP NHẬT SỐ LƯỢNG TỒN KHI MƯỢN
-- Lưu ý: Trigger này sẽ trừ tồn kho ngay khi tạo phiếu (hoặc chi tiết phiếu).
-- Nếu Backend đã trừ rồi thì trigger này sẽ trừ thêm lần nữa.
-- Tuy nhiên để đảm bảo tính toàn vẹn dữ liệu mức DB, ta giữ lại và nên bỏ logic trừ ở Backend.
GO
DROP TRIGGER IF EXISTS TG_CAPNHATSLTONCUASACH_CTPM


-- 3. CẬP NHẬT SỐ LƯỢNG TỒN KHI TRẢ
GO
CREATE TRIGGER TG_CAPNHATSLTONCUASACH_CTPT
ON CHITIETPHIEUTRA
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE S
    SET S.SOLUONGTON = ISNULL(S.SOLUONGTON, 0) + ISNULL(I.SL_TRA, 0) - ISNULL(D.SL_XOA, 0)
    FROM SACH S
    LEFT JOIN (SELECT MASACH, SUM(ISNULL(SOLUONGTRA, 0)) AS SL_TRA FROM inserted GROUP BY MASACH) I ON S.MASACH = I.MASACH
    LEFT JOIN (SELECT MASACH, SUM(ISNULL(SOLUONGTRA, 0)) AS SL_XOA FROM deleted GROUP BY MASACH) D ON S.MASACH = D.MASACH
    WHERE S.MASACH IN (SELECT MASACH FROM inserted UNION SELECT MASACH FROM deleted);
END;
GO

-- 4. CẬP NHẬT TỔNG TIỀN PHIẾU NHẬP
GO
CREATE TRIGGER TG_CAPNHATTONGTIEN_PN
ON CHITIETPHIEUNHAP
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE PN SET PN.TONGTIEN = ISNULL(T.TONG, 0)
    FROM PHIEUNHAP PN
    LEFT JOIN (SELECT MAPN, SUM(ISNULL(THANHTIEN, 0)) AS TONG FROM CHITIETPHIEUNHAP GROUP BY MAPN) T ON PN.MAPN = T.MAPN
    WHERE PN.MAPN IN (SELECT MAPN FROM inserted UNION SELECT MAPN FROM deleted);
END;
GO

-- 5. CẬP NHẬT TRẠNG THÁI PHIẾU MƯỢN KHI TRẢ SÁCH
GO
CREATE TRIGGER TG_CAPNHATTRANGTHAI_PM
ON PHIEUTRA
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE PM
    SET TRANGTHAI = CASE
        WHEN NOT EXISTS (SELECT 1 FROM PHIEUTRA PT WHERE PT.MAPM = PM.MAPM) THEN N'Đang mượn'
        WHEN (SELECT MAX(CTPT.NGAYTRA) FROM CHITIETPHIEUTRA CTPT JOIN PHIEUTRA PT ON CTPT.MAPT = PT.MAPT WHERE PT.MAPM = PM.MAPM) > PM.HANTRA
             AND (SELECT SUM(ISNULL(CTPT.SOLUONGTRA, 0)) FROM CHITIETPHIEUTRA CTPT JOIN PHIEUTRA PT ON CTPT.MAPT = PT.MAPT WHERE PT.MAPM = PM.MAPM) < (SELECT SUM(ISNULL(SOLUONG, 0)) FROM CHITIETPHIEUMUON CTPM WHERE CTPM.MAPM = PM.MAPM)
             THEN N'Quá hạn và Thiếu'
        WHEN (SELECT MAX(CTPT.NGAYTRA) FROM CHITIETPHIEUTRA CTPT JOIN PHIEUTRA PT ON CTPT.MAPT = PT.MAPT WHERE PT.MAPM = PM.MAPM) > PM.HANTRA
             THEN N'Quá hạn'
        WHEN (SELECT SUM(ISNULL(CTPT.SOLUONGTRA, 0)) FROM CHITIETPHIEUTRA CTPT JOIN PHIEUTRA PT ON CTPT.MAPT = PT.MAPT WHERE PT.MAPM = PM.MAPM) < (SELECT SUM(ISNULL(SOLUONG, 0)) FROM CHITIETPHIEUMUON CTPM WHERE CTPM.MAPM = PM.MAPM)
             THEN N'Thiếu'
        ELSE N'Đã trả'
    END
    FROM PHIEUMUON PM
    WHERE PM.MAPM IN (SELECT PT.MAPM FROM PHIEUTRA PT WHERE PT.MAPT IN (SELECT MAPT FROM inserted UNION SELECT MAPT FROM deleted));
END;
GO

-- 6. CẬP NHẬT TIỀN PHẠT
GO
CREATE TRIGGER TG_CAPNHATTIENPHAT_PT
ON CHITIETPHIEUTRA
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE PT
    SET PT.TONGTIENPHAT = ISNULL((
        SELECT SUM(
            CASE 
                WHEN DATEDIFF(DAY, PM.HANTRA, CTPT.NGAYTRA) > 0 THEN
                    CASE 
                        WHEN PM.TRANGTHAI LIKE N'%Quá hạn%' THEN 
                             DATEDIFF(DAY, PM.HANTRA, CTPT.NGAYTRA) * 1000 -- Logic phạt đơn giản: 1000đ/ngày
                        ELSE 0
                    END
                ELSE 0
            END
        )
        FROM CHITIETPHIEUTRA CTPT
        JOIN PHIEUTRA PT2 ON CTPT.MAPT = PT2.MAPT
        JOIN PHIEUMUON PM ON PT2.MAPM = PM.MAPM
        WHERE PT2.MAPT = PT.MAPT
    ), 0)
    FROM PHIEUTRA PT
    WHERE PT.MAPT IN (SELECT MAPT FROM inserted UNION SELECT MAPT FROM deleted);
END;
GO

-- 7. CẬP NHẬT TỔNG TIỀN THANH LÝ (Trigger mới từ nhánh Trong)
GO
CREATE TRIGGER TG_CAPNHATTONGTIEN_TL
ON CHITIETTHANHLY
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE TL SET TL.TONGTIEN = ISNULL(T.TotalThanhtien, 0)
    FROM THANHLY TL
    LEFT JOIN (SELECT MATL, SUM(ISNULL(THANHTIEN, 0)) AS TotalThanhtien FROM CHITIETTHANHLY GROUP BY MATL) T ON TL.MATL = T.MATL
    WHERE TL.MATL IN (SELECT MATL FROM inserted UNION SELECT MATL FROM deleted);
END;
GO

-- 8. CẬP NHẬT TRẠNG THÁI SÁCH (CÒN/HẾT)
GO
CREATE TRIGGER TG_TRANGTHAI_SACH
ON SACH
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE S
    SET TRANGTHAI = CASE WHEN ISNULL(S.SOLUONGTON, 0) > 0 THEN N'Có sẵn' ELSE N'Đã hết' END
    FROM SACH S JOIN inserted I ON S.MASACH = I.MASACH;
END;
GO

-- 9. TRỪ TỒN KHO KHI THANH LÝ (Trigger mới từ nhánh Trong)
GO
CREATE TRIGGER TG_CAPNHATSLTON_THANHLY
ON CHITIETTHANHLY
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- 1. Khi thêm phiếu thanh lý (Trừ tồn kho)
    UPDATE S SET S.SOLUONGTON = S.SOLUONGTON - I.SOLUONG
    FROM SACH S JOIN inserted I ON S.MASACH = I.MASACH;
    -- 2. Khi xóa phiếu thanh lý (Cộng lại tồn kho)
    UPDATE S SET S.SOLUONGTON = S.SOLUONGTON + D.SOLUONG
    FROM SACH S JOIN deleted D ON S.MASACH = D.MASACH;
END;
GO

-- =====================================================================================================================
-- ||                                          DỮ LIỆU MẪU                                                            ||
-- =====================================================================================================================

-- =============================================
-- 1) PHÂN QUYỀN
-- =============================================
INSERT INTO PHANQUYEN (TENQUYEN) VALUES
(N'Admin'),
(N'Thủ Thư'),
(N'Thủ Kho'),
(N'Độc Giả');

-- =============================================
-- 2) TÀI KHOẢN
-- =============================================
INSERT INTO TAIKHOAN (TENDANGNHAP, MATKHAU, MAQUYEN) VALUES
(N'admin01', N'123456', 1),
(N'thuthu01', N'123456', 2),
(N'thukho01', N'123456', 3),
(N'sv01', N'123456', 4),
(N'sv02', N'123456', 4),
(N'sv03', N'123456', 4);

-- =============================================
-- 3) THỦ THƯ
-- =============================================
INSERT INTO THUTHU (MATAIKHOAN, HOVATEN, GIOITINH, NGAYSINH, SDT, EMAIL) VALUES
(2, N'Nguyễn Văn A', N'Nam', '1990-01-01', '0123456789', 'a@gmail.com');

-- =============================================
-- 4) THỦ KHO
-- =============================================
INSERT INTO THUKHO (MATAIKHOAN, HOVATEN, GIOITINH, NGAYSINH, SDT, EMAIL) VALUES
(3, N'Trần Thị B', N'Nữ', '1992-02-02', '0987654321', 'b@gmail.com');

-- =============================================
-- 5) SINH VIÊN
-- =============================================
INSERT INTO SINHVIEN (MATAIKHOAN, HOVATEN, GIOITINH, NGAYSINH, SDT, EMAIL) VALUES
(4, N'Lê Văn C', N'Nam', '2000-03-03', '0912345678', 'c@gmail.com'),
(5, N'Phạm Thị D', N'Nữ', '2001-04-04', '0923456789', 'd@gmail.com'),
(6, N'Hoàng Văn E', N'Nam', '2002-05-05', '0934567890', 'e@gmail.com')

-- =============================================
-- 6) TÁC GIẢ
-- =============================================
INSERT INTO TACGIA (TENTG, QUOCTICH, MOTA) VALUES
(N'J.K. Rowling', N'UK', N'Tác giả Harry Potter'),
(N'George R.R. Martin', N'USA', N'Tác giả Game of Thrones'),
(N'Haruki Murakami', N'Japan', N'Tác giả Kafka on the Shore'),
(N'Agatha Christie', N'UK', N'Tác giả trinh thám'),
(N'J.R.R. Tolkien', N'UK', N'Tác giả Lord of the Rings'),
(N'Nguyen Nhat Anh', N'Vietnam', N'Tác giả tuổi teen'),
(N'Dan Brown', N'USA', N'Tác giả Da Vinci Code'),
(N'Stephen King', N'USA', N'Tác giả kinh dị'),
(N'Paulo Coelho', N'Brazil', N'Tác giả Alchemist'),
(N'Marie Curie', N'France', N'Tác giả khoa học');

-- =============================================
-- 7) NHÀ XUẤT BẢN
-- =============================================
INSERT INTO NHAXUATBAN (TENNXB, DIACHI, SDT) VALUES
(N'NXB Kim Đồng', N'HN', '0241234567'),
(N'NXB Trẻ', N'HCM', '0281234567'),
(N'NXB Giáo Dục', N'HN', '0247654321'),
(N'NXB Văn Học', N'HCM', '0287654321'),
(N'NXB Thế Giới', N'HN', '0241112222'),
(N'NXB Alpha', N'HCM', '0283334444'),
(N'NXB Omega', N'HN', '0245556666'),
(N'NXB Beta', N'HCM', '0287778888'),
(N'NXB Delta', N'HN', '0249990000'),
(N'NXB Gamma', N'HCM', '0280001111');

-- =============================================
-- 8) SÁCH
-- =============================================
INSERT INTO SACH (TENSACH, MATG, MANXB, HINHANH, THELOAI, MOTA, GIAMUON, SOLUONGTON) VALUES
(N'Harry Potter 1', 1, 1, 'hp1.jpg', N'Fantasy', N'Cuốn 1 của Harry Potter', 50000, 5),
(N'Harry Potter 2', 1, 1, 'hp2.jpg', N'Fantasy', N'Cuốn 2 của Harry Potter', 50000, 5),
(N'Game of Thrones 1', 2, 2, 'got1.jpg', N'Fantasy', N'Cuốn 1 Game of Thrones', 60000, 4),
(N'Kafka on the Shore', 3, 3, 'ks.jpg', N'Fiction', N'Tác phẩm Kafka', 40000, 6),
(N'Murder on Orient Express', 4, 4, 'moe.jpg', N'Mystery', N'Trinh thám Agatha', 45000, 3),
(N'Lord of the Rings', 5, 5, 'lotr.jpg', N'Fantasy', N'Triều đại Trung Địa', 70000, 2),
(N'Tôi thấy hoa vàng trên cỏ xanh', 6, 6, 'tvhv.jpg', N'Young Adult', N'Tác giả Việt Nam', 30000, 8),
(N'Da Vinci Code', 7, 7, 'dvc.jpg', N'Mystery', N'Trinh thám', 55000, 7),
(N'The Shining', 8, 8, 'ts.jpg', N'Horror', N'Sách kinh dị', 60000, 5),
(N'Alchemist', 9, 9, 'alc.jpg', N'Fiction', N'Tác phẩm triết học', 50000, 4);

-- =============================================
-- 9) PHIẾU MƯỢN
-- =============================================
INSERT INTO PHIEUMUON (MASV, MATT, NGAYLAPPHIEUMUON, HANTRA) VALUES
(1, 1, '2025-01-01', '2025-01-10'),
(2, 1, '2025-02-01', '2025-02-10'),
(3, 1, '2025-03-01', '2025-03-10'),
(1, 1, '2025-04-01', '2025-04-10'),
(2, 1, '2025-05-01', '2025-05-10');

-- =============================================
-- 10) CHI TIẾT PHIẾU MƯỢN
-- =============================================
INSERT INTO CHITIETPHIEUMUON (MAPM, MASACH, SOLUONG) VALUES
(1, 1, 1),
(1, 2, 1),
(2, 3, 1),
(2, 4, 1),
(3, 5, 1),
(3, 6, 1),
(4, 7, 1),
(4, 8, 1),
(5, 9, 1),
(5, 10, 1);

-- =============================================
-- 11) PHIẾU TRẢ
-- =============================================
INSERT INTO PHIEUTRA (MAPM, MATT, NGAYLAPPHIEUTRA) VALUES
(1, 1, '2025-01-05'),
(2, 1, '2025-02-08'),
(3, 1, '2025-03-15'),
(4, 1, '2025-04-05'),
(5, 1, '2025-05-12');

-- =============================================
-- 12) CHI TIẾT PHIẾU TRẢ
-- =============================================
INSERT INTO CHITIETPHIEUTRA (MAPT, MASACH, SOLUONGTRA, NGAYTRA) VALUES
(1, 1, 1, '2025-01-05'),
(1, 2, 1, '2025-01-05'),
(2, 3, 1, '2025-02-08'),
(2, 4, 1, '2025-02-08'),
(3, 5, 1, '2025-03-15'),
(3, 6, 1, '2025-03-15'),
(4, 7, 1, '2025-04-05'),
(4, 8, 1, '2025-04-05'),
(5, 9, 1, '2025-05-12'),
(5, 10, 1, '2025-05-12');

-- =============================================
-- 13) PHIẾU NHẬP
-- =============================================
INSERT INTO PHIEUNHAP (MATK, NGAYNHAP, TONGTIEN) VALUES
(1, '2025-01-01', 100000),
(1, '2025-02-01', 120000),
(1, '2025-03-01', 150000),
(1, '2025-04-01', 90000),
(1, '2025-05-01', 110000);

-- =============================================
-- 14) CHI TIẾT PHIẾU NHẬP
-- =============================================
INSERT INTO CHITIETPHIEUNHAP (MAPN, MASACH, SOLUONG, GIANHAP) VALUES
(1, 1, 5, 50000),
(1, 2, 5, 50000),
(2, 3, 4, 60000),
(2, 4, 6, 40000),
(3, 5, 3, 45000),
(3, 6, 2, 70000),
(4, 7, 8, 30000),
(4, 8, 7, 55000),
(5, 9, 5, 60000),
(5, 10, 4, 50000);

-- =============================================
-- 15) THANH LÝ
-- =============================================
INSERT INTO THANHLY (MATK, NGAYLAP, TONGTIEN) VALUES
(1, '2025-06-01', 50000),
(1, '2025-06-05', 60000),
(1, '2025-06-10', 70000),
(1, '2025-06-15', 80000),
(1, '2025-06-20', 90000);

-- =============================================
-- 16) CHI TIẾT THANH LÝ
-- =============================================
INSERT INTO CHITIETTHANHLY (MATL, MASACH, SOLUONG, DONGIA) VALUES
(1, 1, 1, 50000),
(2, 2, 1, 60000),
(3, 3, 1, 70000),
(4, 4, 1, 80000),
(5, 5, 1, 90000);


-- =============================================
-- 17) HỎI ĐÁP
-- =============================================
-- Dữ liệu mẫu cho chức năng tương tác
INSERT INTO HOIDAP (MASV, CAUHOI, TRANGTHAI) VALUES
(1, N'Thư viện có mở cửa chủ nhật không?', N'Chờ trả lời'),
(2, N'Làm sao để gia hạn sách online?', N'Chờ trả lời');

-- =============================================
-- 18) GÓP Ý
-- =============================================
INSERT INTO GOPY (MASV, NOIDUNG, LOAIGOPY) VALUES
(1, N'Wifi ở tầng 2 hơi yếu', N'Cơ sở vật chất'),
(3, N'Nên có thêm máy nước nóng lạnh', N'Cơ sở vật chất');

-- =============================================
-- 19) ĐÁNH GIÁ
-- =============================================
INSERT INTO DANHGIASACH (MASACH, MASV, DIEM, NHANXET) VALUES
(1, 1, 5, N'Sách rất hay, bìa đẹp'),
(3, 2, 4, N'Nội dung hấp dẫn nhưng dịch chưa mượt lắm');

-- STORED PROCEDURES HỖ TRỢ
GO
CREATE PROCEDURE SP_NHAP_SACH
    @MaPN VARCHAR(10),
    @MaTK VARCHAR(10),
    @MaSach VARCHAR(10),
    @SoLuong INT,
    @GiaNhap DECIMAL(10,2)
AS
BEGIN
    -- Logic nhập sách (đơn giản hóa cho demo)
    INSERT INTO CHITIETPHIEUNHAP (MAPN, MASACH, SOLUONG, GIANHAP)
    VALUES (CAST(@MaPN AS INT), CAST(@MaSach AS INT), @SoLuong, @GiaNhap);
END;
GO

-- SP: Thêm Tài Khoản và Người Dùng (Admin)
GO
CREATE PROCEDURE SP_ADMIN_THEM_TAIKHOAN
    @TenDangNhap NVARCHAR(50),
    @MatKhau NVARCHAR(255),
    @MaQuyen INT,           -- 1:Admin, 2:Thủ thư, 3:Thủ kho, 4:Độc giả
    @HoVaTen NVARCHAR(100),
    @GioiTinh NVARCHAR(5),
    @NgaySinh DATE,
    @Sdt VARCHAR(15),
    @Email VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @MaTaiKhoan INT;
    
    -- 1. Thêm vào bảng TAIKHOAN
    INSERT INTO TAIKHOAN (TENDANGNHAP, MATKHAU, MAQUYEN)
    VALUES (@TenDangNhap, @MatKhau, @MaQuyen);

    SET @MaTaiKhoan = SCOPE_IDENTITY(); -- Lấy ID vừa tạo

    -- 2. Thêm vào bảng người dùng tương ứng
    IF @MaQuyen = 2 -- Thủ thư
    BEGIN
        INSERT INTO THUTHU (MATAIKHOAN, HOVATEN, GIOITINH, NGAYSINH, SDT, EMAIL)
        VALUES (@MaTaiKhoan, @HoVaTen, @GioiTinh, @NgaySinh, @Sdt, @Email);
    END
    ELSE IF @MaQuyen = 3 -- Thủ kho
    BEGIN
        INSERT INTO THUKHO (MATAIKHOAN, HOVATEN, GIOITINH, NGAYSINH, SDT, EMAIL)
        VALUES (@MaTaiKhoan, @HoVaTen, @GioiTinh, @NgaySinh, @Sdt, @Email);
    END
    ELSE IF @MaQuyen = 4 -- Sinh viên/Độc giả
    BEGIN
        INSERT INTO SINHVIEN (MATAIKHOAN, HOVATEN, GIOITINH, NGAYSINH, SDT, EMAIL)
        VALUES (@MaTaiKhoan, @HoVaTen, @GioiTinh, @NgaySinh, @Sdt, @Email);
    END

    -- Trả về Mã Tài Khoản để xác nhận thành công
    SELECT @MaTaiKhoan AS MaTaiKhoan;
END;
GO

-- SP: Cập nhật Trạng thái Tài khoản
GO
CREATE PROCEDURE SP_ADMIN_CAPNHAT_TRANGTHAI
    @MaTaiKhoan INT,
    @TrangThaiMoi NVARCHAR(20) -- N'Hoạt động' hoặc N'Ngừng hoạt động'
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE TAIKHOAN
    SET TRANGTHAI = @TrangThaiMoi
    WHERE MATAIKHOAN = @MaTaiKhoan;

    IF @@ROWCOUNT > 0
        SELECT 1 AS Success;
    ELSE
        SELECT 0 AS Success;
END;
GO

