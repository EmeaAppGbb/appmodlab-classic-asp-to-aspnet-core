using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Data.Configurations;

public class InquiryConfiguration : IEntityTypeConfiguration<Inquiry>
{
    public void Configure(EntityTypeBuilder<Inquiry> builder)
    {
        builder.HasKey(i => i.InquiryId);

        builder.Property(i => i.ClientName).HasMaxLength(100).IsRequired();
        builder.Property(i => i.ClientEmail).HasMaxLength(100).IsRequired();
        builder.Property(i => i.ClientPhone).HasMaxLength(20);
        builder.Property(i => i.Message).IsRequired();
        builder.Property(i => i.Status).HasConversion<string>().HasMaxLength(20);
        builder.Property(i => i.InquiryDate).HasDefaultValueSql("GETUTCDATE()");

        builder.HasOne(i => i.Agent)
            .WithMany(a => a.Inquiries)
            .HasForeignKey(i => i.AgentId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
