using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Nhaxuatban
{
    public int Manxb { get; set; }

    public string Tennxb { get; set; } = null!;

    public string? Diachi { get; set; }

    public string? Sdt { get; set; }

    public virtual ICollection<Sach> Saches { get; set; } = new List<Sach>();
}
