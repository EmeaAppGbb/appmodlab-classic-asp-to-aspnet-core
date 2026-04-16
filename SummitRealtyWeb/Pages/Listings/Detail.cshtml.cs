using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SummitRealtyWeb.Models;
using SummitRealtyWeb.Services;

namespace SummitRealtyWeb.Pages.Listings;

public class DetailModel : PageModel
{
    private readonly PropertyService _propertyService;

    public DetailModel(PropertyService propertyService)
    {
        _propertyService = propertyService;
    }

    public Property? Property { get; set; }

    public async Task<IActionResult> OnGetAsync(int id)
    {
        Property = await _propertyService.GetPropertyDetailAsync(id);
        if (Property == null)
        {
            return Page();
        }
        return Page();
    }
}
