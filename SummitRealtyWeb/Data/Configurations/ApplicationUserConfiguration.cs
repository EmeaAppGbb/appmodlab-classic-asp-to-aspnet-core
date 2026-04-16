using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Data.Configurations;

public class ApplicationUserConfiguration : IEntityTypeConfiguration<ApplicationUser>
{
    public void Configure(EntityTypeBuilder<ApplicationUser> builder)
    {
        builder.HasOne(u => u.Agent)
            .WithMany(a => a.Users)
            .HasForeignKey(u => u.AgentId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
