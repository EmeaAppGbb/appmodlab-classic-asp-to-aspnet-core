using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Data.Configurations;

public class AppointmentConfiguration : IEntityTypeConfiguration<Appointment>
{
    public void Configure(EntityTypeBuilder<Appointment> builder)
    {
        builder.HasKey(a => a.AppointmentId);

        builder.Property(a => a.ClientName).HasMaxLength(100).IsRequired();
        builder.Property(a => a.ClientEmail).HasMaxLength(100).IsRequired();
        builder.Property(a => a.Status).HasConversion<string>().HasMaxLength(20);

        builder.HasOne(a => a.Property)
            .WithMany(p => p.Appointments)
            .HasForeignKey(a => a.PropertyId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(a => a.Agent)
            .WithMany(ag => ag.Appointments)
            .HasForeignKey(a => a.AgentId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
