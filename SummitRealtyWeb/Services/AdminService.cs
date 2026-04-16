using Microsoft.EntityFrameworkCore;
using SummitRealtyWeb.Data;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Services;

public class AdminService
{
    private readonly SummitRealtyContext _context;

    public AdminService(SummitRealtyContext context)
    {
        _context = context;
    }

    public async Task<AdminReportData> GetReportDataAsync()
    {
        var totalProperties = await _context.Properties.CountAsync();
        var activeProperties = await _context.Properties
            .CountAsync(p => p.Status == PropertyStatus.Active);
        var totalAgents = await _context.Agents.CountAsync();
        var totalInquiries = await _context.Inquiries.CountAsync();
        var pendingInquiries = await _context.Inquiries
            .CountAsync(i => i.Status == InquiryStatus.Pending);

        var propertiesByAgent = await _context.Agents
            .Select(a => new AgentPropertySummary
            {
                AgentName = a.FirstName + " " + a.LastName,
                ActiveListings = a.Properties.Count(p => p.Status == PropertyStatus.Active),
                TotalValue = a.Properties
                    .Where(p => p.Status == PropertyStatus.Active)
                    .Sum(p => p.Price)
            })
            .OrderByDescending(x => x.ActiveListings)
            .AsNoTracking()
            .ToListAsync();

        var propertiesByType = await _context.Properties
            .Where(p => p.Status == PropertyStatus.Active)
            .GroupBy(p => p.PropertyType)
            .Select(g => new PropertyTypeSummary
            {
                PropertyType = g.Key,
                Count = g.Count(),
                AveragePrice = g.Average(p => p.Price)
            })
            .OrderByDescending(x => x.Count)
            .AsNoTracking()
            .ToListAsync();

        var recentInquiries = await _context.Inquiries
            .Include(i => i.Property)
            .Include(i => i.Agent)
            .OrderByDescending(i => i.InquiryDate)
            .Take(10)
            .AsNoTracking()
            .ToListAsync();

        return new AdminReportData
        {
            TotalProperties = totalProperties,
            ActiveProperties = activeProperties,
            TotalAgents = totalAgents,
            TotalInquiries = totalInquiries,
            PendingInquiries = pendingInquiries,
            PropertiesByAgent = propertiesByAgent,
            PropertiesByType = propertiesByType,
            RecentInquiries = recentInquiries
        };
    }
}

public class AdminReportData
{
    public int TotalProperties { get; set; }
    public int ActiveProperties { get; set; }
    public int TotalAgents { get; set; }
    public int TotalInquiries { get; set; }
    public int PendingInquiries { get; set; }
    public List<AgentPropertySummary> PropertiesByAgent { get; set; } = new();
    public List<PropertyTypeSummary> PropertiesByType { get; set; } = new();
    public List<Inquiry> RecentInquiries { get; set; } = new();
}

public class AgentPropertySummary
{
    public string AgentName { get; set; } = string.Empty;
    public int ActiveListings { get; set; }
    public decimal TotalValue { get; set; }
}

public class PropertyTypeSummary
{
    public string PropertyType { get; set; } = string.Empty;
    public int Count { get; set; }
    public decimal AveragePrice { get; set; }
}
