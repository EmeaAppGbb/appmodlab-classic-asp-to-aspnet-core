using Microsoft.AspNetCore.Identity;

namespace SummitRealtyWeb.Models;

public class ApplicationUser : IdentityUser
{
    public int AgentId { get; set; }
    public Agent Agent { get; set; } = null!;

    public DateTime? LastLogin { get; set; }
}
