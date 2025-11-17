using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Tacgium
{
    public int Matg { get; set; }

    public string Tentg { get; set; } = null!;

    public string? Quoctich { get; set; }

    public string? Mota { get; set; }

    public virtual ICollection<Sach> Saches { get; set; } = new List<Sach>();
}
