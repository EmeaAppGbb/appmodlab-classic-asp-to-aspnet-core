using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SummitRealtyWeb.Models;
using SummitRealtyWeb.Services;
using System.ComponentModel.DataAnnotations;

namespace SummitRealtyWeb.Pages.Inquiries;

public class ScheduleModel : PageModel
{
    private readonly InquiryService _inquiryService;
    private readonly PropertyService _propertyService;

    public ScheduleModel(InquiryService inquiryService, PropertyService propertyService)
    {
        _inquiryService = inquiryService;
        _propertyService = propertyService;
    }

    [BindProperty]
    public ScheduleInput Input { get; set; } = new();

    public string? SuccessMessage { get; set; }
    public string? PropertyAddress { get; set; }

    public async Task OnGetAsync([FromQuery] int? propertyId)
    {
        Input.PropertyId = propertyId ?? 0;
        await LoadPropertyAddressAsync();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            await LoadPropertyAddressAsync();
            return Page();
        }

        var property = await _propertyService.GetPropertyDetailAsync(Input.PropertyId);
        int agentId = property?.AgentId ?? 1;

        var time = TimeOnly.Parse(Input.AppointmentTime);
        var appointmentDateTime = Input.AppointmentDate.ToDateTime(time);

        var appointment = new Appointment
        {
            PropertyId = Input.PropertyId,
            AgentId = agentId,
            ClientName = Input.ClientName,
            ClientEmail = Input.ClientEmail,
            AppointmentDate = appointmentDateTime,
            Notes = Input.Notes
        };

        await _inquiryService.ScheduleShowingAsync(appointment);

        SuccessMessage = "Your appointment has been scheduled! We will send you a confirmation email shortly.";
        await LoadPropertyAddressAsync();
        ModelState.Clear();
        Input = new ScheduleInput { PropertyId = Input.PropertyId };
        return Page();
    }

    private async Task LoadPropertyAddressAsync()
    {
        if (Input.PropertyId > 0)
        {
            var property = await _propertyService.GetPropertyDetailAsync(Input.PropertyId);
            if (property != null)
            {
                PropertyAddress = $"{property.Address}, {property.City}, {property.State}";
            }
        }
    }

    public class ScheduleInput
    {
        public int PropertyId { get; set; }

        [Required, StringLength(100)]
        public string ClientName { get; set; } = string.Empty;

        [Required, StringLength(100), EmailAddress]
        public string ClientEmail { get; set; } = string.Empty;

        [Required]
        public DateOnly AppointmentDate { get; set; }

        [Required]
        public string AppointmentTime { get; set; } = string.Empty;

        public string? Notes { get; set; }
    }
}
