using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SummitRealtyWeb.Models;

public class Agent
{
    public int AgentId { get; set; }

    [Required, StringLength(50)]
    public string FirstName { get; set; } = string.Empty;

    [Required, StringLength(50)]
    public string LastName { get; set; } = string.Empty;

    [Required, StringLength(100), EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required, StringLength(20), Phone]
    public string Phone { get; set; } = string.Empty;

    [Required, StringLength(50)]
    public string LicenseNumber { get; set; } = string.Empty;

    public string? Bio { get; set; }

    [StringLength(255)]
    public string? PhotoPath { get; set; }

    public DateTime HireDate { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public ICollection<Property> Properties { get; set; } = new List<Property>();
    public ICollection<Inquiry> Inquiries { get; set; } = new List<Inquiry>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<ApplicationUser> Users { get; set; } = new List<ApplicationUser>();

    [NotMapped]
    public string FullName => $"{FirstName} {LastName}";
}
