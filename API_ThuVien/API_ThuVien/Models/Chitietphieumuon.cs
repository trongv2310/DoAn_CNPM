using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Chitietphieumuon
{
    public int Mapm { get; set; }

    public int Masach { get; set; }

    public int? Soluong { get; set; }

    // --- THÊM 2 DÒNG NÀY ĐỂ HẾT LỖI ĐỎ ---
    public DateOnly? Hantra { get; set; }
    public int? Solangiahan { get; set; }
    // -------------------------------------

    public virtual Phieumuon MapmNavigation { get; set; } = null!;

    public virtual Sach MasachNavigation { get; set; } = null!;
}