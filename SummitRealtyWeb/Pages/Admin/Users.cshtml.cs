using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Pages.Admin;

[Authorize(Policy = "AdminOnly")]
public class UsersModel : PageModel
{
    private readonly UserManager<ApplicationUser> _userManager;

    public UsersModel(UserManager<ApplicationUser> userManager)
    {
        _userManager = userManager;
    }

    public List<UserViewModel> Users { get; set; } = new();

    public class UserViewModel
    {
        public string Id { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public List<string> Roles { get; set; } = new();
        public DateTime? LastLogin { get; set; }
        public bool IsLockedOut { get; set; }
    }

    public async Task OnGetAsync()
    {
        var users = _userManager.Users.ToList();

        foreach (var user in users)
        {
            var roles = await _userManager.GetRolesAsync(user);
            Users.Add(new UserViewModel
            {
                Id = user.Id,
                Email = user.Email ?? string.Empty,
                Roles = roles.ToList(),
                LastLogin = user.LastLogin,
                IsLockedOut = await _userManager.IsLockedOutAsync(user)
            });
        }
    }
}
