using Microsoft.AspNetCore.Mvc.RazorPages;
using SummitRealtyWeb.Models;
using SummitRealtyWeb.Services;

namespace SummitRealtyWeb.Pages.Agents;

public class DirectoryModel : PageModel
{
    private readonly AgentService _agentService;

    public DirectoryModel(AgentService agentService)
    {
        _agentService = agentService;
    }

    public List<Agent> Agents { get; set; } = new();

    public async Task OnGetAsync()
    {
        Agents = await _agentService.GetAllAgentsAsync();
    }
}
