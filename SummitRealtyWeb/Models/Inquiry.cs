using System.ComponentModel.DataAnnotations;

namespace SummitRealtyWeb.Models;

public class Inquiry
{
    public int InquiryId { get; set; }

    public int? PropertyId { get; set; }
    public Property? Property { get; set; }

    [Required, StringLength(100)]
    public string ClientName { get; set; } = string.Empty;

    [Required, StringLength(100), EmailAddress]
    public string ClientEmail { get; set; } = string.Empty;

    [StringLength(20), Phone]
    public string? ClientPhone { get; set; }

    [Required]
    public string Message { get; set; } = string.Empty;

    public DateTime InquiryDate { get; set; } = DateTime.UtcNow;

    public InquiryStatus Status { get; set; } = InquiryStatus.Pending;

    // Foreign key
    public int AgentId { get; set; }
    public Agent Agent { get; set; } = null!;
}
