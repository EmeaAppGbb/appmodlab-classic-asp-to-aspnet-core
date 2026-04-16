using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SummitRealtyWeb.Models;
using SummitRealtyWeb.Services;
using System.ComponentModel.DataAnnotations;

namespace SummitRealtyWeb.Pages.Inquiries;

public class ContactModel : PageModel
{
    private readonly InquiryService _inquiryService;
    private readonly PropertyService _propertyService;

    public ContactModel(InquiryService inquiryService, PropertyService propertyService)
    {
        _inquiryService = inquiryService;
        _propertyService = propertyService;
    }

    [BindProperty]
    public InquiryInput Input { get; set; } = new();

    public string? SuccessMessage { get; set; }

    public void OnGet([FromQuery] int? propertyId)
    {
        Input.PropertyId = propertyId;
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        int agentId = 1;
        if (Input.PropertyId.HasValue)
        {
            var property = await _propertyService.GetPropertyDetailAsync(Input.PropertyId.Value);
            if (property != null)
            {
                agentId = property.AgentId;
            }
        }

        var inquiry = new Inquiry
        {
            PropertyId = Input.PropertyId,
            ClientName = Input.ClientName,
            ClientEmail = Input.ClientEmail,
            ClientPhone = Input.ClientPhone,
            Message = Input.Message,
            AgentId = agentId
        };

        await _inquiryService.SubmitInquiryAsync(inquiry);

        SuccessMessage = "Thank you for your inquiry! We will contact you shortly.";
        ModelState.Clear();
        Input = new InquiryInput();
        return Page();
    }

    public class InquiryInput
    {
        public int? PropertyId { get; set; }

        [Required, StringLength(100)]
        public string ClientName { get; set; } = string.Empty;

        [Required, StringLength(100), EmailAddress]
        public string ClientEmail { get; set; } = string.Empty;

        [StringLength(20), Phone]
        public string? ClientPhone { get; set; }

        [Required]
        public string Message { get; set; } = string.Empty;
    }
}
