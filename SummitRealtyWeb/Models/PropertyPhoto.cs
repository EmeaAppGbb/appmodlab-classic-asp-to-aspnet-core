using System.ComponentModel.DataAnnotations;

namespace SummitRealtyWeb.Models;

public class PropertyPhoto
{
    public int PhotoId { get; set; }

    [Required, StringLength(255)]
    public string FilePath { get; set; } = string.Empty;

    [StringLength(255)]
    public string? Caption { get; set; }

    public int SortOrder { get; set; } = 1;

    // Foreign key
    public int PropertyId { get; set; }
    public Property Property { get; set; } = null!;
}
