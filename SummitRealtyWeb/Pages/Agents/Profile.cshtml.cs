using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SummitRealtyWeb.Models;
using SummitRealtyWeb.Services;

namespace SummitRealtyWeb.Pages.Agents;

public class ProfileModel : PageModel
{
    private readonly AgentService _agentService;

    public ProfileModel(AgentService agentService)
    {
        _agentService = agentService;
    }

    public Agent? Agent { get; set; }

    public async Task<IActionResult> OnGetAsync(int id)
    {
        Agent = await _agentService.GetAgentProfileAsync(id);
        return Page();
    }
}
