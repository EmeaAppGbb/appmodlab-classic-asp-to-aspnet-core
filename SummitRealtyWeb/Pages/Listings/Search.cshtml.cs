using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SummitRealtyWeb.Models;
using SummitRealtyWeb.Services;

namespace SummitRealtyWeb.Pages.Listings;

public class SearchModel : PageModel
{
    private readonly PropertyService _propertyService;

    public SearchModel(PropertyService propertyService)
    {
        _propertyService = propertyService;
    }

    [BindProperty(SupportsGet = true)]
    public string? City { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? State { get; set; }

    [BindProperty(SupportsGet = true)]
    public decimal? MinPrice { get; set; }

    [BindProperty(SupportsGet = true)]
    public decimal? MaxPrice { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? Bedrooms { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? PropertyType { get; set; }

    public List<Property> Results { get; set; } = new();

    public async Task OnGetAsync()
    {
        Results = await _propertyService.SearchPropertiesAsync(
            City, State, MinPrice, MaxPrice, Bedrooms, PropertyType);
    }
}
