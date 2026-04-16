using Microsoft.EntityFrameworkCore;
using SummitRealtyWeb.Data;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Services;

public class PropertyService
{
    private readonly SummitRealtyContext _context;

    public PropertyService(SummitRealtyContext context)
    {
        _context = context;
    }

    public async Task<List<Property>> GetFeaturedPropertiesAsync(int count = 6)
    {
        return await _context.Properties
            .Include(p => p.Agent)
            .Include(p => p.Photos.OrderBy(ph => ph.SortOrder).Take(1))
            .Where(p => p.Status == PropertyStatus.Active)
            .OrderByDescending(p => p.ListingDate)
            .Take(count)
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<List<Property>> SearchPropertiesAsync(
        string? city = null, string? state = null,
        decimal? minPrice = null, decimal? maxPrice = null,
        int? bedrooms = null, string? propertyType = null)
    {
        var query = _context.Properties
            .Include(p => p.Agent)
            .Include(p => p.Photos.OrderBy(ph => ph.SortOrder).Take(1))
            .Where(p => p.Status == PropertyStatus.Active)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(city))
            query = query.Where(p => p.City.Contains(city));

        if (!string.IsNullOrWhiteSpace(state))
            query = query.Where(p => p.State == state);

        if (minPrice.HasValue)
            query = query.Where(p => p.Price >= minPrice.Value);

        if (maxPrice.HasValue)
            query = query.Where(p => p.Price <= maxPrice.Value);

        if (bedrooms.HasValue)
            query = query.Where(p => p.Bedrooms >= bedrooms.Value);

        if (!string.IsNullOrWhiteSpace(propertyType))
            query = query.Where(p => p.PropertyType == propertyType);

        return await query
            .OrderByDescending(p => p.ListingDate)
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<Property?> GetPropertyDetailAsync(int id)
    {
        return await _context.Properties
            .Include(p => p.Agent)
            .Include(p => p.Photos.OrderBy(ph => ph.SortOrder))
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.PropertyId == id);
    }

    public async Task<Property> AddPropertyAsync(Property property)
    {
        property.ListingDate = DateTime.UtcNow;
        property.Status = PropertyStatus.Active;
        _context.Properties.Add(property);
        await _context.SaveChangesAsync();
        return property;
    }

    public async Task<bool> UpdatePropertyAsync(Property property)
    {
        var existing = await _context.Properties.FindAsync(property.PropertyId);
        if (existing == null) return false;

        existing.Address = property.Address;
        existing.City = property.City;
        existing.State = property.State;
        existing.ZipCode = property.ZipCode;
        existing.Price = property.Price;
        existing.Bedrooms = property.Bedrooms;
        existing.Bathrooms = property.Bathrooms;
        existing.SquareFeet = property.SquareFeet;
        existing.PropertyType = property.PropertyType;
        existing.Description = property.Description;
        existing.Status = property.Status;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> AddPhotoAsync(int propertyId, string filePath, string? caption, int sortOrder)
    {
        var property = await _context.Properties.FindAsync(propertyId);
        if (property == null) return false;

        _context.PropertyPhotos.Add(new PropertyPhoto
        {
            PropertyId = propertyId,
            FilePath = filePath,
            Caption = caption,
            SortOrder = sortOrder
        });
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeletePhotoAsync(int photoId)
    {
        var photo = await _context.PropertyPhotos.FindAsync(photoId);
        if (photo == null) return false;

        _context.PropertyPhotos.Remove(photo);
        await _context.SaveChangesAsync();
        return true;
    }
}
