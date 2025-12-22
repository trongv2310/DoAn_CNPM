    using Microsoft.AspNetCore.Mvc;
    using Microsoft.EntityFrameworkCore;
    using API_ThuVien.Models;
    using API_ThuVien.DTO;
    using System.Linq;
    using System.Threading.Tasks;
    using System;
    using System.Collections.Generic;

    namespace API_ThuVien.Controllers
    {
        [Route("api/[controller]")]
        [ApiController]
        public class PhieuMuonController : ControllerBase
        {
            private readonly ThuVienDbContext _context;

            public PhieuMuonController(ThuVienDbContext context)
            {
                _context = context;
            }

            // --- ENDPOINT 1: Độc giả gửi yêu cầu mượn ---
            [HttpPost]
            public async Task<IActionResult> CreateBorrowRequest([FromBody] BorrowRequestDto request)
            {
                if (request == null || request.SachMuon == null || !request.SachMuon.Any())
                    return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ." });

                DateOnly ngayHienTai = DateOnly.FromDateTime(DateTime.Now);
                DateOnly hanTra = DateOnly.FromDateTime(request.NgayHenTra);

                if (hanTra <= ngayHienTai)
                    return BadRequest(new { success = false, message = "Ngày hẹn trả phải sau ngày hôm nay." });

                // 1. Kiểm tra thông tin sinh viên
                var sinhVien = await _context.Sinhviens.FirstOrDefaultAsync(sv => sv.Mataikhoan == request.MaTaiKhoan);
                if (sinhVien == null) return NotFound(new { success = false, message = "Không tìm thấy thông tin sinh viên." });

                // -----------------------------------------------------------------------------
                // [SỬA ĐỔI LOGIC CHẶN MƯỢN]
                // -----------------------------------------------------------------------------

                // XÓA: Không chặn dựa trên tiền phạt cũ (coTienPhatChuaDong) nữa theo yêu cầu của bạn.
                // Nếu họ đã trả sách rồi thì cho phép mượn tiếp (dù còn nợ).

                // THÊM: Chặn nếu ĐANG GIỮ sách quá hạn (Chưa trả)
                bool dangGiuSachQuaHan = await _context.Phieumuons
                    .Include(pm => pm.Chitietphieumuons)
                    .AnyAsync(pm => pm.Masv == sinhVien.Masv
                                    // Phiếu chưa kết thúc
                                    && pm.Trangthai != "Đã trả"
                                    && pm.Trangthai != "Chờ duyệt"
                                    && pm.Trangthai != "Từ chối"
                                    // Và đã quá hạn (Tính theo hạn trả của từng cuốn trong chi tiết hoặc của phiếu)
                                    && (pm.Hantra < ngayHienTai || pm.Chitietphieumuons.Any(ct => ct.Hantra < ngayHienTai)));

                if (dangGiuSachQuaHan)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Bạn đang giữ sách quá hạn! Vui lòng trả sách và thanh toán phạt trước khi mượn mới."
                    });
                }
                // -----------------------------------------------------------------------------

                using (var transaction = await _context.Database.BeginTransactionAsync())
                {
                    try
                    {
                        var defaultThuThu = await _context.Thuthus.FirstOrDefaultAsync();
                        int firstMapm = 0;

                        foreach (var item in request.SachMuon)
                        {
                            var sach = await _context.Saches.FindAsync(item.MaSach);
                            if (sach == null) throw new Exception($"Sách ID {item.MaSach} không tồn tại.");
                            if (sach.Soluongton < item.SoLuong)
                                throw new Exception($"Sách '{sach.Tensach}' hiện không đủ số lượng (Còn: {sach.Soluongton}).");

                            var newPhieuMuon = new Phieumuon
                            {
                                Masv = sinhVien.Masv,
                                Matt = defaultThuThu?.Matt ?? 1,
                                Ngaylapphieumuon = ngayHienTai,
                                Hantra = hanTra,
                                Trangthai = "Chờ duyệt",
                                Solangiahan = 0
                            };

                            _context.Phieumuons.Add(newPhieuMuon);
                            await _context.SaveChangesAsync();

                            if (firstMapm == 0) firstMapm = newPhieuMuon.Mapm;

                            var chiTiet = new Chitietphieumuon
                            {
                                Mapm = newPhieuMuon.Mapm,
                                Masach = item.MaSach,
                                Soluong = item.SoLuong,
                                Hantra = hanTra,
                                Solangiahan = 0
                            };
                            _context.Chitietphieumuons.Add(chiTiet);
                        }

                        await _context.SaveChangesAsync();
                        await transaction.CommitAsync();

                        return Ok(new { success = true, message = "Gửi yêu cầu thành công!", maPhieuMuon = firstMapm });
                    }
                    catch (Exception ex)
                    {
                        await transaction.RollbackAsync();
                        return BadRequest(new { success = false, message = ex.Message });
                    }
                }
            }

            // --- CÁC API KHÁC GIỮ NGUYÊN ---
            // (Approve, Pending, History, ThanhToanPhat, Extend, ResetDemo...)
            // Bạn copy lại y nguyên các hàm dưới đây từ code cũ của bạn

            [HttpPost("approve/{mapm}")]
            public async Task<IActionResult> ApproveBorrowRequest(int mapm, [FromQuery] int maThuThuDuyet)
            {
                using (var transaction = await _context.Database.BeginTransactionAsync())
                {
                    try
                    {
                        var phieuMuon = await _context.Phieumuons
                                                .Include(pm => pm.Chitietphieumuons)
                                                .FirstOrDefaultAsync(p => p.Mapm == mapm);

                        if (phieuMuon == null) return NotFound(new { message = "Không tìm thấy phiếu mượn." });
                        if (phieuMuon.Trangthai != "Chờ duyệt") return BadRequest(new { message = "Phiếu này không ở trạng thái chờ duyệt." });

                        foreach (var ct in phieuMuon.Chitietphieumuons)
                        {
                            var sach = await _context.Saches.FindAsync(ct.Masach);
                            if (sach == null) throw new Exception($"Sách ID {ct.Masach} bị lỗi dữ liệu.");
                            if (sach.Soluongton < ct.Soluong) throw new Exception($"Sách '{sach.Tensach}' đã hết hàng trong kho.");

                            sach.Soluongton -= (ct.Soluong ?? 0);
                            _context.Saches.Update(sach);
                        }

                        phieuMuon.Trangthai = "Đang mượn";
                        phieuMuon.Matt = maThuThuDuyet;

                        await _context.SaveChangesAsync();
                        await transaction.CommitAsync();
                        return Ok(new { message = "Duyệt phiếu thành công (Đã trừ tồn kho)." });
                    }
                    catch (Exception ex)
                    {
                        await transaction.RollbackAsync();
                        return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
                    }
                }
            }

            [HttpGet("pending")]
            public async Task<IActionResult> GetPendingRequests()
            {
                var list = await _context.Phieumuons
                    .Include(p => p.MasvNavigation)
                    .Include(p => p.Chitietphieumuons).ThenInclude(ct => ct.MasachNavigation)
                    .Where(p => p.Trangthai == "Chờ duyệt")
                    .OrderBy(p => p.Ngaylapphieumuon)
                    .Select(p => new
                    {
                        MaPhieu = p.Mapm,
                        TenSinhVien = p.MasvNavigation.Hovaten,
                        NgayMuon = p.Ngaylapphieumuon.ToString("dd/MM/yyyy"),
                        HanTra = p.Hantra.ToString("dd/MM/yyyy"),
                        SachMuon = p.Chitietphieumuons.Select(ct => new { TenSach = ct.MasachNavigation.Tensach, SoLuong = ct.Soluong }).ToList()
                    }).ToListAsync();
                return Ok(list);
            }

            [HttpGet("History/{maTaiKhoan}")]
            public async Task<IActionResult> GetLichSuMuon(int maTaiKhoan)
            {
                var sv = await _context.Sinhviens.FirstOrDefaultAsync(s => s.Mataikhoan == maTaiKhoan);
                if (sv == null) return NotFound("Không tìm thấy sinh viên");

                var listPhieuMuon = await _context.Phieumuons
                    .Include(pm => pm.Chitietphieumuons).ThenInclude(ct => ct.MasachNavigation)
                    .Where(pm => pm.Masv == sv.Masv).OrderByDescending(pm => pm.Ngaylapphieumuon).ToListAsync();

                var listPhieuTra = await _context.Phieutras
                    .Include(pt => pt.Chitietphieutras)
                    .Where(pt => listPhieuMuon.Select(pm => pm.Mapm).Contains(pt.Mapm)).ToListAsync();

                var result = new List<LichSuMuonDto>();
                var today = DateOnly.FromDateTime(DateTime.Now);

                foreach (var pm in listPhieuMuon)
                {
                    foreach (var ctMuon in pm.Chitietphieumuons)
                    {
                        string statusHienThi = pm.Trangthai;
                        double tienPhatSach = 0;
                        string trangThaiThanhToan = "Hoàn thành";
                        DateOnly hanTraSach = ctMuon.Hantra ?? pm.Hantra;

                        // ... (Giữ nguyên logic kiểm tra trả sách/quá hạn cũ) ...
                        var chiTietTra = listPhieuTra
                            .Where(pt => pt.Mapm == pm.Mapm)
                            .SelectMany(pt => pt.Chitietphieutras)
                            .FirstOrDefault(ctTra => ctTra.Masach == ctMuon.Masach);

                        if (chiTietTra != null) // Đã trả
                        {
                            statusHienThi = "Đã trả";
                            var ptChuaSach = listPhieuTra.First(pt => pt.Chitietphieutras.Any(x => x.Masach == ctMuon.Masach));
                            if (ptChuaSach.Tongtienphat > 0)
                            {
                                tienPhatSach = ptChuaSach.Tongtienphat ?? 0;
                                trangThaiThanhToan = ptChuaSach.Trangthaithanhtoan ?? "Chưa thanh toán";
                            }
                        }
                        else // Chưa trả
                        {
                            if (statusHienThi != "Chờ duyệt" && statusHienThi != "Từ chối" && statusHienThi != "Chờ trả")
                            {
                                if (today > hanTraSach)
                                {
                                    statusHienThi = "Quá hạn";
                                    int daysLate = today.DayNumber - hanTraSach.DayNumber;
                                    tienPhatSach = daysLate * 1000;
                                    trangThaiThanhToan = "Chưa trả sách";
                                }
                                else statusHienThi = "Đang mượn";
                            }
                        }

                        result.Add(new LichSuMuonDto
                        {
                            MaPhieu = pm.Mapm,
                            MaSach = ctMuon.MasachNavigation.Masach,
                            TenSach = ctMuon.MasachNavigation.Tensach,
                            HinhAnh = ctMuon.MasachNavigation.Hinhanh,
                            GiaMuon = ctMuon.MasachNavigation.Giamuon,
                            NgayMuon = pm.Ngaylapphieumuon.ToDateTime(TimeOnly.MinValue),
                            HanTra = hanTraSach.ToDateTime(TimeOnly.MinValue),
                            TrangThai = statusHienThi,
                            TienPhat = tienPhatSach,
                            TrangThaiThanhToan = trangThaiThanhToan,
                            // [MỚI] Trả về trạng thái gia hạn
                            TrangThaiGiaHan = ctMuon.Trangthaigiahan // Có thể là null, "Chờ duyệt", "Đã duyệt", "Từ chối"
                        });
                    }
                }
                return Ok(result);
            }

            [HttpPost("thanh-toan-phat/{maPhieu}")]
            public async Task<IActionResult> ThanhToanPhat(int maPhieu)
            {
                var listPhieuTra = await _context.Phieutras
                    .Where(pt => pt.Mapm == maPhieu && pt.Tongtienphat > 0 && pt.Trangthaithanhtoan == "Chưa thanh toán")
                    .ToListAsync();

                if (!listPhieuTra.Any()) return BadRequest(new { success = false, message = "Không tìm thấy khoản phạt nào cần thanh toán." });

                foreach (var pt in listPhieuTra) pt.Trangthaithanhtoan = "Đã thanh toán";
                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = "Thanh toán thành công!" });
            }

            [HttpPost("Extend/{mapm}")]
            public async Task<IActionResult> ExtendLoan(int mapm, [FromBody] ExtendRequestDto request)
            {
                var chiTiet = await _context.Chitietphieumuons
                    .FirstOrDefaultAsync(ct => ct.Mapm == mapm && ct.Masach == request.MaSach);

                if (chiTiet == null) return NotFound(new { success = false, message = "Không tìm thấy sách trong phiếu mượn." });

                // -----------------------------------------------------------
                // [LOGIC MỚI] Kiểm tra quá hạn
                // -----------------------------------------------------------
                DateOnly today = DateOnly.FromDateTime(DateTime.Now);
                DateOnly hanTraHienTai = chiTiet.Hantra ?? today;

                // Nếu hạn trả nhỏ hơn ngày hiện tại -> Đã quá hạn
                if (hanTraHienTai < today)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Sách này đã quá hạn! Bạn không thể gia hạn. Vui lòng mang sách đến trả và đóng phạt."
                    });
                }
                // -----------------------------------------------------------

                // Kiểm tra trạng thái đang chờ
                if (chiTiet.Trangthaigiahan == "Chờ duyệt")
                    return BadRequest(new { success = false, message = "Bạn đã gửi yêu cầu gia hạn cho sách này rồi, vui lòng chờ duyệt." });

                DateOnly hanTraMoi = DateOnly.FromDateTime(request.NgayHenTraMoi);

                if (hanTraMoi <= hanTraHienTai)
                    return BadRequest(new { success = false, message = "Ngày gia hạn phải sau hạn trả cũ." });

                if ((chiTiet.Solangiahan ?? 0) >= 2)
                    return BadRequest(new { success = false, message = "Đã hết lượt gia hạn (Tối đa 2 lần)." });

                // Gửi yêu cầu (Chờ duyệt)
                chiTiet.Trangthaigiahan = "Chờ duyệt";
                chiTiet.Ngaygiahanmongmuon = hanTraMoi;

                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = "Đã gửi yêu cầu gia hạn. Vui lòng chờ thủ thư phê duyệt." });
            }

            [HttpPost("reset-demo/{mapm}")]
            public async Task<IActionResult> ResetDemoData(int mapm)
            {
                var listPhieuTra = await _context.Phieutras.Where(pt => pt.Mapm == mapm).ToListAsync();
                if (listPhieuTra.Any())
                {
                    var listMaPT = listPhieuTra.Select(pt => pt.Mapt).ToList();
                    var listChiTiet = await _context.Chitietphieutras.Where(ct => listMaPT.Contains(ct.Mapt)).ToListAsync();
                    _context.Chitietphieutras.RemoveRange(listChiTiet);
                    _context.Phieutras.RemoveRange(listPhieuTra);
                }
                var pm = await _context.Phieumuons.FindAsync(mapm);
                if (pm != null)
                {
                    pm.Trangthai = "Quá hạn";
                    pm.Hantra = DateOnly.FromDateTime(DateTime.Now.AddDays(-5));
                    var chiTietMuon = await _context.Chitietphieumuons.Where(ct => ct.Mapm == mapm).ToListAsync();
                    foreach (var item in chiTietMuon)
                    {
                        item.Hantra = pm.Hantra;
                        item.Solangiahan = 0;
                    }
                }
                await _context.SaveChangesAsync();
                return Ok(new { message = $"Đã reset phiếu mượn {mapm} về trạng thái QUÁ HẠN thành công!" });
            }
            [HttpGet("librarian-stats")]
            public async Task<IActionResult> GetLibrarianStats()
            {
                // 1. Đếm phiếu đang chờ duyệt mượn
                int choDuyet = await _context.Phieumuons
                    .CountAsync(p => p.Trangthai == "Chờ duyệt");

                // 2. Đếm phiếu ĐANG CÓ YÊU CẦU TRẢ (status = "Chờ trả")
                int yeuCauTra = await _context.Phieumuons
                    .CountAsync(p => p.Trangthai == "Chờ trả");

                // 3. Đếm câu hỏi chưa trả lời
                int cauHoiMoi = await _context.Hoidaps
                    .CountAsync(h => h.Trangthai == "Chờ trả lời");

                // 4. [MỚI] Đếm yêu cầu gia hạn (nằm trong bảng chi tiết)
                int yeuCauGiaHan = await _context.Chitietphieumuons
                    .CountAsync(ct => ct.Trangthaigiahan == "Chờ duyệt");

                return Ok(new
                {
                    ChoDuyet = choDuyet,
                    YeuCauTra = yeuCauTra,
                    CauHoiMoi = cauHoiMoi,
                    YeuCauGiaHan = yeuCauGiaHan // Trả thêm trường này về
                });
            }

            [HttpPost("request-return")]
            public async Task<IActionResult> RequestReturn([FromBody] TraSachDto request)
            {
                var pm = await _context.Phieumuons.FindAsync(request.MaPhieuMuon);
                if (pm == null) return NotFound(new { success = false, message = "Không tìm thấy phiếu." });
                if (pm.Trangthai == "Chờ trả" || pm.Trangthai == "Đã trả") return BadRequest(new { success = false, message = "Trạng thái không hợp lệ." });

                pm.Trangthai = "Chờ trả";
                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = "Đã gửi yêu cầu trả." });
            }

            [HttpGet("borrowed-books")]
            public async Task<IActionResult> GetBorrowedBooksForLibrarian()
            {
                var today = DateOnly.FromDateTime(DateTime.Now);
                var list = await _context.Chitietphieumuons
                    .Include(ct => ct.MapmNavigation).ThenInclude(pm => pm.MasvNavigation)
                    .Include(ct => ct.MasachNavigation)
                    .Where(ct => ct.MapmNavigation.Trangthai == "Chờ trả")
                    .Select(ct => new {
                        MaPhieu = ct.Mapm,
                        MaSach = ct.Masach,
                        TenDocGia = ct.MapmNavigation.MasvNavigation.Hovaten,
                        TenSach = ct.MasachNavigation.Tensach,
                        MaSachHienThi = $"S{ct.Masach.ToString("D4")}",
                        NgayMuon = ct.MapmNavigation.Ngaylapphieumuon,
                        HanTra = ct.Hantra ?? ct.MapmNavigation.Hantra
                    }).ToListAsync();

                var result = list.Select(item => {
                    int soNgayQuaHan = (today > item.HanTra) ? today.DayNumber - item.HanTra.DayNumber : 0;
                    return new
                    {
                        item.MaPhieu,
                        item.MaSach,
                        item.TenDocGia,
                        item.TenSach,
                        item.MaSachHienThi,
                        NgayMuon = item.NgayMuon.ToString("dd/MM/yyyy"),
                        HanTra = item.HanTra.ToString("dd/MM/yyyy"),
                        TrangThai = soNgayQuaHan > 0 ? "Chờ trả (Quá hạn)" : "Chờ trả",
                        SoNgayQuaHan = soNgayQuaHan,
                        PhiPhat = soNgayQuaHan * 1000
                    };
                }).OrderByDescending(x => x.SoNgayQuaHan).ToList();
                return Ok(result);
            }

        [HttpGet("approval-stats")]
        public async Task<IActionResult> GetApprovalStats()
        {
            // Sử dụng biến với Unicode prefix đúng
            string choDuyetStatus = "Chờ duyệt";
            string tuChoiStatus = "Từ chối";
            string dangMuonStatus = "Đang mượn";
            string daTraStatus = "Đã trả";
            string quaHanStatus = "Quá hạn";
            string choTraStatus = "Chờ trả";

            // Đếm số lượng theo trạng thái cụ thể
            int choDuyet = await _context.Phieumuons.CountAsync(p => p.Trangthai == choDuyetStatus);
            int tuChoi = await _context.Phieumuons.CountAsync(p => p.Trangthai == tuChoiStatus);

            // Đã duyệt bao gồm:  Đang mượn, Đã trả, Quá hạn, Chờ trả
            int daDuyet = await _context.Phieumuons.CountAsync(p =>
                p.Trangthai == dangMuonStatus ||
                p.Trangthai == daTraStatus ||
                p.Trangthai == quaHanStatus ||
                p.Trangthai == choTraStatus);

            // Trả về JSON với key viết thường để khớp với Flutter
            return Ok(new { choDuyet = choDuyet, daDuyet = daDuyet, tuChoi = tuChoi });
        }

        [HttpGet("history-by-type")]
            public async Task<IActionResult> GetHistoryRequests([FromQuery] string type)
            {
                var query = _context.Phieumuons
                    .Include(p => p.MasvNavigation)
                    .Include(p => p.Chitietphieumuons).ThenInclude(ct => ct.MasachNavigation)
                    .AsQueryable();

                if (type == "rejected") query = query.Where(p => p.Trangthai == "Từ chối");
                else if (type == "approved") query = query.Where(p => p.Trangthai != "Chờ duyệt" && p.Trangthai != "Từ chối");
                else return BadRequest("Loại không hợp lệ");

                var list = await query.OrderByDescending(p => p.Ngaylapphieumuon).Select(p => new {
                    MaPhieu = p.Mapm,
                    TenSinhVien = p.MasvNavigation.Hovaten,
                    NgayMuon = p.Ngaylapphieumuon.ToString("dd/MM/yyyy"),
                    HanTra = p.Hantra.ToString("dd/MM/yyyy"),
                    TrangThai = p.Trangthai,
                    SachMuon = p.Chitietphieumuons.Select(ct => new { TenSach = ct.MasachNavigation.Tensach, SoLuong = ct.Soluong }).ToList()
                }).ToListAsync();
                return Ok(list);
            }
            [HttpGet("extension-requests")]
            public async Task<IActionResult> GetExtensionRequests()
            {
                var list = await _context.Chitietphieumuons
                    .Include(ct => ct.MapmNavigation).ThenInclude(pm => pm.MasvNavigation)
                    .Include(ct => ct.MasachNavigation)
                    .Where(ct => ct.Trangthaigiahan == "Chờ duyệt")
                    .Select(ct => new
                    {
                        MaPhieu = ct.Mapm,
                        MaSach = ct.Masach,
                        TenSach = ct.MasachNavigation.Tensach,
                        TenSinhVien = ct.MapmNavigation.MasvNavigation.Hovaten,
                        HanTraCu = ct.Hantra,
                        HanTraMoi = ct.Ngaygiahanmongmuon,
                        SoLanDaGiaHan = ct.Solangiahan
                    })
                    .ToListAsync();

                return Ok(list);
            }

            // --- [MỚI] API CHO THỦ THƯ: DUYỆT HOẶC TỪ CHỐI GIA HẠN ---
            [HttpPost("process-extension")]
            public async Task<IActionResult> ProcessExtension([FromBody] DuyetGiaHanDto request)
            {
                // Include MapmNavigation để update luôn bảng Phieumuon
                var chiTiet = await _context.Chitietphieumuons
                    .Include(ct => ct.MapmNavigation)
                    .FirstOrDefaultAsync(ct => ct.Mapm == request.MaPhieu && ct.Masach == request.MaSach);

                if (chiTiet == null) return NotFound(new { success = false, message = "Không tìm thấy yêu cầu." });

                if (request.DongY)
                {
                    if (chiTiet.Ngaygiahanmongmuon != null)
                    {
                        // 1. Cập nhật hạn trả của cuốn sách con
                        chiTiet.Hantra = chiTiet.Ngaygiahanmongmuon;
                        chiTiet.Solangiahan = (chiTiet.Solangiahan ?? 0) + 1;
                        chiTiet.Trangthaigiahan = "Đã duyệt";

                        // 2. LOGIC MỚI: Cập nhật hạn trả của PHIẾU MƯỢN (Cha)
                        // (Lấy ngày hạn trả xa nhất trong tất cả các sách của phiếu này)
                        var allBooks = await _context.Chitietphieumuons
                            .Where(ct => ct.Mapm == request.MaPhieu)
                            .ToListAsync();

                        // Tìm ngày max (bao gồm cả ngày vừa gia hạn của cuốn hiện tại)
                        DateOnly maxHanTra = chiTiet.Hantra.Value;
                        foreach (var book in allBooks)
                        {
                            if (book.Masach != request.MaSach && book.Hantra.HasValue && book.Hantra.Value > maxHanTra)
                            {
                                maxHanTra = book.Hantra.Value;
                            }
                        }

                        // Nếu ngày max mới lớn hơn hạn phiếu hiện tại -> Cập nhật phiếu
                        if (maxHanTra > chiTiet.MapmNavigation.Hantra)
                        {
                            chiTiet.MapmNavigation.Hantra = maxHanTra;

                            // Nếu phiếu đang bị "Quá hạn" mà gia hạn xong thành hợp lệ -> Chuyển về "Đang mượn"
                            if (chiTiet.MapmNavigation.Trangthai == "Quá hạn" && maxHanTra >= DateOnly.FromDateTime(DateTime.Now))
                            {
                                chiTiet.MapmNavigation.Trangthai = "Đang mượn";
                            }
                        }
                    }
                }
                else
                {
                    chiTiet.Trangthaigiahan = "Từ chối";
                }

                // 3. Reset ngày mong muốn về null để hoàn tất
                chiTiet.Ngaygiahanmongmuon = null;

                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = request.DongY ? "Đã duyệt gia hạn." : "Đã từ chối gia hạn." });
            }
            [HttpPost("cancel/{mapm}")]
            public async Task<IActionResult> CancelBorrowRequest(int mapm)
            {
                // 1. Tìm phiếu mượn
                var phieuMuon = await _context.Phieumuons
                    .Include(pm => pm.Chitietphieumuons)
                    .FirstOrDefaultAsync(p => p.Mapm == mapm);

                if (phieuMuon == null)
                    return NotFound(new { success = false, message = "Không tìm thấy phiếu mượn." });

                // 2. Kiểm tra trạng thái: Chỉ cho phép hủy khi đang "Chờ duyệt"
                if (phieuMuon.Trangthai != "Chờ duyệt")
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Không thể hủy! Phiếu này đã được xử lý hoặc đang mượn."
                    });
                }

                try
                {
                    // 3. Xóa chi tiết phiếu mượn trước
                    _context.Chitietphieumuons.RemoveRange(phieuMuon.Chitietphieumuons);

                    // 4. Xóa phiếu mượn cha
                    _context.Phieumuons.Remove(phieuMuon);

                    await _context.SaveChangesAsync();

                    return Ok(new { success = true, message = "Đã hủy yêu cầu mượn thành công!" });
                }
                catch (Exception ex)
                {
                    return StatusCode(500, new { success = false, message = "Lỗi hệ thống: " + ex.Message });
                }
            }
            // --- [MỚI] API: HỦY YÊU CẦU GIA HẠN (Dành cho Độc giả) ---
            [HttpPost("cancel-extension")]
            public async Task<IActionResult> CancelExtension([FromBody] DuyetGiaHanDto request)
            {
                // DuyetGiaHanDto chứa MaPhieu và MaSach là đủ dùng
                var chiTiet = await _context.Chitietphieumuons
                    .FirstOrDefaultAsync(ct => ct.Mapm == request.MaPhieu && ct.Masach == request.MaSach);

                if (chiTiet == null)
                    return NotFound(new { success = false, message = "Không tìm thấy sách trong phiếu mượn." });

                if (chiTiet.Trangthaigiahan != "Chờ duyệt")
                    return BadRequest(new { success = false, message = "Yêu cầu này đã được xử lý hoặc không tồn tại." });

                // Reset trạng thái gia hạn về null
                chiTiet.Trangthaigiahan = null;
                chiTiet.Ngaygiahanmongmuon = null;

                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = "Đã hủy yêu cầu gia hạn thành công." });
            }
            // --- [MỚI] API TỪ CHỐI PHIẾU MƯỢN ---
            [HttpPost("reject/{mapm}")]
            public async Task<IActionResult> RejectBorrowRequest(int mapm, [FromQuery] int maThuThuDuyet)
            {
                var phieuMuon = await _context.Phieumuons.FindAsync(mapm);
                if (phieuMuon == null) return NotFound(new { message = "Không tìm thấy phiếu mượn." });

                // Chỉ từ chối được khi đang chờ duyệt
                if (phieuMuon.Trangthai != "Chờ duyệt")
                    return BadRequest(new { message = "Phiếu này không ở trạng thái chờ duyệt." });

                phieuMuon.Trangthai = "Từ chối";
                phieuMuon.Matt = maThuThuDuyet; // Lưu lại ai là người từ chối

                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = "Đã từ chối phiếu mượn." });
            }
        }
    }