using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Data.Configurations;

public class PropertyConfiguration : IEntityTypeConfiguration<Property>
{
    public void Configure(EntityTypeBuilder<Property> builder)
    {
        builder.HasKey(p => p.PropertyId);

        builder.Property(p => p.Address).HasMaxLength(255).IsRequired();
        builder.Property(p => p.City).HasMaxLength(100).IsRequired();
        builder.Property(p => p.State).HasMaxLength(2).IsRequired();
        builder.Property(p => p.ZipCode).HasMaxLength(10).IsRequired();
        builder.Property(p => p.Price).HasColumnType("decimal(18,2)");
        builder.Property(p => p.Bathrooms).HasColumnType("decimal(3,1)");
        builder.Property(p => p.PropertyType).HasMaxLength(50).IsRequired();
        builder.Property(p => p.Status).HasConversion<string>().HasMaxLength(20);
        builder.Property(p => p.ListingDate).HasDefaultValueSql("GETUTCDATE()");

        builder.HasOne(p => p.Agent)
            .WithMany(a => a.Properties)
            .HasForeignKey(p => p.AgentId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(p => p.Photos)
            .WithOne(ph => ph.Property)
            .HasForeignKey(ph => ph.PropertyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(p => p.Inquiries)
            .WithOne(i => i.Property)
            .HasForeignKey(i => i.PropertyId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasMany(p => p.Appointments)
            .WithOne(ap => ap.Property)
            .HasForeignKey(ap => ap.PropertyId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
