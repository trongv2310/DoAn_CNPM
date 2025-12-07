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
        [HttpPost]
        public async Task<IActionResult> CreateBorrowRequest([FromBody] BorrowRequestDto request)
        {
            if (request == null || request.SachMuon == null || !request.SachMuon.Any())
                return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ." });

            DateOnly ngayHienTai = DateOnly.FromDateTime(DateTime.Now);
            DateOnly hanTra = DateOnly.FromDateTime(request.NgayHenTra);

            if (hanTra <= ngayHienTai)
                return BadRequest(new { success = false, message = "Ngày hẹn trả phải sau ngày hôm nay." });

            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    var sinhVien = await _context.Sinhviens.FirstOrDefaultAsync(sv => sv.Mataikhoan == request.MaTaiKhoan);
                    if (sinhVien == null) return NotFound(new { success = false, message = "Không tìm thấy thông tin sinh viên." });

                    var defaultThuThu = await _context.Thuthus.FirstOrDefaultAsync();
                    int firstMapm = 0;

                    // --- ĐIỂM KHÁC BIỆT: Tách từng sách ra thành 1 phiếu riêng ---
                    foreach (var item in request.SachMuon)
                    {
                        // Kiểm tra tồn kho
                        var sach = await _context.Saches.FindAsync(item.MaSach);
                        if (sach == null) throw new Exception($"Sách ID {item.MaSach} không tồn tại.");
                        if (sach.Soluongton < item.SoLuong)
                            throw new Exception($"Sách '{sach.Tensach}' hiện không đủ số lượng (Còn: {sach.Soluongton}).");

                        // Tạo 1 Phiếu Mượn cho RIÊNG cuốn sách này
                        var newPhieuMuon = new Phieumuon
                        {
                            Masv = sinhVien.Masv,
                            Matt = defaultThuThu?.Matt ?? 1,
                            Ngaylapphieumuon = ngayHienTai,
                            Hantra = hanTra,
                            Trangthai = "Chờ duyệt", // Trạng thái này giờ chỉ đại diện cho đúng 1 cuốn sách này
                            Solangiahan = 0
                        };

                        _context.Phieumuons.Add(newPhieuMuon);
                        await _context.SaveChangesAsync(); // Lưu để lấy ID phiếu mới

                        if (firstMapm == 0) firstMapm = newPhieuMuon.Mapm;

                        // Tạo chi tiết (Mỗi phiếu chỉ có 1 dòng chi tiết này)
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

                    return Ok(new
                    {
                        success = true,
                        message = "Gửi yêu cầu thành công. Đã tách thành các phiếu riêng biệt.",
                        maPhieuMuon = firstMapm
                    });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return BadRequest(new { success = false, message = ex.Message });
                }
            }
        }

        // --- ENDPOINT 2: Thủ thư duyệt yêu cầu (ĐÃ SỬA: TRỪ KHO TẠI ĐÂY) ---
        [HttpPost("approve/{mapm}")]
        public async Task<IActionResult> ApproveBorrowRequest(int mapm, [FromQuery] int maThuThuDuyet)
        {
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    // Phải Include chi tiết để biết sách nào cần trừ
                    var phieuMuon = await _context.Phieumuons
                                            .Include(pm => pm.Chitietphieumuons)
                                            .FirstOrDefaultAsync(p => p.Mapm == mapm);

                    if (phieuMuon == null) return NotFound(new { message = "Không tìm thấy phiếu mượn." });

                    if (phieuMuon.Trangthai != "Chờ duyệt")
                        return BadRequest(new { message = "Phiếu này không ở trạng thái chờ duyệt." });

                    // --- LOGIC MỚI: TRỪ TỒN KHO ---
                    foreach (var ct in phieuMuon.Chitietphieumuons)
                    {
                        var sach = await _context.Saches.FindAsync(ct.Masach);
                        if (sach == null) throw new Exception($"Sách ID {ct.Masach} bị lỗi dữ liệu.");

                        // Kiểm tra lại lần cuối (Race condition check)
                        if (sach.Soluongton < ct.Soluong)
                        {
                            throw new Exception($"Sách '{sach.Tensach}' đã hết hàng trong kho, không thể duyệt phiếu này.");
                        }

                        sach.Soluongton -= (ct.Soluong ?? 0);
                        _context.Saches.Update(sach);
                    }

                    // Cập nhật trạng thái sang Đang mượn
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

        // --- ENDPOINT MỚI: Lấy danh sách phiếu chờ duyệt (Cho Thủ thư) ---
        [HttpGet("pending")]
        public async Task<IActionResult> GetPendingRequests()
        {
            var list = await _context.Phieumuons
                .Include(p => p.MasvNavigation) // Lấy tên sinh viên
                .Include(p => p.Chitietphieumuons)
                    .ThenInclude(ct => ct.MasachNavigation) // Lấy tên sách
                .Where(p => p.Trangthai == "Chờ duyệt")
                .OrderBy(p => p.Ngaylapphieumuon)
                .Select(p => new
                {
                    MaPhieu = p.Mapm,
                    TenSinhVien = p.MasvNavigation.Hovaten,
                    NgayMuon = p.Ngaylapphieumuon.ToString("dd/MM/yyyy"),
                    HanTra = p.Hantra.ToString("dd/MM/yyyy"),
                    SachMuon = p.Chitietphieumuons.Select(ct => new {
                        TenSach = ct.MasachNavigation.Tensach,
                        SoLuong = ct.Soluong
                    }).ToList()
                })
                .ToListAsync();

            return Ok(list);
        }

        // --- SỬA LẠI API LẤY LỊCH SỬ ---
        [HttpGet("History/{maTaiKhoan}")]
        public async Task<IActionResult> GetLichSuMuon(int maTaiKhoan)
        {
            var sv = await _context.Sinhviens.FirstOrDefaultAsync(s => s.Mataikhoan == maTaiKhoan);
            if (sv == null) return NotFound("Không tìm thấy sinh viên");

            var listPhieuMuon = await _context.Phieumuons
                .Include(pm => pm.Chitietphieumuons)
                    .ThenInclude(ct => ct.MasachNavigation)
                .Where(pm => pm.Masv == sv.Masv)
                .OrderByDescending(pm => pm.Ngaylapphieumuon)
                .ToListAsync();

            var result = new List<LichSuMuonDto>();
            var today = DateOnly.FromDateTime(DateTime.Now);

            foreach (var pm in listPhieuMuon)
            {
                foreach (var ct in pm.Chitietphieumuons)
                {
                    // Lấy trạng thái trực tiếp từ Phiếu
                    string statusHienThi = pm.Trangthai;

                    double tienPhatSach = 0;
                    DateOnly hanTraSach = ct.Hantra ?? pm.Hantra;

                    // Xử lý hiển thị Quá hạn nếu chưa trả
                    if (pm.Trangthai != "Đã trả" && pm.Trangthai != "Chờ duyệt" && pm.Trangthai != "Từ chối" && today > hanTraSach)
                    {
                        if (statusHienThi == "Đang mượn") statusHienThi = "Quá hạn";
                        int daysLate = today.DayNumber - hanTraSach.DayNumber;
                        tienPhatSach = daysLate * 1000;
                    }

                    // Nếu đã trả thì lấy tiền phạt thực tế (nếu có)
                    if (pm.Trangthai == "Đã trả")
                    {
                        var phieuTra = await _context.Phieutras
                           .Where(pt => pt.Mapm == pm.Mapm)
                           .OrderByDescending(pt => pt.Ngaylapphieutra)
                           .FirstOrDefaultAsync();
                        if (phieuTra != null) tienPhatSach = phieuTra.Tongtienphat ?? 0;
                    }

                    result.Add(new LichSuMuonDto
                    {
                        MaPhieu = pm.Mapm,
                        MaSach = ct.MasachNavigation.Masach,
                        TenSach = ct.MasachNavigation.Tensach,
                        HinhAnh = ct.MasachNavigation.Hinhanh,
                        GiaMuon = ct.MasachNavigation.Giamuon,
                        NgayMuon = pm.Ngaylapphieumuon.ToDateTime(TimeOnly.MinValue),
                        HanTra = hanTraSach.ToDateTime(TimeOnly.MinValue),
                        TrangThai = statusHienThi,
                        TienPhat = tienPhatSach
                    });
                }
            }
            return Ok(result);
        }

        // --- ENDPOINT 4: Gia hạn sách ---
        [HttpPost("Extend/{mapm}")]
        public async Task<IActionResult> ExtendLoan(int mapm, [FromBody] ExtendRequestDto request)
        {
            var chiTiet = await _context.Chitietphieumuons
                .FirstOrDefaultAsync(ct => ct.Mapm == mapm && ct.Masach == request.MaSach);

            if (chiTiet == null) return NotFound(new { success = false, message = "Không tìm thấy sách." });

            DateOnly hanTraCu = chiTiet.Hantra ?? DateOnly.FromDateTime(DateTime.Now);
            DateOnly hanTraMoi = DateOnly.FromDateTime(request.NgayHenTraMoi);

            if (hanTraMoi <= hanTraCu)
                return BadRequest(new { success = false, message = "Ngày gia hạn phải sau hạn trả cũ." });

            if ((chiTiet.Solangiahan ?? 0) >= 2)
                return BadRequest(new { success = false, message = "Đã hết lượt gia hạn (Tối đa 2 lần)." });

            chiTiet.Hantra = hanTraMoi;
            chiTiet.Solangiahan = (chiTiet.Solangiahan ?? 0) + 1;

            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Gia hạn thành công!" });
        }

        // DEMO QUÁ HẠN
        // Gọi API này bằng Postman hoặc Swagger: POST /api/PhieuMuon/reset-demo/{mapm}
        [HttpPost("reset-demo/{mapm}")]
        public async Task<IActionResult> ResetDemoData(int mapm)
        {
            // 1. Tìm tất cả phiếu trả liên quan đến phiếu mượn này
            var listPhieuTra = await _context.Phieutras
                .Where(pt => pt.Mapm == mapm)
                .ToListAsync();

            if (listPhieuTra.Any())
            {
                // Lấy danh sách mã phiếu trả
                var listMaPT = listPhieuTra.Select(pt => pt.Mapt).ToList();

                // 2. Xóa Chi tiết phiếu trả (Bảng con)
                var listChiTiet = await _context.Chitietphieutras
                    .Where(ct => listMaPT.Contains(ct.Mapt))
                    .ToListAsync();
                _context.Chitietphieutras.RemoveRange(listChiTiet);

                // 3. Xóa Phiếu trả (Bảng cha)
                _context.Phieutras.RemoveRange(listPhieuTra);
            }

            // 4. Cập nhật lại Phiếu Mượn thành "Quá hạn" & Chỉnh hạn trả về quá khứ
            var pm = await _context.Phieumuons.FindAsync(mapm);
            if (pm != null)
            {
                pm.Trangthai = "Quá hạn";
                // Set hạn trả lùi về 5 ngày trước để chắc chắn nó quá hạn
                pm.Hantra = DateOnly.FromDateTime(DateTime.Now.AddDays(-5));

                // Cập nhật luôn hạn trả trong chi tiết phiếu mượn (nếu có)
                var chiTietMuon = await _context.Chitietphieumuons.Where(ct => ct.Mapm == mapm).ToListAsync();
                foreach (var item in chiTietMuon)
                {
                    item.Hantra = pm.Hantra;
                    item.Solangiahan = 0; // Reset lượt gia hạn
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = $"Đã reset phiếu mượn {mapm} về trạng thái CHƯA TRẢ và QUÁ HẠN thành công!" });
        }

        // --- ENDPOINT MỚI: Lấy thống kê nhanh cho Dashboard Thủ thư ---
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

            return Ok(new
            {
                ChoDuyet = choDuyet,
                YeuCauTra = yeuCauTra, // Trả về số lượng yêu cầu trả
                CauHoiMoi = cauHoiMoi
            });
        }

        // --- API 1: ĐỘC GIẢ GỬI YÊU CẦU TRẢ SÁCH ---
        [HttpPost("request-return")]
        public async Task<IActionResult> RequestReturn([FromBody] TraSachDto request)
        {
            // Tìm phiếu mượn
            var pm = await _context.Phieumuons.FindAsync(request.MaPhieuMuon);
            if (pm == null) return NotFound(new { success = false, message = "Không tìm thấy phiếu mượn." });

            // Kiểm tra trạng thái hợp lệ
            if (pm.Trangthai == "Chờ trả")
                return BadRequest(new { success = false, message = "Phiếu này đang chờ thủ thư xử lý rồi." });

            if (pm.Trangthai == "Đã trả")
                return BadRequest(new { success = false, message = "Phiếu này đã hoàn tất." });

            // Cập nhật trạng thái sang "Chờ trả"
            pm.Trangthai = "Chờ trả";
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Đã gửi yêu cầu trả sách. Vui lòng mang sách đến quầy thủ thư." });
        }

        // --- API 2: SỬA LẠI API LẤY DANH SÁCH CHO THỦ THƯ (CHỈ LẤY 'CHỜ TRẢ') ---
        [HttpGet("borrowed-books")]
        public async Task<IActionResult> GetBorrowedBooksForLibrarian()
        {
            var today = DateOnly.FromDateTime(DateTime.Now);

            var list = await _context.Chitietphieumuons
                .Include(ct => ct.MapmNavigation)
                    .ThenInclude(pm => pm.MasvNavigation)
                .Include(ct => ct.MasachNavigation)
                // [QUAN TRỌNG] Chỉ lấy những phiếu có trạng thái "Chờ trả"
                .Where(ct => ct.MapmNavigation.Trangthai == "Chờ trả")
                .Select(ct => new
                {
                    MaPhieu = ct.Mapm,
                    MaSach = ct.Masach,
                    TenDocGia = ct.MapmNavigation.MasvNavigation.Hovaten,
                    MaDocGia = $"DG{ct.MapmNavigation.Masv.ToString("D3")}",
                    TenSach = ct.MasachNavigation.Tensach,
                    MaSachHienThi = $"S{ct.Masach.ToString("D4")}",
                    NgayMuon = ct.MapmNavigation.Ngaylapphieumuon,
                    HanTra = ct.Hantra ?? ct.MapmNavigation.Hantra,
                    TrangThaiPhieu = ct.MapmNavigation.Trangthai
                })
                .ToListAsync();

            // Lọc logic hiển thị (Tính toán sơ bộ phí phạt để thủ thư xem trước)
            var result = list.Select(item =>
            {
                int soNgayQuaHan = 0;
                double phiPhat = 0;

                if (today > item.HanTra)
                {
                    soNgayQuaHan = item.HanTra.DayNumber > today.DayNumber ? 0 : today.DayNumber - item.HanTra.DayNumber;
                    phiPhat = soNgayQuaHan * 1000; // 1000đ/ngày
                }

                // Kiểm tra xem sách này đã được trả chưa (trong trường hợp phiếu có nhiều sách)
                // Tuy nhiên logic "Chờ trả" thường áp dụng khi user mang sách đến trả tiếp.
                // Ở đây ta hiển thị tất cả sách trong phiếu "Chờ trả" để thủ thư tích chọn.

                return new
                {
                    item.MaPhieu,
                    item.MaSach,
                    item.TenDocGia,
                    item.MaDocGia,
                    item.TenSach,
                    item.MaSachHienThi,
                    NgayMuon = item.NgayMuon.ToString("dd/MM/yyyy"),
                    HanTra = item.HanTra.ToString("dd/MM/yyyy"),
                    // Hiển thị rõ trạng thái chờ
                    TrangThai = soNgayQuaHan > 0 ? "Chờ trả (Quá hạn)" : "Chờ trả",
                    SoNgayQuaHan = soNgayQuaHan,
                    PhiPhat = phiPhat
                };
            }).OrderByDescending(x => x.SoNgayQuaHan).ToList();

            return Ok(result);
        }

        // --- API 3: Lấy thống kê duyệt mượn (Chờ / Đã duyệt / Từ chối) ---
        [HttpGet("approval-stats")]
        public async Task<IActionResult> GetApprovalStats()
        {
            // 1. Chờ duyệt
            int choDuyet = await _context.Phieumuons.CountAsync(p => p.Trangthai == "Chờ duyệt");

            // 2. Từ chối
            int tuChoi = await _context.Phieumuons.CountAsync(p => p.Trangthai == "Từ chối");

            // 3. Đã duyệt (Bao gồm Đang mượn, Đã trả, Quá hạn, Chờ trả...)
            // Logic: Tất cả phiếu không phải "Chờ duyệt" và không phải "Từ chối" đều là đã được duyệt chấp thuận
            int daDuyet = await _context.Phieumuons.CountAsync(p => p.Trangthai != "Chờ duyệt" && p.Trangthai != "Từ chối");

            return Ok(new { ChoDuyet = choDuyet, DaDuyet = daDuyet, TuChoi = tuChoi });
        }

        // --- API 4: Xem danh sách lịch sử theo loại (approved / rejected) ---
        [HttpGet("history-by-type")]
        public async Task<IActionResult> GetHistoryRequests([FromQuery] string type)
        {
            var query = _context.Phieumuons
                .Include(p => p.MasvNavigation)
                .Include(p => p.Chitietphieumuons).ThenInclude(ct => ct.MasachNavigation)
                .AsQueryable();

            if (type == "rejected")
            {
                query = query.Where(p => p.Trangthai == "Từ chối");
            }
            else if (type == "approved")
            {
                // Lấy tất cả các trạng thái thể hiện đã được duyệt
                query = query.Where(p => p.Trangthai != "Chờ duyệt" && p.Trangthai != "Từ chối");
            }
            else
            {
                return BadRequest("Loại không hợp lệ");
            }

            var list = await query
                .OrderByDescending(p => p.Ngaylapphieumuon) // Mới nhất lên đầu
                .Select(p => new
                {
                    MaPhieu = p.Mapm,
                    TenSinhVien = p.MasvNavigation.Hovaten,
                    NgayMuon = p.Ngaylapphieumuon.ToString("dd/MM/yyyy"),
                    HanTra = p.Hantra.ToString("dd/MM/yyyy"),
                    TrangThai = p.Trangthai,
                    SachMuon = p.Chitietphieumuons.Select(ct => new {
                        TenSach = ct.MasachNavigation.Tensach,
                        SoLuong = ct.Soluong
                    }).ToList()
                })
                .ToListAsync();

            return Ok(list);
        }

    }
}