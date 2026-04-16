using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Data.Configurations;

public class AgentConfiguration : IEntityTypeConfiguration<Agent>
{
    public void Configure(EntityTypeBuilder<Agent> builder)
    {
        builder.HasKey(a => a.AgentId);

        builder.Property(a => a.FirstName).HasMaxLength(50).IsRequired();
        builder.Property(a => a.LastName).HasMaxLength(50).IsRequired();
        builder.Property(a => a.Email).HasMaxLength(100).IsRequired();
        builder.Property(a => a.Phone).HasMaxLength(20).IsRequired();
        builder.Property(a => a.LicenseNumber).HasMaxLength(50).IsRequired();
        builder.Property(a => a.PhotoPath).HasMaxLength(255);
        builder.Property(a => a.HireDate).HasDefaultValueSql("GETUTCDATE()");

        builder.HasIndex(a => a.Email).IsUnique();
        builder.HasIndex(a => a.LicenseNumber).IsUnique();
    }
}
