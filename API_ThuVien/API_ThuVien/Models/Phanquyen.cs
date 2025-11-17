using System;
using System.Collections.Generic;

namespace API_ThuVien.Models;

public partial class Phanquyen
{
    public int Maquyen { get; set; }

    public string Tenquyen { get; set; } = null!;

    public virtual ICollection<Taikhoan> Taikhoans { get; set; } = new List<Taikhoan>();
}
