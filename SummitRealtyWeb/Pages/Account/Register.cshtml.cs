using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using SummitRealtyWeb.Data;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Pages.Account;

[Authorize(Policy = "AdminOnly")]
public class RegisterModel : PageModel
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly SummitRealtyContext _context;
    private readonly ILogger<RegisterModel> _logger;

    public RegisterModel(
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole> roleManager,
        SummitRealtyContext context,
        ILogger<RegisterModel> logger)
    {
        _userManager = userManager;
        _roleManager = roleManager;
        _context = context;
        _logger = logger;
    }

    [BindProperty]
    public InputModel Input { get; set; } = new();

    public SelectList AgentOptions { get; set; } = null!;
    public SelectList RoleOptions { get; set; } = null!;

    public class InputModel
    {
        [Required]
        [EmailAddress]
        [Display(Name = "Email")]
        public string Email { get; set; } = string.Empty;

        [Required]
        [DataType(DataType.Password)]
        [StringLength(100, MinimumLength = 12, ErrorMessage = "Password must be at least {2} characters long.")]
        [Display(Name = "Password")]
        public string Password { get; set; } = string.Empty;

        [Required]
        [DataType(DataType.Password)]
        [Compare("Password", ErrorMessage = "Passwords do not match.")]
        [Display(Name = "Confirm Password")]
        public string ConfirmPassword { get; set; } = string.Empty;

        [Required]
        [Display(Name = "Agent")]
        public int AgentId { get; set; }

        [Required]
        [Display(Name = "Role")]
        public string Role { get; set; } = "Agent";
    }

    public async Task OnGetAsync()
    {
        await LoadFormDataAsync();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            await LoadFormDataAsync();
            return Page();
        }

        var user = new ApplicationUser
        {
            UserName = Input.Email,
            Email = Input.Email,
            AgentId = Input.AgentId
        };

        var result = await _userManager.CreateAsync(user, Input.Password);

        if (result.Succeeded)
        {
            await _userManager.AddToRoleAsync(user, Input.Role);
            _logger.LogInformation("Admin created new user {Email} with role {Role}.", Input.Email, Input.Role);
            return RedirectToPage("/Admin/Users");
        }

        foreach (var error in result.Errors)
        {
            ModelState.AddModelError(string.Empty, error.Description);
        }

        await LoadFormDataAsync();
        return Page();
    }

    private async Task LoadFormDataAsync()
    {
        var agents = await _context.Agents
            .OrderBy(a => a.LastName)
            .ThenBy(a => a.FirstName)
            .Select(a => new { a.AgentId, Name = a.FirstName + " " + a.LastName })
            .ToListAsync();

        AgentOptions = new SelectList(agents, "AgentId", "Name");

        var roles = await _roleManager.Roles
            .OrderBy(r => r.Name)
            .ToListAsync();

        RoleOptions = new SelectList(roles, "Name", "Name");
    }
}
