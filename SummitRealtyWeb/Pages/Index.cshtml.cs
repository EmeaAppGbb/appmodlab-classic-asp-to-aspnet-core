using Microsoft.AspNetCore.Mvc.RazorPages;
using SummitRealtyWeb.Models;
using SummitRealtyWeb.Services;

namespace SummitRealtyWeb.Pages;

public class IndexModel : PageModel
{
    private readonly PropertyService _propertyService;

    public IndexModel(PropertyService propertyService)
    {
        _propertyService = propertyService;
    }

    public List<Property> FeaturedProperties { get; set; } = new();

    public async Task OnGetAsync()
    {
        FeaturedProperties = await _propertyService.GetFeaturedPropertiesAsync(6);
    }
}
