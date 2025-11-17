using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Chitietphieunhap
{
    public int Mapn { get; set; }

    public int Masach { get; set; }

    public int? Soluong { get; set; }

    public decimal Gianhap { get; set; }

    public decimal? Thanhtien { get; set; }

    public virtual Phieunhap MapnNavigation { get; set; } = null!;

    public virtual Sach MasachNavigation { get; set; } = null!;
}
