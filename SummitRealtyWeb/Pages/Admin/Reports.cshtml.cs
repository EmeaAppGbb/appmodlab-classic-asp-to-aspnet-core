using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SummitRealtyWeb.Services;

namespace SummitRealtyWeb.Pages.Admin;

[Authorize(Policy = "AdminOnly")]
public class ReportsModel : PageModel
{
    private readonly AdminService _adminService;

    public ReportsModel(AdminService adminService)
    {
        _adminService = adminService;
    }

    public AdminReportData Report { get; set; } = new();

    public async Task OnGetAsync()
    {
        Report = await _adminService.GetReportDataAsync();
    }
}
