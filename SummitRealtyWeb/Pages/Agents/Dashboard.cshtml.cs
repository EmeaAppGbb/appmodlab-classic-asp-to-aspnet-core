using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SummitRealtyWeb.Models;
using SummitRealtyWeb.Services;

namespace SummitRealtyWeb.Pages.Agents;

[Authorize]
public class DashboardModel : PageModel
{
    private readonly AgentService _agentService;
    private readonly UserManager<ApplicationUser> _userManager;

    public DashboardModel(AgentService agentService, UserManager<ApplicationUser> userManager)
    {
        _agentService = agentService;
        _userManager = userManager;
    }

    public AgentDashboardStats Stats { get; set; } = new();

    public async Task OnGetAsync()
    {
        var user = await _userManager.GetUserAsync(User);
        if (user != null)
        {
            Stats = await _agentService.GetAgentDashboardStatsAsync(user.AgentId);
        }
    }
}
