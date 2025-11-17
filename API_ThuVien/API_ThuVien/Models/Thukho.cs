using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Thukho
{
    public int Matk { get; set; }

    public int Mataikhoan { get; set; }

    public string? Hovaten { get; set; }

    public string? Gioitinh { get; set; }

    public DateOnly? Ngaysinh { get; set; }

    public string? Sdt { get; set; }

    public string? Email { get; set; }

    public virtual Taikhoan MataikhoanNavigation { get; set; } = null!;

    public virtual ICollection<Phieunhap> Phieunhaps { get; set; } = new List<Phieunhap>();

    public virtual ICollection<Thanhly> Thanhlies { get; set; } = new List<Thanhly>();
}
