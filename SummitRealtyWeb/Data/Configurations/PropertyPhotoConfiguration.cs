using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Data.Configurations;

public class PropertyPhotoConfiguration : IEntityTypeConfiguration<PropertyPhoto>
{
    public void Configure(EntityTypeBuilder<PropertyPhoto> builder)
    {
        builder.HasKey(p => p.PhotoId);

        builder.Property(p => p.FilePath).HasMaxLength(255).IsRequired();
        builder.Property(p => p.Caption).HasMaxLength(255);
        builder.Property(p => p.SortOrder).HasDefaultValue(1);
    }
}
