using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Data;

public class SummitRealtyContext : IdentityDbContext<ApplicationUser>
{
    public SummitRealtyContext(DbContextOptions<SummitRealtyContext> options)
        : base(options) { }

    public DbSet<Agent> Agents => Set<Agent>();
    public DbSet<Property> Properties => Set<Property>();
    public DbSet<PropertyPhoto> PropertyPhotos => Set<PropertyPhoto>();
    public DbSet<Inquiry> Inquiries => Set<Inquiry>();
    public DbSet<Appointment> Appointments => Set<Appointment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(SummitRealtyContext).Assembly);
    }
}
