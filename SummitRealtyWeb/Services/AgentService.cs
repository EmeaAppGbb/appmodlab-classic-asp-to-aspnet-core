using Microsoft.EntityFrameworkCore;
using SummitRealtyWeb.Data;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Services;

public class AgentService
{
    private readonly SummitRealtyContext _context;

    public AgentService(SummitRealtyContext context)
    {
        _context = context;
    }

    public async Task<List<Agent>> GetAllAgentsAsync()
    {
        return await _context.Agents
            .Include(a => a.Properties.Where(p => p.Status == PropertyStatus.Active))
            .OrderBy(a => a.LastName)
            .ThenBy(a => a.FirstName)
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<Agent?> GetAgentProfileAsync(int agentId)
    {
        return await _context.Agents
            .Include(a => a.Properties.Where(p => p.Status == PropertyStatus.Active))
                .ThenInclude(p => p.Photos.OrderBy(ph => ph.SortOrder).Take(1))
            .AsNoTracking()
            .FirstOrDefaultAsync(a => a.AgentId == agentId);
    }

    public async Task<AgentDashboardStats> GetAgentDashboardStatsAsync(int agentId)
    {
        var agent = await _context.Agents
            .AsNoTracking()
            .FirstOrDefaultAsync(a => a.AgentId == agentId);

        if (agent == null)
            return new AgentDashboardStats();

        var activeListings = await _context.Properties
            .CountAsync(p => p.AgentId == agentId && p.Status == PropertyStatus.Active);

        var totalValue = await _context.Properties
            .Where(p => p.AgentId == agentId && p.Status == PropertyStatus.Active)
            .SumAsync(p => p.Price);

        var pendingInquiries = await _context.Inquiries
            .CountAsync(i => i.AgentId == agentId && i.Status == InquiryStatus.Pending);

        var upcomingShowings = await _context.Appointments
            .CountAsync(a => a.AgentId == agentId
                && a.Status == AppointmentStatus.Scheduled
                && a.AppointmentDate > DateTime.UtcNow);

        var recentInquiries = await _context.Inquiries
            .Include(i => i.Property)
            .Where(i => i.AgentId == agentId)
            .OrderByDescending(i => i.InquiryDate)
            .Take(5)
            .AsNoTracking()
            .ToListAsync();

        return new AgentDashboardStats
        {
            Agent = agent,
            ActiveListings = activeListings,
            TotalPortfolioValue = totalValue,
            PendingInquiries = pendingInquiries,
            UpcomingShowings = upcomingShowings,
            RecentInquiries = recentInquiries
        };
    }

    public async Task<bool> UpdateAgentProfileAsync(Agent agent)
    {
        var existing = await _context.Agents.FindAsync(agent.AgentId);
        if (existing == null) return false;

        existing.FirstName = agent.FirstName;
        existing.LastName = agent.LastName;
        existing.Email = agent.Email;
        existing.Phone = agent.Phone;
        existing.Bio = agent.Bio;
        existing.PhotoPath = agent.PhotoPath;

        await _context.SaveChangesAsync();
        return true;
    }
}

public class AgentDashboardStats
{
    public Agent? Agent { get; set; }
    public int ActiveListings { get; set; }
    public decimal TotalPortfolioValue { get; set; }
    public int PendingInquiries { get; set; }
    public int UpcomingShowings { get; set; }
    public List<Inquiry> RecentInquiries { get; set; } = new();
}
