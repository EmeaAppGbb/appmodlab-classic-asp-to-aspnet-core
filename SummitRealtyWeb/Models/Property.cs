using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SummitRealtyWeb.Models;

public class Property
{
    public int PropertyId { get; set; }

    [Required, StringLength(255)]
    public string Address { get; set; } = string.Empty;

    [Required, StringLength(100)]
    public string City { get; set; } = string.Empty;

    [Required, StringLength(2)]
    public string State { get; set; } = string.Empty;

    [Required, StringLength(10)]
    public string ZipCode { get; set; } = string.Empty;

    [Column(TypeName = "decimal(18,2)")]
    public decimal Price { get; set; }

    public int Bedrooms { get; set; }

    [Column(TypeName = "decimal(3,1)")]
    public decimal Bathrooms { get; set; }

    public int SquareFeet { get; set; }

    [Required, StringLength(50)]
    public string PropertyType { get; set; } = string.Empty;

    public string? Description { get; set; }

    public DateTime ListingDate { get; set; } = DateTime.UtcNow;

    public PropertyStatus Status { get; set; } = PropertyStatus.Active;

    // Foreign key
    public int AgentId { get; set; }
    public Agent Agent { get; set; } = null!;

    // Navigation properties
    public ICollection<PropertyPhoto> Photos { get; set; } = new List<PropertyPhoto>();
    public ICollection<Inquiry> Inquiries { get; set; } = new List<Inquiry>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
}
