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
-- 9) PHIẾU MƯỢN
-- =========================================================
CREATE TABLE PHIEUMUON (
    MAPM INT IDENTITY(1,1) PRIMARY KEY,
    MASV INT NOT NULL,  -- SINH VIÊN MƯỢN
    MATT INT NOT NULL,  -- THỦ THƯ LẬP PHIẾU
    NGAYLAPPHIEUMUON DATE NOT NULL,
    HANTRA DATE NOT NULL,
    TRANGTHAI NVARCHAR(30) NOT NULL DEFAULT N'Đang mượn',

    CONSTRAINT FK_PM_SV FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV),
    CONSTRAINT FK_PM_TT FOREIGN KEY (MATT) REFERENCES THUTHU(MATT),
    CONSTRAINT CK_PM_Ngay CHECK (NGAYLAPPHIEUMUON <= HANTRA),
    CONSTRAINT CK_PM_TRANGTHAI CHECK (TRANGTHAI IN (N'Đang mượn', N'Đã trả', N'Quá hạn', N'Thiếu', N'Quá hạn và Thiếu'))
);
GO

-- =========================================================
-- 10) CHI TIẾT PHIẾU MƯỢN
-- =========================================================
CREATE TABLE CHITIETPHIEUMUON (
    MAPM INT NOT NULL,
    MASACH INT NOT NULL,
    SOLUONG INT DEFAULT 0 CHECK (SOLUONG >= 0),

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
    MAPM INT NOT NULL,   -- Tham chiếu đến phiếu mượn
    MATT INT NOT NULL,   -- Thủ thư ghi nhận phiếu trả
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
-- 13) PHIẾU NHẬP
-- =========================================================
CREATE TABLE PHIEUNHAP (
    MAPN INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    MATK INT NOT NULL, -- Thủ kho lập phiếu
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
-- 15) BẢNG THANH LÝ
-- =========================================================
CREATE TABLE THANHLY (
    MATL INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    MATK INT NOT NULL, -- Thủ kho lập hóa đơn
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
-- 17) BẢNG HỎI ĐÁP
-- =========================================================
CREATE TABLE HOIDAP (
    MAHOIDAP INT IDENTITY(1,1) PRIMARY KEY,
    MASV INT NOT NULL,
    CAUHOI NVARCHAR(500) NOT NULL,
    TRALO NVARCHAR(1000),
    NGAYHOI DATE NOT NULL,
    TRANGTHAI NVARCHAR(30) NOT NULL DEFAULT N'Chờ trả lời' CHECK (TRANGTHAI IN (N'Chờ trả lời', N'Đã trả lời')),

    CONSTRAINT FK_HOIDAP_SV FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV)
);
GO

-- =========================================================
-- 18) BẢNG GÓP Ý
-- =========================================================
CREATE TABLE GOPY (
    MAGOPY INT IDENTITY(1,1) PRIMARY KEY,
    MASV INT NOT NULL,
    NOIDUNG NVARCHAR(1000) NOT NULL,
    NGAYGOPY DATE NOT NULL,
    TRANGTHAI NVARCHAR(30) NOT NULL DEFAULT N'Chưa xử lý' CHECK (TRANGTHAI IN (N'Chưa xử lý', N'Đã xử lý')),

    CONSTRAINT FK_GOPY_SV FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV)
);
GO

-- =========================================================
-- 19) BẢNG ĐÁNH GIÁ SÁCH
-- =========================================================
CREATE TABLE DANHGIASACH (
    MADANHGIA INT IDENTITY(1,1) PRIMARY KEY,
    MASV INT NOT NULL,
    MASACH INT NOT NULL,
    DIEM INT NOT NULL CHECK (DIEM >= 1 AND DIEM <= 5),
    BINHLUAN NVARCHAR(500),
    NGAYDANHGIA DATE NOT NULL,

    CONSTRAINT FK_DANHGIASACH_SV FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV),
    CONSTRAINT FK_DANHGIASACH_SACH FOREIGN KEY (MASACH) REFERENCES SACH(MASACH)
);
GO


-- =========================================================

-- =====================================================================================================================
-- ||                                               TRIGGER                                                           ||
-- =====================================================================================================================

-- ===============================================================
-- 1. CẬP NHẬT SỐ LƯỢNG TỒN CỦA SÁCH KHI NHẬP (PHIẾU NHẬP)
-- ===============================================================
DROP TRIGGER IF EXISTS TG_CAPNHATSLTONCUASACH_CTPN;
GO
CREATE TRIGGER TG_CAPNHATSLTONCUASACH_CTPN
ON CHITIETPHIEUNHAP
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE S
    SET S.SOLUONGTON =
        ISNULL(S.SOLUONGTON, 0)
        + ISNULL(I.SL_NHAP, 0)
        - ISNULL(D.SL_GIAM, 0)
    FROM SACH S
    LEFT JOIN (
        SELECT MASACH, SUM(ISNULL(SOLUONG, 0)) AS SL_NHAP
        FROM inserted GROUP BY MASACH
    ) I ON S.MASACH = I.MASACH
    LEFT JOIN (
        SELECT MASACH, SUM(ISNULL(SOLUONG, 0)) AS SL_GIAM
        FROM deleted GROUP BY MASACH
    ) D ON S.MASACH = D.MASACH
    WHERE S.MASACH IN (
        SELECT MASACH FROM inserted
        UNION
        SELECT MASACH FROM deleted
    );
END;
GO

-- ===============================================================
-- 2. CẬP NHẬT SỐ LƯỢNG TỒN CỦA SÁCH KHI MƯỢN (PHIẾU MƯỢN)
-- ===============================================================
DROP TRIGGER IF EXISTS TG_CAPNHATSLTONCUASACH_CTPM;
GO
CREATE TRIGGER TG_CAPNHATSLTONCUASACH_CTPM
ON CHITIETPHIEUMUON
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra không mượn vượt số lượng tồn
    IF EXISTS (
        SELECT 1
        FROM inserted I
        JOIN SACH S ON I.MASACH = S.MASACH
        WHERE ISNULL(I.SOLUONG, 0) > ISNULL(S.SOLUONGTON, 0)
    )
    BEGIN
        RAISERROR (N'Số lượng mượn vượt quá tồn kho!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Cập nhật tồn kho
    UPDATE S
    SET S.SOLUONGTON =
        ISNULL(S.SOLUONGTON, 0)
        - ISNULL(I.SL_MUON, 0)
        + ISNULL(D.SL_TRA, 0)
    FROM SACH S
    LEFT JOIN (
        SELECT MASACH, SUM(ISNULL(SOLUONG, 0)) AS SL_MUON
        FROM inserted GROUP BY MASACH
    ) I ON S.MASACH = I.MASACH
    LEFT JOIN (
        SELECT MASACH, SUM(ISNULL(SOLUONG, 0)) AS SL_TRA
        FROM deleted GROUP BY MASACH
    ) D ON S.MASACH = D.MASACH
    WHERE S.MASACH IN (
        SELECT MASACH FROM inserted
        UNION
        SELECT MASACH FROM deleted
    );
END;
GO

-- ===============================================================
-- 3. CẬP NHẬT SỐ LƯỢNG TỒN CỦA SÁCH KHI TRẢ
-- ===============================================================
DROP TRIGGER IF EXISTS TG_CAPNHATSLTONCUASACH_CTPT;
GO
CREATE TRIGGER TG_CAPNHATSLTONCUASACH_CTPT
ON CHITIETPHIEUTRA
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE S
    SET S.SOLUONGTON =
        ISNULL(S.SOLUONGTON, 0)
        + ISNULL(I.SL_TRA, 0)
        - ISNULL(D.SL_XOA, 0)
    FROM SACH S
    LEFT JOIN (
        SELECT MASACH, SUM(ISNULL(SOLUONGTRA, 0)) AS SL_TRA
        FROM inserted GROUP BY MASACH
    ) I ON S.MASACH = I.MASACH
    LEFT JOIN (
        SELECT MASACH, SUM(ISNULL(SOLUONGTRA, 0)) AS SL_XOA
        FROM deleted GROUP BY MASACH
    ) D ON S.MASACH = D.MASACH
    WHERE S.MASACH IN (
        SELECT MASACH FROM inserted
        UNION
        SELECT MASACH FROM deleted
    );
END;
GO

-- ===============================================================
-- 4. CẬP NHẬT TỔNG TIỀN CỦA PHIẾU NHẬP
-- ===============================================================
DROP TRIGGER IF EXISTS TG_CAPNHATTONGTIEN_PN;
GO
CREATE TRIGGER TG_CAPNHATTONGTIEN_PN
ON CHITIETPHIEUNHAP
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE PN
    SET PN.TONGTIEN = ISNULL(T.TONG, 0)
    FROM PHIEUNHAP PN
    LEFT JOIN (
        SELECT MAPN, SUM(ISNULL(THANHTIEN, 0)) AS TONG
        FROM CHITIETPHIEUNHAP
        GROUP BY MAPN
    ) T ON PN.MAPN = T.MAPN
    WHERE PN.MAPN IN (
        SELECT MAPN FROM inserted
        UNION
        SELECT MAPN FROM deleted
    );
END;
GO

-- ===============================================================
-- 5. CẬP NHẬT TRẠNG THÁI PHIẾU MƯỢN
-- ===============================================================
DROP TRIGGER IF EXISTS TG_CAPNHATTRANGTHAI_PM;
GO
CREATE TRIGGER TG_CAPNHATTRANGTHAI_PM
ON PHIEUTRA
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE PM
    SET TRANGTHAI = CASE
        WHEN NOT EXISTS (SELECT 1 FROM PHIEUTRA PT WHERE PT.MAPM = PM.MAPM)
            THEN N'Đang mượn'
        WHEN (
            SELECT MAX(CTPT.NGAYTRA)
            FROM CHITIETPHIEUTRA CTPT 
            JOIN PHIEUTRA PT ON CTPT.MAPT = PT.MAPT
            WHERE PT.MAPM = PM.MAPM
        ) > PM.HANTRA
        AND (
            SELECT SUM(ISNULL(CTPT.SOLUONGTRA, 0))
            FROM CHITIETPHIEUTRA CTPT 
            JOIN PHIEUTRA PT ON CTPT.MAPT = PT.MAPT
            WHERE PT.MAPM = PM.MAPM
        ) < (
            SELECT SUM(ISNULL(SOLUONG, 0))
            FROM CHITIETPHIEUMUON CTPM
            WHERE CTPM.MAPM = PM.MAPM
        )
            THEN N'Quá hạn và Thiếu'
        WHEN (
            SELECT MAX(CTPT.NGAYTRA)
            FROM CHITIETPHIEUTRA CTPT 
            JOIN PHIEUTRA PT ON CTPT.MAPT = PT.MAPT
            WHERE PT.MAPM = PM.MAPM
        ) > PM.HANTRA
            THEN N'Quá hạn'
        WHEN (
            SELECT SUM(ISNULL(CTPT.SOLUONGTRA, 0))
            FROM CHITIETPHIEUTRA CTPT 
            JOIN PHIEUTRA PT ON CTPT.MAPT = PT.MAPT
            WHERE PT.MAPM = PM.MAPM
        ) < (
            SELECT SUM(ISNULL(SOLUONG, 0))
            FROM CHITIETPHIEUMUON CTPM
            WHERE CTPM.MAPM = PM.MAPM
        )
            THEN N'Thiếu'
        ELSE N'Đã trả'
    END
    FROM PHIEUMUON PM
    WHERE PM.MAPM IN (
        SELECT PT.MAPM
        FROM PHIEUTRA PT
        WHERE PT.MAPT IN (
            SELECT MAPT FROM inserted
            UNION
            SELECT MAPT FROM deleted
        )
    );
END;
GO

-- ===============================================================
-- 6. CẬP NHẬT TIỀN PHẠT PHIẾU TRẢ
-- ===============================================================
DROP TRIGGER IF EXISTS TG_CAPNHATTIENPHAT_PT;
GO
CREATE TRIGGER TG_CAPNHATTIENPHAT_PT
ON CHITIETPHIEUTRA
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE PT
    SET PT.TONGTIENPHAT =
        ISNULL((
            SELECT SUM(
                CASE 
                    WHEN DATEDIFF(DAY, PM.HANTRA, CTPT.NGAYTRA) > 0 THEN
                        CASE 
                            WHEN PM.TRANGTHAI = N'Quá hạn và Thiếu' THEN
                                CASE 
                                    WHEN DATEDIFF(DAY, PM.HANTRA, CTPT.NGAYTRA) <= 7 
                                        THEN DATEDIFF(DAY, PM.HANTRA, CTPT.NGAYTRA) * 0.02 * ISNULL(S.GIAMUON, 0)
                                    ELSE 1.5 * ISNULL(S.GIAMUON, 0)
                                END
                            WHEN PM.TRANGTHAI = N'Quá hạn' THEN 1500
                            ELSE 0
                        END
                    ELSE 0
                END
            )
            FROM CHITIETPHIEUTRA CTPT
            JOIN PHIEUTRA PT2 ON CTPT.MAPT = PT2.MAPT
            JOIN PHIEUMUON PM ON PT2.MAPM = PM.MAPM
            JOIN SACH S ON CTPT.MASACH = S.MASACH
            WHERE PT2.MAPT = PT.MAPT
        ), 0)
    FROM PHIEUTRA PT
    WHERE PT.MAPT IN (
        SELECT MAPT FROM inserted
        UNION
        SELECT MAPT FROM deleted
    );
END;
GO

-- ===============================================================
-- 7. CẬP NHẬT TỔNG TIỀN THANH LÝ
-- ===============================================================
DROP TRIGGER IF EXISTS TG_CAPNHATTONGTIEN_TL;
GO
CREATE TRIGGER TG_CAPNHATTONGTIEN_TL
ON CHITIETTHANHLY
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE TL
    SET TL.TONGTIEN = ISNULL(T.TotalThanhtien, 0)
    FROM THANHLY TL
    LEFT JOIN (
        SELECT MATL, SUM(ISNULL(THANHTIEN, 0)) AS TotalThanhtien
        FROM CHITIETTHANHLY
        GROUP BY MATL
    ) T ON TL.MATL = T.MATL
    WHERE TL.MATL IN (
        SELECT MATL FROM inserted
        UNION
        SELECT MATL FROM deleted
    );
END;
GO

-- ===============================================================
-- 8. CẬP NHẬT TRẠNG THÁI SÁCH
-- ===============================================================
DROP TRIGGER IF EXISTS TG_TRANGTHAI_SACH;
GO
CREATE TRIGGER TG_TRANGTHAI_SACH
ON SACH
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE S
    SET TRANGTHAI = 
        CASE WHEN ISNULL(S.SOLUONGTON, 0) > 0 THEN N'Có sẵn'
             ELSE N'Đã hết'
        END
    FROM SACH S
    JOIN inserted I ON S.MASACH = I.MASACH;
END;
GO

-- =====================================================================================================================
-- ||                                          THÊM NỘI DUNG DỮ LIỆU                                                  ||
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
INSERT INTO HOIDAP (MASV, CAUHOI, TRALO, NGAYHOI, TRANGTHAI) VALUES
(1, N'Thư viện có mở cửa vào cuối tuần không?', N'Thư viện mở cửa từ thứ 2 đến chủ nhật, 8h sáng đến 5h chiều', '2025-01-15', N'Đã trả lời'),
(2, N'Làm thế nào để gia hạn sách?', N'Bạn có thể gia hạn sách qua website hoặc liên hệ trực tiếp thủ thư', '2025-02-10', N'Đã trả lời'),
(3, N'Số lượng sách tối đa được mượn một lần là bao nhiêu?', NULL, '2025-03-20', N'Chờ trả lời'),
(1, N'Có dịch vụ photo tài liệu không?', N'Có, thư viện có dịch vụ photo với giá 500đ/trang', '2025-04-05', N'Đã trả lời'),
(2, N'Làm sao để tìm sách theo chủ đề?', NULL, '2025-05-12', N'Chờ trả lời');

-- =============================================
-- 18) GÓP Ý
-- =============================================
INSERT INTO GOPY (MASV, NOIDUNG, NGAYGOPY, TRANGTHAI) VALUES
(1, N'Nên mở rộng giờ làm việc của thư viện đến 8h tối', '2025-01-20', N'Đã xử lý'),
(2, N'Bổ sung thêm sách về công nghệ thông tin', '2025-02-15', N'Chưa xử lý'),
(3, N'Cần cải thiện hệ thống tìm kiếm sách', '2025-03-10', N'Đã xử lý'),
(1, N'Thêm khu vực học nhóm yên tĩnh', '2025-04-08', N'Chưa xử lý'),
(2, N'Cập nhật thêm sách mới về kinh tế', '2025-05-15', N'Chưa xử lý');

-- =============================================
-- 19) ĐÁNH GIÁ SÁCH
-- =============================================
INSERT INTO DANHGIASACH (MASV, MASACH, DIEM, BINHLUAN, NGAYDANHGIA) VALUES
(1, 1, 5, N'Cuốn sách rất hay và hấp dẫn', '2025-01-12'),
(2, 3, 4, N'Nội dung tốt nhưng hơi dài', '2025-02-18'),
(3, 5, 5, N'Trinh thám kịch tính, không thể bỏ xuống', '2025-03-22'),
(1, 7, 4, N'Câu chuyện cảm động về tuổi thơ', '2025-04-10'),
(2, 9, 3, N'Hơi kinh dị nhưng viết hay', '2025-05-18'),
(3, 2, 5, N'Phần 2 hay hơn phần 1', '2025-05-25'),
(1, 4, 4, N'Văn phong độc đáo của Murakami', '2025-06-01');


-- =====================================================================================================================
-- ||                                          CẬP NHẬT DỮ LIỆU ĐỘNG                                                  ||
-- =====================================================================================================================


-- =====================================================================================================================
-- ||                                          PROCEDURE                                                              ||
-- =====================================================================================================================
    --  Xem thông tin đăng nhập
GO
    CREATE PROC SP_XEMTT_DANGNHAP AS
        BEGIN
            SELECT MATT AS MATAIKHOAN,EMAIL,MATKHAU FROM THUTHU
                                    UNION
                                    SELECT MATK,EMAIL,MATKHAU FROM THUKHO
                                    UNION
                                    SELECT MASV,EMAIL,MATKHAU FROM SINHVIEN
        end
GO
EXEC SP_XEMTT_DANGNHAP

    -- ADMIN
    -- 1.Quản lý thông tin user truy cập (mức view) : Thủ Thư , Thủ Kho ,Sinh Viên--> TẠO TÀI KHOẢN
    --1 --> DỰA THEO VAI TRÒ (INPUT) TẠO MÃ TÀI KHOẢN VD : TTxxx , TKxxx ,SVxxx
GO
    CREATE PROC SP_PHATSINH_MATAIKHOAN_TAM @VAITRO NVARCHAR(30) , @MATK VARCHAR(10) OUTPUT AS
        BEGIN
            DECLARE @MA_2KYTU VARCHAR(5)							   
            DECLARE @SO_SAUKYTU VARCHAR(8)
            DECLARE @MATK_TAM VARCHAR(10)
            SET @MA_2KYTU = CASE
                WHEN @VAITRO=N'Thủ Thư' THEN 'TT'
                WHEN @VAITRO=N'Thủ Kho' THEN 'TK'
                ELSE 'SV'
                END
            WHILE 1=1
                ---->KIỂM TRA MÃ TÀI KHOẢN KHÔNG TRÙNG ( TỈ LỆ 1: 100.000.000 RẤT HIẾM NHƯNG KO CÓ NGHĨA KO TRÙNG)
                BEGIN
                    SET @SO_SAUKYTU =CAST( ABS(CHECKSUM(NEWID())) % 100000000 AS VARCHAR(8))
                    SET @MATK_TAM = @MA_2KYTU + @SO_SAUKYTU
                    IF NOT EXISTS(SELECT 1 FROM
                                 (
                                    SELECT MATT AS MADANGNHAP,EMAIL,MATKHAU FROM THUTHU
                                    UNION
                                    SELECT MATK,EMAIL,MATKHAU FROM THUKHO
                                    UNION
                                    SELECT MASV,EMAIL,MATKHAU FROM SINHVIEN
                                 ) AS THONGTINDANGNHAP WHERE THONGTINDANGNHAP.MADANGNHAP=@MATK_TAM
                               )
                        BEGIN
                            SET @MATK=@MATK_TAM
                            BREAK
                        end
                end
        end
GO
--thử dữ liệu
DECLARE @MATK VARCHAR(15);
EXEC SP_PHATSINH_MATAIKHOAN_TAM N'Thủ Thư', @MATK OUTPUT;
SELECT @MATK AS MaDangNhap;


    -- 2--> PHÁT SINH MẬT KHẨU TỰ ĐỘNG (8 CHỮ SỐ NGẪU NHIÊN ĐẢM BẢO KHÔNG TRÙNG)
GO
    CREATE PROC SP_PHATSINHMATKHAU @MATKHAU NVARCHAR(20) OUTPUT AS
        BEGIN
            DECLARE @DUYET NVARCHAR(20)
            WHILE 1=1
            BEGIN
                SET @DUYET = CAST( ABS(CHECKSUM(NEWID())) % 100000000 AS VARCHAR(8))
                -- CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR(10))
                IF NOT EXISTS(SELECT 1 FROM
                                   (
                                    SELECT MATT AS MADANGNHAP,EMAIL,MATKHAU FROM THUTHU
                                    UNION
                                    SELECT MATK,EMAIL,MATKHAU FROM THUKHO
                                    UNION
                                    SELECT MASV,EMAIL,MATKHAU FROM SINHVIEN
                                   ) AS THONGTINDANGNHAP WHERE THONGTINDANGNHAP.MATKHAU=@MATKHAU
                             )
                BEGIN
                    SET @MATKHAU=@DUYET
                    BREAK
                end
            end
        end
GO
--thử dữ liệu
DECLARE @MK NVARCHAR(20)
EXEC SP_PHATSINHMATKHAU @MK OUTPUT
SELECT @MK AS MK

    -- 3 --> THÊM TÀI KHOẢN
GO
    CREATE PROC SP_THEMTAIKHOAN  @HOTEN NVARCHAR(30), @GIOITINH NVARCHAR(10) ,@NGSINH DATE,@SDT VARCHAR(15), @VAITRO NVARCHAR(20) AS
        BEGIN
            DECLARE @BANG VARCHAR(50)
            DECLARE @EMAIL VARCHAR(50)
            DECLARE @MATK VARCHAR(10)
            DECLARE @MATKHAU NVARCHAR(20)
            EXEC SP_PHATSINHMATKHAU @MATKHAU OUTPUT
            EXEC SP_PHATSINH_MATAIKHOAN_TAM @VAITRO,@MATK OUTPUT
            SET @BANG = CASE
                WHEN SUBSTRING(@MATK,1,2) ='TT' THEN 'THUTHU'
                WHEN SUBSTRING(@MATK ,1,2) ='TK' THEN 'THUKHO'
                ELSE  'SINHVIEN'
                END
            SET @EMAIL = LOWER(REPLACE(@HOTEN, ' ', '') + '.' + @MATK + '@unilib.edu.vn')

            IF @BANG = 'THUTHU'
                BEGIN
                    INSERT INTO THUTHU VALUES
                    (@MATK,@HOTEN,@GIOITINH,@NGSINH,@SDT,@EMAIL,@MATKHAU)
                end
            ELSE IF @BANG='THUKHO'
                BEGIN
                    INSERT INTO THUKHO VALUES
                    (@MATK,@HOTEN,@GIOITINH,@NGSINH,@SDT,@EMAIL,@MATKHAU)
                end
            ELSE
                BEGIN
                    INSERT INTO SINHVIEN VALUES
                    (@MATK,@HOTEN,@GIOITINH,@NGSINH,@SDT,@EMAIL,@MATKHAU)
                end
        end
GO
EXEC SP_THEMTAIKHOAN N'VU DUY HUNG',N'Nam','2005-10-10','020202020',N'Thủ Kho'

    ---------------- THỦ THƯ -----------------------
    ---------------- THỦ KHO -----------------------
-- 1. Thủ kho nhập sách mới: tự động cập nhật tồn kho và tổng tiền phiếu nhập
GO
	CREATE PROCEDURE SP_NHAP_SACH
		@MaPN VARCHAR(10),
		@MaTK VARCHAR(10),
		@MaSach VARCHAR(10),
		@SoLuong INT,
		@GiaNhap DECIMAL(10,2)
	AS
	BEGIN
		
		IF NOT EXISTS(SELECT 1 FROM dbo.PHIEUNHAP WHERE MAPN=@MaPN)
		BEGIN		
		    INSERT INTO PHIEUNHAP (MAPN, MATK, NGAYNHAP) VALUES
             (@MaPN,@MaTK,GETDATE())
		END
		--

		INSERT INTO CHITIETPHIEUNHAP (MAPN, MASACH, SOLUONG, GIANHAP)
		VALUES (@MaPN, @MaSach, @SoLuong, @GiaNhap);
	END;
GO
-- THU DU LIEU :
EXEC dbo.SP_NHAP_SACH @MaPN = 'PN11',     -- varchar(10)
                      @MaTK = 'TK01',     -- varchar(10)
                      @MaSach = 'S01',   -- varchar(10)
                      @SoLuong = 10,   -- int
                      @GiaNhap = 22000 -- decimal(10, 2)

-- 2. sinh viên mượn sách <--> thủ thư tạo Phiếu Mượn sách tương ứng với Sinh Viên , sau đó sinh viên hoàn thiện thông tin Chi Tiết Phiếu Mượn
GO
	CREATE PROC SP_TRAN_MUONSACH 
		@MAPM VARCHAR(10),
		@MATT VARCHAR(10),
		@MASV VARCHAR(10),
		@MASACH VARCHAR(10),
		@NGAYLAP DATE ,
		@HANTRA DATE,
		@SL INT
	AS
	BEGIN
		BEGIN  TRY
			BEGIN TRANSACTION 
			-- tạo phiếu mượn nếu chưa có
			IF NOT EXISTS(SELECT 1 FROM dbo.PHIEUMUON WHERE MAPM=@MAPM)
			BEGIN
				INSERT INTO PHIEUMUON (MAPM,MASV,MATT,NGAYLAPPHIEUMUON,HANTRA) VALUES
				(@MAPM,@MASV,@MATT,@NGAYLAP,@HANTRA)
			END
			-- điền thông tin phiếu mượn
			INSERT INTO CHITIETPHIEUMUON VALUES
			(@MAPM,@MASACH,@SL)
			-- phiên thành công
			COMMIT TRAN
		END	TRY
		BEGIN CATCH
			ROLLBACK TRAN
			PRINT 'PHIÊN MƯỢN SÁCH BỊ HỦY !!!'
		END CATCH
	END
GO

-- 3. SINH VIÊN trả sách <--> THỦ THƯ tạo phiếu trả tương ứng với PHIẾU MƯỢN , sau đó SINH VIÊN hoàn thiện (chi tiết) phiếu trả tương ứng




-- =====================================================================================================================
-- ||                                          FUNCTION                                                               ||
-- =====================================================================================================================





-- =====================================================================================================================
-- ||                                          CURSOR                                                                 ||
-- =====================================================================================================================

-- =====================================================================================================================
-- ||                                          TRANSACTION                                                            ||
-- =====================================================================================================================

-- =====================================================================================================================
-- ||                                          CÁC TRUY VẤN THUẦN                                                     ||
-- =====================================================================================================================

SELECT * FROM THUKHO
SELECT * FROM SINHVIEN
SELECT * FROM TACGIA
SELECT * FROM NHAXUATBAN
SELECT * FROM SACH
SELECT * FROM PHIEUNHAP
SELECT * FROM CHITIETPHIEUNHAP
SELECT * FROM PHIEUMUON
SELECT * FROM CHITIETPHIEUMUON
SELECT * FROM PHIEUTRA
SELECT * FROM CHITIETPHIEUTRA
SELECT * FROM THANHLY
SELECT * FROM CHITIETTHANHLY
SELECT * FROM HOIDAP
SELECT * FROM GOPY
SELECT * FROM DANHGIASACH


SELECT dbo.PHIEUMUON.MAPM,dbo.PHIEUTRA.MAPT,HANTRA,NGAYTRA
FROM dbo.PHIEUMUON JOIN dbo.PHIEUTRA ON PHIEUTRA.MAPM = PHIEUMUON.MAPM
JOIN dbo.CHITIETPHIEUTRA ON CHITIETPHIEUTRA.MAPT = PHIEUTRA.MAPT