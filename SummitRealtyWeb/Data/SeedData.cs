using Microsoft.AspNetCore.Identity;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Data;

public static class SeedData
{
    public static async Task InitializeAsync(
        SummitRealtyContext context,
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole> roleManager)
    {
        // Seed roles
        string[] roles = ["Admin", "Agent"];
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole(role));
            }
        }

        // Seed default admin user
        const string adminEmail = "admin@summitrealty.com";
        if (await userManager.FindByEmailAsync(adminEmail) == null)
        {
            // Ensure agent record exists for admin before creating user
            if (!context.Agents.Any(a => a.Email == adminEmail))
            {
                context.Agents.Add(new Agent
                {
                    FirstName = "System",
                    LastName = "Administrator",
                    Email = adminEmail,
                    Phone = "(555) 000-0000",
                    LicenseNumber = "RE-ADMIN-001",
                    Bio = "System administrator account.",
                    HireDate = DateTime.UtcNow
                });
                await context.SaveChangesAsync();
            }

            var adminAgent = context.Agents.First(a => a.Email == adminEmail);

            var adminUser = new ApplicationUser
            {
                UserName = adminEmail,
                Email = adminEmail,
                EmailConfirmed = true,
                AgentId = adminAgent.AgentId
            };

            var result = await userManager.CreateAsync(adminUser, "Admin@Summit2026!");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(adminUser, "Admin");
            }
        }

        if (context.Agents.Count(a => a.Email != adminEmail) > 0) return; // Already seeded agents

        var agents = new List<Agent>
        {
            new() { AgentId = 1, FirstName = "Sarah", LastName = "Johnson", Email = "sarah.johnson@summitrealty.com", Phone = "(555) 123-4567", LicenseNumber = "RE-2019-001", Bio = "Specializing in luxury homes and waterfront properties with 15 years of experience.", HireDate = new DateTime(2019, 3, 15) },
            new() { AgentId = 2, FirstName = "Michael", LastName = "Chen", Email = "michael.chen@summitrealty.com", Phone = "(555) 234-5678", LicenseNumber = "RE-2020-002", Bio = "Expert in commercial real estate and investment properties.", HireDate = new DateTime(2020, 6, 1) },
            new() { AgentId = 3, FirstName = "Emily", LastName = "Rodriguez", Email = "emily.rodriguez@summitrealty.com", Phone = "(555) 345-6789", LicenseNumber = "RE-2018-003", Bio = "First-time homebuyer specialist with a passion for helping families find their dream home.", HireDate = new DateTime(2018, 1, 10) },
            new() { AgentId = 4, FirstName = "David", LastName = "Williams", Email = "david.williams@summitrealty.com", Phone = "(555) 456-7890", LicenseNumber = "RE-2021-004", Bio = "Focused on suburban developments and new construction.", HireDate = new DateTime(2021, 9, 20) },
            new() { AgentId = 5, FirstName = "Jessica", LastName = "Taylor", Email = "jessica.taylor@summitrealty.com", Phone = "(555) 567-8901", LicenseNumber = "RE-2017-005", Bio = "Top producer specializing in downtown condos and urban living.", HireDate = new DateTime(2017, 4, 5) }
        };

        context.Agents.AddRange(agents);
        await context.SaveChangesAsync();

        var properties = new List<Property>
        {
            new() { Address = "123 Lakewood Drive", City = "Austin", State = "TX", ZipCode = "78701", Price = 450000m, Bedrooms = 4, Bathrooms = 3.0m, SquareFeet = 2800, PropertyType = "Single Family", Description = "Beautiful lakefront property with panoramic views. Updated kitchen with granite countertops and stainless steel appliances.", AgentId = 1, Status = PropertyStatus.Active },
            new() { Address = "456 Oak Street", City = "Austin", State = "TX", ZipCode = "78702", Price = 325000m, Bedrooms = 3, Bathrooms = 2.0m, SquareFeet = 1950, PropertyType = "Single Family", Description = "Charming home in a quiet neighborhood with mature oak trees. Recently renovated bathrooms.", AgentId = 1, Status = PropertyStatus.Active },
            new() { Address = "789 Congress Ave #12B", City = "Austin", State = "TX", ZipCode = "78701", Price = 275000m, Bedrooms = 2, Bathrooms = 2.0m, SquareFeet = 1200, PropertyType = "Condo", Description = "Modern downtown condo with skyline views. Walking distance to shops and restaurants.", AgentId = 5, Status = PropertyStatus.Active },
            new() { Address = "1010 Ranch Road", City = "Dripping Springs", State = "TX", ZipCode = "78620", Price = 625000m, Bedrooms = 5, Bathrooms = 3.5m, SquareFeet = 3500, PropertyType = "Single Family", Description = "Sprawling ranch home on 5 acres. Custom pool, detached workshop, and horse-ready property.", AgentId = 2, Status = PropertyStatus.Active },
            new() { Address = "222 Elm Boulevard", City = "Round Rock", State = "TX", ZipCode = "78664", Price = 350000m, Bedrooms = 4, Bathrooms = 2.5m, SquareFeet = 2400, PropertyType = "Single Family", Description = "Family-friendly home near top-rated schools. Open floor plan with large backyard.", AgentId = 3, Status = PropertyStatus.Active },
            new() { Address = "555 Market Street #5A", City = "Austin", State = "TX", ZipCode = "78703", Price = 195000m, Bedrooms = 1, Bathrooms = 1.0m, SquareFeet = 750, PropertyType = "Condo", Description = "Cozy studio-style condo perfect for young professionals. Includes parking and gym access.", AgentId = 5, Status = PropertyStatus.Active },
            new() { Address = "888 Hilltop Lane", City = "Cedar Park", State = "TX", ZipCode = "78613", Price = 475000m, Bedrooms = 4, Bathrooms = 3.0m, SquareFeet = 2900, PropertyType = "Single Family", Description = "Stunning hilltop home with Hill Country views. Chef's kitchen and wine cellar.", AgentId = 4, Status = PropertyStatus.Active },
            new() { Address = "333 Riverside Drive", City = "Austin", State = "TX", ZipCode = "78704", Price = 550000m, Bedrooms = 3, Bathrooms = 2.5m, SquareFeet = 2200, PropertyType = "Townhouse", Description = "Luxurious townhouse on the river. Private dock and outdoor entertaining area.", AgentId = 1, Status = PropertyStatus.Active },
            new() { Address = "100 Commercial Blvd", City = "Austin", State = "TX", ZipCode = "78701", Price = 850000m, Bedrooms = 0, Bathrooms = 2.0m, SquareFeet = 5000, PropertyType = "Commercial", Description = "Prime commercial space in downtown Austin. Open layout suitable for office or retail.", AgentId = 2, Status = PropertyStatus.Active },
            new() { Address = "777 Sunset Drive", City = "Lakeway", State = "TX", ZipCode = "78734", Price = 725000m, Bedrooms = 5, Bathrooms = 4.0m, SquareFeet = 4200, PropertyType = "Single Family", Description = "Executive home in gated community. Home theater, pool, and three-car garage.", AgentId = 3, Status = PropertyStatus.Active }
        };

        context.Properties.AddRange(properties);
        await context.SaveChangesAsync();

        // Add sample photos
        var photos = new List<PropertyPhoto>();
        for (int i = 1; i <= properties.Count; i++)
        {
            photos.Add(new PropertyPhoto { PropertyId = i, FilePath = $"/images/properties/property-{i}-front.jpg", Caption = "Front view", SortOrder = 1 });
            photos.Add(new PropertyPhoto { PropertyId = i, FilePath = $"/images/properties/property-{i}-interior.jpg", Caption = "Interior", SortOrder = 2 });
        }
        context.PropertyPhotos.AddRange(photos);
        await context.SaveChangesAsync();

        // Add sample inquiries
        var inquiries = new List<Inquiry>
        {
            new() { PropertyId = 1, ClientName = "John Smith", ClientEmail = "john.smith@email.com", ClientPhone = "(555) 111-2222", Message = "I'd like to schedule a viewing of this lakefront property. Available weekends.", AgentId = 1, Status = InquiryStatus.Pending },
            new() { PropertyId = 3, ClientName = "Alice Brown", ClientEmail = "alice.brown@email.com", ClientPhone = "(555) 333-4444", Message = "Interested in the downtown condo. What are the HOA fees?", AgentId = 5, Status = InquiryStatus.Contacted },
            new() { PropertyId = 5, ClientName = "Robert Davis", ClientEmail = "robert.davis@email.com", Message = "First-time buyer looking at homes near good schools. Can we schedule a tour?", AgentId = 3, Status = InquiryStatus.Pending },
            new() { PropertyId = 4, ClientName = "Maria Garcia", ClientEmail = "maria.garcia@email.com", ClientPhone = "(555) 555-6666", Message = "Very interested in the ranch property. Is the price negotiable?", AgentId = 2, Status = InquiryStatus.Pending },
            new() { PropertyId = 10, ClientName = "James Wilson", ClientEmail = "james.wilson@email.com", ClientPhone = "(555) 777-8888", Message = "Looking for a luxury home in Lakeway. Can you tell me more about the community?", AgentId = 3, Status = InquiryStatus.Closed }
        };

        context.Inquiries.AddRange(inquiries);
        await context.SaveChangesAsync();
    }
}
