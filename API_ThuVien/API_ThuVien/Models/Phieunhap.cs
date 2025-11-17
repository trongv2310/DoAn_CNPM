using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Phieunhap
{
    public int Mapn { get; set; }

    public int Matk { get; set; }

    public DateOnly Ngaynhap { get; set; }

    public decimal Tongtien { get; set; }

    public virtual ICollection<Chitietphieunhap> Chitietphieunhaps { get; set; } = new List<Chitietphieunhap>();

    public virtual Thukho MatkNavigation { get; set; } = null!;
}
