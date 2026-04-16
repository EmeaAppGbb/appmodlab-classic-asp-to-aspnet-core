using System.ComponentModel.DataAnnotations;

namespace SummitRealtyWeb.Models;

public class Appointment
{
    public int AppointmentId { get; set; }

    public DateTime AppointmentDate { get; set; }

    [Required, StringLength(100)]
    public string ClientName { get; set; } = string.Empty;

    [Required, StringLength(100), EmailAddress]
    public string ClientEmail { get; set; } = string.Empty;

    public string? Notes { get; set; }

    public AppointmentStatus Status { get; set; } = AppointmentStatus.Scheduled;

    // Foreign keys
    public int PropertyId { get; set; }
    public Property Property { get; set; } = null!;

    public int AgentId { get; set; }
    public Agent Agent { get; set; } = null!;
}
