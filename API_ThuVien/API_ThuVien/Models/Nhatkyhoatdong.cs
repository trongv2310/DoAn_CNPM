using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace API_ThuVien.Models
{
    public partial class Nhatkyhoatdong
    {
        [Key]
        public int Manhatky { get; set; }
        public int Mataikhoan { get; set; }
        public string Hanhdong { get; set; } = null!;
        public DateTime? Thoigian { get; set; }
        public string? Ghichu { get; set; }

        public virtual Taikhoan MataikhoanNavigation { get; set; } = null!;
    }
}