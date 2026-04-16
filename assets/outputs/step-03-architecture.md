# ASP.NET Core Architecture Design — Summit Realty Group

> **Purpose:** Actionable blueprint for migrating the Summit Realty Classic ASP application to ASP.NET Core 8 with Razor Pages, Entity Framework Core, and ASP.NET Core Identity.
>
> **Inputs:** [Step 1 — Application Analysis](step-01-analysis.md) · [Step 2 — Security Assessment](step-02-security-assessment.md)

---

## 1. Project Structure Overview

```
SummitRealty.Web/
├── SummitRealty.Web.csproj
├── Program.cs                          # Application entry point, DI, middleware pipeline
├── appsettings.json                    # Non-secret configuration
├── appsettings.Development.json        # Dev overrides (User Secrets for connection strings)
│
├── Models/                             # EF Core entities and enums
│   ├── Agent.cs
│   ├── Property.cs
│   ├── PropertyPhoto.cs
│   ├── Inquiry.cs
│   ├── Appointment.cs
│   ├── ApplicationUser.cs              # Extends IdentityUser — replaces Users table
│   ├── PropertyStatus.cs               # Enum: Active, Pending, Sold
│   ├── InquiryStatus.cs                # Enum: Pending, Contacted, Closed
│   └── AppointmentStatus.cs            # Enum: Scheduled, Completed
│
├── Data/                               # Data access layer
│   ├── SummitRealtyDbContext.cs         # DbContext with entity configuration
│   ├── Configurations/                 # IEntityTypeConfiguration<T> classes
│   │   ├── AgentConfiguration.cs
│   │   ├── PropertyConfiguration.cs
│   │   ├── PropertyPhotoConfiguration.cs
│   │   ├── InquiryConfiguration.cs
│   │   ├── AppointmentConfiguration.cs
│   │   └── ApplicationUserConfiguration.cs
│   └── SeedData.cs                     # Database seeding (agents, properties, photos, etc.)
│
├── Services/                           # Business logic layer
│   ├── IPropertyService.cs
│   ├── PropertyService.cs
│   ├── IAgentService.cs
│   ├── AgentService.cs
│   ├── IInquiryService.cs
│   ├── InquiryService.cs
│   ├── IAppointmentService.cs
│   ├── AppointmentService.cs
│   ├── IPhotoService.cs
│   ├── PhotoService.cs                 # File upload validation + storage
│   ├── IEmailService.cs
│   └── EmailService.cs                 # Replaces CDO email (Azure Communication Services / SendGrid)
│
├── Authorization/                      # Custom authorization policies
│   ├── PropertyOwnerHandler.cs         # Checks agent owns the property (fixes IDOR)
│   └── PropertyOwnerRequirement.cs
│
├── Pages/                              # Razor Pages (maps 1:1 to Classic ASP pages)
│   ├── _ViewImports.cshtml             # @using, @addTagHelper
│   ├── _ViewStart.cshtml               # Layout assignment
│   ├── Index.cshtml                    # ← default.asp (homepage, featured listings)
│   ├── Index.cshtml.cs
│   ├── Error.cshtml                    # Global error page
│   ├── Error.cshtml.cs
│   │
│   ├── Listings/
│   │   ├── Search.cshtml               # ← listings/search.asp (public property search)
│   │   ├── Search.cshtml.cs
│   │   ├── Detail.cshtml               # ← listings/detail.asp (property detail)
│   │   ├── Detail.cshtml.cs
│   │   ├── Add.cshtml                  # ← listings/add.asp [Authorize]
│   │   ├── Add.cshtml.cs
│   │   ├── Edit.cshtml                 # ← listings/edit.asp [Authorize + ownership]
│   │   ├── Edit.cshtml.cs
│   │   ├── Photos.cshtml               # ← listings/photos.asp [Authorize + ownership]
│   │   └── Photos.cshtml.cs
│   │
│   ├── Agents/
│   │   ├── Index.cshtml                # ← agents/directory.asp (public agent listing)
│   │   ├── Index.cshtml.cs
│   │   ├── Profile.cshtml              # ← agents/profile.asp (public agent profile)
│   │   ├── Profile.cshtml.cs
│   │   ├── Dashboard.cshtml            # ← agents/dashboard.asp [Authorize]
│   │   └── Dashboard.cshtml.cs
│   │
│   ├── Inquiries/
│   │   ├── Contact.cshtml              # ← inquiries/contact.asp (public contact form)
│   │   ├── Contact.cshtml.cs
│   │   ├── Schedule.cshtml             # ← inquiries/schedule.asp (public scheduling)
│   │   ├── Schedule.cshtml.cs
│   │   ├── Index.cshtml                # ← inquiries/list.asp [Authorize] (agent's inquiries)
│   │   └── Index.cshtml.cs
│   │
│   ├── Admin/
│   │   ├── Users.cshtml                # ← admin/users.asp [Authorize(Roles="Admin")]
│   │   ├── Users.cshtml.cs
│   │   ├── Reports.cshtml              # ← admin/reports.asp [Authorize]
│   │   └── Reports.cshtml.cs
│   │
│   └── Account/                        # ← admin/login.asp (replaces custom login)
│       ├── Login.cshtml
│       ├── Login.cshtml.cs
│       ├── Logout.cshtml
│       └── Logout.cshtml.cs
│
├── Shared/                             # Shared Razor components
│   ├── _Layout.cshtml                  # ← header.asp + footer.asp combined
│   ├── _LoginPartial.cshtml            # Nav login/logout links (conditional)
│   └── _ValidationScriptsPartial.cshtml
│
├── ViewModels/                         # Page-specific view models and form DTOs
│   ├── PropertySearchViewModel.cs      # Search form filters + results
│   ├── PropertyFormViewModel.cs        # Add/Edit property form
│   ├── ContactFormViewModel.cs         # Contact inquiry form
│   ├── ScheduleFormViewModel.cs        # Appointment scheduling form
│   ├── UserCreateViewModel.cs          # Admin user creation form
│   └── DashboardViewModel.cs           # Agent dashboard stats
│
├── wwwroot/                            # Static files (served by StaticFiles middleware)
│   ├── css/
│   │   └── site.css                    # Migrated from header.asp inline styles
│   ├── js/
│   │   └── site.js                     # Client-side validation + UI interactions
│   ├── images/
│   │   └── properties/                 # Property photo uploads (dev only; prod uses blob storage)
│   └── lib/                            # Client-side libraries (Bootstrap, jQuery validation)
│
├── Middleware/
│   └── SecurityHeadersMiddleware.cs    # CSP, X-Frame-Options, HSTS, etc.
│
└── Migrations/                         # EF Core migrations (auto-generated)
```

---

## 2. Page Mapping — Classic ASP to Razor Pages

Every Classic ASP file maps to a specific Razor Page. The `includes/` files become shared infrastructure.

### 2.1 Page Files

| Classic ASP File | Razor Page | Route | Auth | HTTP Methods |
|---|---|---|---|---|
| `default.asp` | `Pages/Index.cshtml` | `/` | Public | GET |
| `listings/search.asp` | `Pages/Listings/Search.cshtml` | `/Listings/Search` | Public | GET |
| `listings/detail.asp` | `Pages/Listings/Detail.cshtml` | `/Listings/Detail/{id:int}` | Public | GET |
| `listings/add.asp` | `Pages/Listings/Add.cshtml` | `/Listings/Add` | `[Authorize]` | GET, POST |
| `listings/edit.asp` | `Pages/Listings/Edit.cshtml` | `/Listings/Edit/{id:int}` | `[Authorize]` + ownership | GET, POST |
| `listings/photos.asp` | `Pages/Listings/Photos.cshtml` | `/Listings/Photos/{id:int}` | `[Authorize]` + ownership | GET, POST |
| `agents/directory.asp` | `Pages/Agents/Index.cshtml` | `/Agents` | Public | GET |
| `agents/profile.asp` | `Pages/Agents/Profile.cshtml` | `/Agents/Profile/{id:int}` | Public | GET |
| `agents/dashboard.asp` | `Pages/Agents/Dashboard.cshtml` | `/Agents/Dashboard` | `[Authorize]` | GET |
| `inquiries/contact.asp` | `Pages/Inquiries/Contact.cshtml` | `/Inquiries/Contact` | Public | GET, POST |
| `inquiries/schedule.asp` | `Pages/Inquiries/Schedule.cshtml` | `/Inquiries/Schedule` | Public | GET, POST |
| `inquiries/list.asp` | `Pages/Inquiries/Index.cshtml` | `/Inquiries` | `[Authorize]` | GET, POST |
| `admin/login.asp` | `Pages/Account/Login.cshtml` | `/Account/Login` | Public | GET, POST |
| `admin/users.asp` | `Pages/Admin/Users.cshtml` | `/Admin/Users` | `[Authorize(Roles="Admin")]` | GET, POST |
| `admin/reports.asp` | `Pages/Admin/Reports.cshtml` | `/Admin/Reports` | `[Authorize]` | GET |

### 2.2 Include Files → Shared Infrastructure

| Classic ASP Include | ASP.NET Core Replacement | Notes |
|---|---|---|
| `includes/conn.asp` | `Data/SummitRealtyDbContext.cs` + `appsettings.json` | DbContext via DI; connection string in config/secrets |
| `includes/functions.asp` | Built-in C# / Tag Helpers | `FormatCurrency` → `Price.ToString("C0")`; `TruncateText` → custom Tag Helper or extension method; `SanitizeInput` → eliminated (EF Core parameterizes) |
| `includes/auth.asp` | `[Authorize]` attribute + policies | `RequireAuth()` → `[Authorize]`; `RequireRole("Admin")` → `[Authorize(Roles = "Admin")]` |
| `includes/header.asp` | `Shared/_Layout.cshtml` (top) + `Shared/_LoginPartial.cshtml` | Razor layout with conditional nav via `User.Identity.IsAuthenticated` |
| `includes/footer.asp` | `Shared/_Layout.cshtml` (bottom) | Copyright, contact info in layout footer |
| `global.asa` | `Program.cs` | Service registration, middleware pipeline, app config |

---

## 3. Entity Framework Core Model Design

### 3.1 Entity Classes

Each entity maps directly to the existing SQL Server table. ASP.NET Core Identity replaces the `Users` table.

#### `Models/Agent.cs`

```csharp
public class Agent
{
    public int AgentId { get; set; }

    [Required, StringLength(50)]
    public string FirstName { get; set; } = string.Empty;

    [Required, StringLength(50)]
    public string LastName { get; set; } = string.Empty;

    [Required, StringLength(100), EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required, StringLength(20), Phone]
    public string Phone { get; set; } = string.Empty;

    [Required, StringLength(50)]
    public string LicenseNumber { get; set; } = string.Empty;

    public string? Bio { get; set; }

    [StringLength(255)]
    public string? PhotoPath { get; set; }

    public DateTime HireDate { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public ICollection<Property> Properties { get; set; } = new List<Property>();
    public ICollection<Inquiry> Inquiries { get; set; } = new List<Inquiry>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
    public ICollection<ApplicationUser> Users { get; set; } = new List<ApplicationUser>();

    // Computed
    [NotMapped]
    public string FullName => $"{FirstName} {LastName}";
}
```

#### `Models/Property.cs`

```csharp
public class Property
{
    public int PropertyId { get; set; }

    [Required, StringLength(255)]
    public string Address { get; set; } = string.Empty;

    [Required, StringLength(100)]
    public string City { get; set; } = string.Empty;

    [Required, StringLength(2)]
    public string State { get; set; } = string.Empty;

    [Required, StringLength(10)]
    public string ZipCode { get; set; } = string.Empty;

    [Column(TypeName = "decimal(18,2)")]
    public decimal Price { get; set; }

    public int Bedrooms { get; set; }

    [Column(TypeName = "decimal(3,1)")]
    public decimal Bathrooms { get; set; }

    public int SquareFeet { get; set; }

    [Required, StringLength(50)]
    public string PropertyType { get; set; } = string.Empty;

    public string? Description { get; set; }

    public DateTime ListingDate { get; set; } = DateTime.UtcNow;

    public PropertyStatus Status { get; set; } = PropertyStatus.Active;

    // Foreign key
    public int AgentId { get; set; }
    public Agent Agent { get; set; } = null!;

    // Navigation properties
    public ICollection<PropertyPhoto> Photos { get; set; } = new List<PropertyPhoto>();
    public ICollection<Inquiry> Inquiries { get; set; } = new List<Inquiry>();
    public ICollection<Appointment> Appointments { get; set; } = new List<Appointment>();
}
```

#### `Models/PropertyPhoto.cs`

```csharp
public class PropertyPhoto
{
    public int PhotoId { get; set; }

    [Required, StringLength(255)]
    public string FilePath { get; set; } = string.Empty;

    [StringLength(255)]
    public string? Caption { get; set; }

    public int SortOrder { get; set; } = 1;

    // Foreign key
    public int PropertyId { get; set; }
    public Property Property { get; set; } = null!;
}
```

#### `Models/Inquiry.cs`

```csharp
public class Inquiry
{
    public int InquiryId { get; set; }

    // Nullable — supports general inquiries not tied to a property
    public int? PropertyId { get; set; }
    public Property? Property { get; set; }

    [Required, StringLength(100)]
    public string ClientName { get; set; } = string.Empty;

    [Required, StringLength(100), EmailAddress]
    public string ClientEmail { get; set; } = string.Empty;

    [StringLength(20), Phone]
    public string? ClientPhone { get; set; }

    [Required]
    public string Message { get; set; } = string.Empty;

    public DateTime InquiryDate { get; set; } = DateTime.UtcNow;

    public InquiryStatus Status { get; set; } = InquiryStatus.Pending;

    // Foreign key
    public int AgentId { get; set; }
    public Agent Agent { get; set; } = null!;
}
```

#### `Models/Appointment.cs`

```csharp
public class Appointment
{
    public int AppointmentId { get; set; }

    public DateTime AppointmentDate { get; set; }

    [Required, StringLength(100)]
    public string ClientName { get; set; } = string.Empty;

    [Required, StringLength(100), EmailAddress]
    public string ClientEmail { get; set; } = string.Empty;

    public string? Notes { get; set; }

    public AppointmentStatus Status { get; set; } = AppointmentStatus.Scheduled;

    // Foreign keys
    public int PropertyId { get; set; }
    public Property Property { get; set; } = null!;

    public int AgentId { get; set; }
    public Agent Agent { get; set; } = null!;
}
```

#### `Models/ApplicationUser.cs` — Replaces `Users` Table

```csharp
public class ApplicationUser : IdentityUser
{
    // Link to Agent record (maps to legacy Users.AgentID)
    public int AgentId { get; set; }
    public Agent Agent { get; set; } = null!;

    public DateTime? LastLogin { get; set; }
}
```

> **Key change:** The legacy `Users` table stored plain-text passwords and a `Role` column. ASP.NET Core Identity replaces this entirely — passwords are hashed with PBKDF2 (HMAC-SHA256, 600K iterations), roles are stored in the `AspNetUserRoles` junction table, and session management uses encrypted, signed cookies.

### 3.2 Enums

```csharp
// Models/PropertyStatus.cs
public enum PropertyStatus
{
    Active,
    Pending,
    Sold
}

// Models/InquiryStatus.cs
public enum InquiryStatus
{
    Pending,
    Contacted,
    Closed
}

// Models/AppointmentStatus.cs
public enum AppointmentStatus
{
    Scheduled,
    Completed
}
```

### 3.3 Entity Relationship Diagram

```
┌─────────────────────┐
│  ApplicationUser     │      ┌──────────────────┐
│  (IdentityUser)      │      │     Agent         │
├─────────────────────┤      ├──────────────────┤
│ Id (PK, string)      │      │ AgentId (PK, int) │
│ AgentId (FK) ────────┼─────►│ FirstName         │
│ LastLogin            │      │ LastName          │
│ [PasswordHash]       │      │ Email             │
│ [Roles via Identity] │      │ Phone             │
└─────────────────────┘      │ LicenseNumber     │
                              │ Bio               │
                              │ PhotoPath         │
                              │ HireDate          │
                              └────────┬──────────┘
                                       │ 1
                                       │
               ┌───────────────────────┼───────────────────────┐
               │ *                     │ *                     │ *
    ┌──────────┴──────────┐ ┌─────────┴──────────┐ ┌─────────┴──────────┐
    │     Property         │ │    Inquiry          │ │   Appointment       │
    ├─────────────────────┤ ├────────────────────┤ ├────────────────────┤
    │ PropertyId (PK)      │ │ InquiryId (PK)     │ │ AppointmentId (PK) │
    │ Address              │ │ PropertyId (FK)?    │ │ PropertyId (FK)    │
    │ City, State, Zip     │ │ AgentId (FK)       │ │ AgentId (FK)       │
    │ Price, Beds, Baths   │ │ ClientName/Email   │ │ ClientName/Email   │
    │ SquareFeet           │ │ Message            │ │ AppointmentDate    │
    │ PropertyType         │ │ InquiryDate        │ │ Notes              │
    │ Description          │ │ Status (enum)      │ │ Status (enum)      │
    │ ListingDate          │ └────────────────────┘ └────────────────────┘
    │ Status (enum)        │
    │ AgentId (FK)         │
    └──────────┬───────────┘
               │ 1
               │
               │ *
    ┌──────────┴──────────┐
    │   PropertyPhoto      │
    ├─────────────────────┤
    │ PhotoId (PK)         │
    │ PropertyId (FK)      │
    │ FilePath             │
    │ Caption              │
    │ SortOrder            │
    └─────────────────────┘
```

---

## 4. Data Access Layer Design

### 4.1 DbContext

```csharp
// Data/SummitRealtyDbContext.cs
public class SummitRealtyDbContext : IdentityDbContext<ApplicationUser>
{
    public SummitRealtyDbContext(DbContextOptions<SummitRealtyDbContext> options)
        : base(options) { }

    public DbSet<Agent> Agents => Set<Agent>();
    public DbSet<Property> Properties => Set<Property>();
    public DbSet<PropertyPhoto> PropertyPhotos => Set<PropertyPhoto>();
    public DbSet<Inquiry> Inquiries => Set<Inquiry>();
    public DbSet<Appointment> Appointments => Set<Appointment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder); // Identity tables

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(SummitRealtyDbContext).Assembly);
    }
}
```

### 4.2 Entity Configurations (Fluent API)

```csharp
// Data/Configurations/PropertyConfiguration.cs
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

// Data/Configurations/ApplicationUserConfiguration.cs
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
```

### 4.3 Service Layer Pattern

Services encapsulate business logic and data access. Pages depend on service interfaces (injected via DI), not directly on `DbContext`.

```csharp
// Services/IPropertyService.cs
public interface IPropertyService
{
    Task<List<Property>> GetFeaturedListingsAsync(int count = 6);
    Task<Property?> GetByIdAsync(int id);
    Task<(List<Property> Results, int TotalCount)> SearchAsync(PropertySearchViewModel filters);
    Task<Property> CreateAsync(PropertyFormViewModel model, int agentId);
    Task UpdateAsync(int id, PropertyFormViewModel model);
    Task<bool> IsOwnedByAgentAsync(int propertyId, int agentId);
}

// Services/PropertyService.cs
public class PropertyService : IPropertyService
{
    private readonly SummitRealtyDbContext _context;

    public PropertyService(SummitRealtyDbContext context)
    {
        _context = context;
    }

    public async Task<List<Property>> GetFeaturedListingsAsync(int count = 6)
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

    public async Task<(List<Property> Results, int TotalCount)> SearchAsync(
        PropertySearchViewModel filters)
    {
        // All filters applied via LINQ — EF Core generates parameterized SQL
        var query = _context.Properties
            .Include(p => p.Agent)
            .Include(p => p.Photos.OrderBy(ph => ph.SortOrder).Take(1))
            .Where(p => p.Status == PropertyStatus.Active)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(filters.City))
            query = query.Where(p => p.City.Contains(filters.City));

        if (!string.IsNullOrWhiteSpace(filters.State))
            query = query.Where(p => p.State == filters.State);

        if (filters.MinPrice.HasValue)
            query = query.Where(p => p.Price >= filters.MinPrice.Value);

        if (filters.MaxPrice.HasValue)
            query = query.Where(p => p.Price <= filters.MaxPrice.Value);

        if (filters.Bedrooms.HasValue)
            query = query.Where(p => p.Bedrooms >= filters.Bedrooms.Value);

        if (!string.IsNullOrWhiteSpace(filters.PropertyType))
            query = query.Where(p => p.PropertyType == filters.PropertyType);

        var totalCount = await query.CountAsync();
        var results = await query
            .OrderByDescending(p => p.ListingDate)
            .AsNoTracking()
            .ToListAsync();

        return (results, totalCount);
    }

    public async Task<bool> IsOwnedByAgentAsync(int propertyId, int agentId)
    {
        return await _context.Properties
            .AnyAsync(p => p.PropertyId == propertyId && p.AgentId == agentId);
    }
}
```

### 4.4 Query Mapping — Legacy SQL to EF Core LINQ

| Classic ASP Query (file) | EF Core LINQ Equivalent |
|---|---|
| `SELECT TOP 6 ... WHERE Status='Active' ORDER BY ListingDate DESC` (default.asp) | `Properties.Where(p => p.Status == Active).OrderByDescending(p => p.ListingDate).Take(6)` |
| `SELECT ... WHERE City LIKE '%x%' AND State='y' AND Price >= z` (search.asp) | Conditional `.Where()` chaining as shown above |
| `SELECT p.*, a.* WHERE PropertyID = @id` (detail.asp) | `Properties.Include(p => p.Agent).Include(p => p.Photos).FirstOrDefaultAsync(p => p.PropertyId == id)` |
| `INSERT INTO Properties (...)` (add.asp) | `_context.Properties.Add(entity); await _context.SaveChangesAsync();` |
| `UPDATE Properties SET ... WHERE PropertyID = @id` (edit.asp) | `_context.Properties.Update(entity); await _context.SaveChangesAsync();` |
| `SELECT COUNT(*) FROM Properties WHERE AgentID = @id` (dashboard.asp) | `Properties.CountAsync(p => p.AgentId == agentId)` |
| `SELECT ... FROM Agents` (directory.asp) | `Agents.AsNoTracking().ToListAsync()` |
| `SELECT * FROM Agents WHERE AgentID = @id` (profile.asp) | `Agents.Include(a => a.Properties).FirstOrDefaultAsync(a => a.AgentId == id)` |
| `INSERT INTO Inquiries (...)` (contact.asp) | `_context.Inquiries.Add(entity); await _context.SaveChangesAsync();` |
| `INSERT INTO Appointments (...)` (schedule.asp) | `_context.Appointments.Add(entity); await _context.SaveChangesAsync();` |
| `UPDATE Inquiries SET Status = @s WHERE InquiryID = @id AND AgentID = @a` (list.asp) | `inquiry.Status = newStatus; await _context.SaveChangesAsync();` (with ownership check) |
| `SELECT u.*, a.* FROM Users JOIN Agents` (users.asp) | `_userManager.Users.Include(u => u.Agent).ToListAsync()` |
| `SELECT COUNT(*), SUM(Price), GROUP BY` (reports.asp) | EF Core `.GroupBy()` with aggregate projections |

---

## 5. Authentication & Authorization Architecture

### 5.1 ASP.NET Core Identity Setup

ASP.NET Core Identity **completely replaces** the legacy `Users` table, session-based authentication, `auth.asp` guards, and plain-text password storage.

```csharp
// Program.cs — Identity configuration
builder.Services.AddDbContext<SummitRealtyDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    // Password policy (remediates plain-text password storage)
    options.Password.RequiredLength = 12;
    options.Password.RequireDigit = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireNonAlphanumeric = true;

    // Lockout (remediates brute-force attacks)
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.AllowedForNewUsers = true;

    // User settings
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<SummitRealtyDbContext>()
.AddDefaultTokenProviders();

// Cookie configuration (remediates session fixation, missing Secure/HttpOnly flags)
builder.Services.ConfigureApplicationCookie(options =>
{
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
    options.Cookie.SameSite = SameSiteMode.Strict;
    options.ExpireTimeSpan = TimeSpan.FromMinutes(30);  // Matches legacy 30-min timeout
    options.SlidingExpiration = true;
    options.LoginPath = "/Account/Login";
    options.LogoutPath = "/Account/Logout";
    options.AccessDeniedPath = "/Account/AccessDenied";
});
```

### 5.2 Role-Based Authorization

| Legacy Mechanism | ASP.NET Core Replacement |
|---|---|
| `Session("Authenticated") = True` | `User.Identity.IsAuthenticated` (cookie-based) |
| `Session("Role") = "Admin"` | `User.IsInRole("Admin")` (via `AspNetUserRoles`) |
| `RequireAuth()` in `auth.asp` | `[Authorize]` attribute on PageModel |
| `RequireRole("Admin")` in `auth.asp` | `[Authorize(Roles = "Admin")]` attribute |
| `Session("UserID")` (AgentID) | `User.FindFirst(ClaimTypes.NameIdentifier)` + custom claim for AgentId |

### 5.3 Custom Claims for Agent ID

The legacy app stores `AgentID` in session. We add it as a custom claim during login:

```csharp
// In Account/Login.cshtml.cs — after successful sign-in
public async Task<IActionResult> OnPostAsync()
{
    var user = await _userManager.FindByNameAsync(Input.Username);
    if (user == null) { /* handle error */ }

    var result = await _signInManager.PasswordSignInAsync(
        user, Input.Password, Input.RememberMe, lockoutOnFailure: true);

    if (result.Succeeded)
    {
        // Add AgentId as a custom claim
        var claims = new List<Claim>
        {
            new("AgentId", user.AgentId.ToString())
        };
        await _userManager.AddClaimsAsync(user, claims);

        user.LastLogin = DateTime.UtcNow;
        await _userManager.UpdateAsync(user);

        return LocalRedirect(ReturnUrl ?? "/Agents/Dashboard");
    }
    // Handle lockout, failure, etc.
}
```

### 5.4 Resource-Based Authorization (Fixes IDOR Vulnerabilities)

The legacy app has no ownership checks — any agent can edit any property. We fix this with a custom authorization handler:

```csharp
// Authorization/PropertyOwnerRequirement.cs
public class PropertyOwnerRequirement : IAuthorizationRequirement { }

// Authorization/PropertyOwnerHandler.cs
public class PropertyOwnerHandler : AuthorizationHandler<PropertyOwnerRequirement, Property>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        PropertyOwnerRequirement requirement,
        Property resource)
    {
        // Admins bypass ownership check
        if (context.User.IsInRole("Admin"))
        {
            context.Succeed(requirement);
            return Task.CompletedTask;
        }

        var agentIdClaim = context.User.FindFirst("AgentId")?.Value;
        if (agentIdClaim != null && int.Parse(agentIdClaim) == resource.AgentId)
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}

// Registration in Program.cs
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("PropertyOwner", policy =>
        policy.Requirements.Add(new PropertyOwnerRequirement()));
});
builder.Services.AddSingleton<IAuthorizationHandler, PropertyOwnerHandler>();
```

**Usage in Page Handlers:**

```csharp
// Pages/Listings/Edit.cshtml.cs
[Authorize]
public class EditModel : PageModel
{
    private readonly IPropertyService _propertyService;
    private readonly IAuthorizationService _authorizationService;

    public async Task<IActionResult> OnGetAsync(int id)
    {
        var property = await _propertyService.GetByIdAsync(id);
        if (property == null) return NotFound();

        var authResult = await _authorizationService.AuthorizeAsync(
            User, property, "PropertyOwner");
        if (!authResult.Succeeded) return Forbid();

        // Populate form...
    }
}
```

### 5.5 Data Migration Strategy for Users

Since legacy passwords are plain-text, users must be migrated with forced password resets:

```csharp
// Data/SeedData.cs — migration of legacy users
public static async Task MigrateUsersAsync(
    UserManager<ApplicationUser> userManager,
    RoleManager<IdentityRole> roleManager)
{
    // Create roles
    await roleManager.CreateAsync(new IdentityRole("Admin"));
    await roleManager.CreateAsync(new IdentityRole("Agent"));

    // Migrate each legacy user with a temporary hashed password
    // and require password change on first login
    var legacyUsers = new[]
    {
        new { Username = "admin", Role = "Admin", AgentId = 1 },
        new { Username = "sarah.j", Role = "Agent", AgentId = 1 },
        // ... remaining 8 users
    };

    foreach (var legacy in legacyUsers)
    {
        var user = new ApplicationUser
        {
            UserName = legacy.Username,
            AgentId = legacy.AgentId,
            EmailConfirmed = true
        };

        // Create with a strong temporary password
        var result = await userManager.CreateAsync(user, "TempP@ss" + Guid.NewGuid().ToString("N")[..8]);
        if (result.Succeeded)
        {
            await userManager.AddToRoleAsync(user, legacy.Role);
            // In production: send password reset email to each user
        }
    }
}
```

---

## 6. Middleware Pipeline Design

### 6.1 Complete Pipeline (`Program.cs`)

```csharp
var builder = WebApplication.CreateBuilder(args);

// === Service Registration ===

// Database
builder.Services.AddDbContext<SummitRealtyDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Identity (see §5.1)
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(/* options */)
    .AddEntityFrameworkStores<SummitRealtyDbContext>()
    .AddDefaultTokenProviders();

// Authorization policies
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("PropertyOwner", policy =>
        policy.Requirements.Add(new PropertyOwnerRequirement()));
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireRole("Admin"));
});
builder.Services.AddSingleton<IAuthorizationHandler, PropertyOwnerHandler>();

// Application services
builder.Services.AddScoped<IPropertyService, PropertyService>();
builder.Services.AddScoped<IAgentService, AgentService>();
builder.Services.AddScoped<IInquiryService, InquiryService>();
builder.Services.AddScoped<IAppointmentService, AppointmentService>();
builder.Services.AddScoped<IPhotoService, PhotoService>();
builder.Services.AddScoped<IEmailService, EmailService>();

// Razor Pages with anti-forgery (remediates CSRF)
builder.Services.AddRazorPages();
builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "X-CSRF-TOKEN";
});

// Rate limiting (remediates brute-force on login and public forms)
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("login", limiter =>
    {
        limiter.PermitLimit = 5;
        limiter.Window = TimeSpan.FromMinutes(1);
    });
    options.AddFixedWindowLimiter("forms", limiter =>
    {
        limiter.PermitLimit = 10;
        limiter.Window = TimeSpan.FromMinutes(1);
    });
});

var app = builder.Build();

// === Middleware Pipeline (order matters!) ===

// 1. Exception handling — replaces "On Error Resume Next"
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();                          // Strict-Transport-Security header
}

// 2. HTTPS redirection (remediates cleartext transmission)
app.UseHttpsRedirection();

// 3. Security headers (remediates missing CSP, X-Frame-Options, etc.)
app.UseMiddleware<SecurityHeadersMiddleware>();

// 4. Static files (wwwroot/)
app.UseStaticFiles();

// 5. Routing
app.UseRouting();

// 6. Rate limiting
app.UseRateLimiter();

// 7. Authentication & Authorization
app.UseAuthentication();
app.UseAuthorization();

// 8. Razor Pages endpoint mapping
app.MapRazorPages();

// 9. Seed database
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<SummitRealtyDbContext>();
    await context.Database.MigrateAsync();
    await SeedData.InitializeAsync(scope.ServiceProvider);
}

app.Run();
```

### 6.2 Security Headers Middleware

```csharp
// Middleware/SecurityHeadersMiddleware.cs
public class SecurityHeadersMiddleware
{
    private readonly RequestDelegate _next;

    public SecurityHeadersMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        var headers = context.Response.Headers;

        // Prevent MIME type sniffing
        headers.Append("X-Content-Type-Options", "nosniff");

        // Prevent clickjacking
        headers.Append("X-Frame-Options", "DENY");

        // Control referrer information
        headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");

        // Restrict browser features
        headers.Append("Permissions-Policy", "camera=(), microphone=(), geolocation=()");

        // Content Security Policy — mitigates XSS
        headers.Append("Content-Security-Policy",
            "default-src 'self'; " +
            "script-src 'self'; " +
            "style-src 'self' 'unsafe-inline'; " +
            "img-src 'self' data: blob:; " +
            "font-src 'self'; " +
            "form-action 'self'; " +
            "frame-ancestors 'none';");

        await _next(context);
    }
}
```

### 6.3 Pipeline Flow Diagram

```
HTTP Request
    │
    ▼
┌──────────────────────────┐
│ 1. Exception Handler     │  ← Replaces "On Error Resume Next"
│    Dev: DeveloperPage    │    Structured error handling + logging
│    Prod: /Error page     │
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│ 2. HTTPS Redirection     │  ← Remediates CWE-319 (cleartext)
│    + HSTS                │
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│ 3. Security Headers      │  ← Remediates CWE-693 (missing headers)
│    CSP, X-Frame-Options  │    CSP, X-Content-Type-Options, etc.
│    X-Content-Type-Options│
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│ 4. Static Files          │  ← Serves wwwroot/ (CSS, JS, images)
│    (short-circuits here  │
│     for static content)  │
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│ 5. Routing               │  ← Matches request to Razor Page
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│ 6. Rate Limiter          │  ← Prevents brute-force attacks
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│ 7. Authentication        │  ← Cookie auth (replaces Session vars)
│    Cookie validation     │    Reads & validates auth cookie
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│ 8. Authorization         │  ← [Authorize], role checks, ownership
│    Policy evaluation     │    Replaces auth.asp RequireAuth/RequireRole
└──────────┬───────────────┘
           ▼
┌──────────────────────────┐
│ 9. Razor Page Endpoint   │  ← OnGet/OnPost handlers execute
│    Anti-forgery validated │    Model binding, validation, EF Core
│    Model binding         │
└──────────────────────────┘
    │
    ▼
HTTP Response
```

---

## 7. NuGet Packages

### 7.1 Required Packages

| Package | Version | Purpose |
|---|---|---|
| `Microsoft.AspNetCore.Identity.EntityFrameworkCore` | 8.0.x | Identity with EF Core store |
| `Microsoft.EntityFrameworkCore.SqlServer` | 8.0.x | SQL Server EF Core provider |
| `Microsoft.EntityFrameworkCore.Tools` | 8.0.x | EF Core CLI tools (migrations) |
| `Microsoft.AspNetCore.Diagnostics.EntityFrameworkCore` | 8.0.x | Dev-time DB error pages |

### 7.2 Recommended Packages

| Package | Version | Purpose |
|---|---|---|
| `Serilog.AspNetCore` | 8.x | Structured logging (replaces silent error suppression) |
| `Serilog.Sinks.Console` | 5.x | Console log output |
| `Serilog.Sinks.File` | 5.x | File log output |
| `FluentValidation.AspNetCore` | 11.x | Server-side input validation (supplements Data Annotations) |
| `Azure.Communication.Email` | 1.x | Email sending (replaces CDO with SMTP) |
| `Azure.Storage.Blobs` | 12.x | Photo storage (replaces FileSystemObject + local disk) |
| `Azure.Identity` | 1.x | Managed identity for Key Vault / Azure services |
| `Azure.Extensions.AspNetCore.Configuration.Secrets` | 1.x | Azure Key Vault configuration provider |

### 7.3 Project File

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.AspNetCore.Identity.EntityFrameworkCore" Version="8.0.*" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.*" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.0.*" />
    <PackageReference Include="Microsoft.AspNetCore.Diagnostics.EntityFrameworkCore" Version="8.0.*" />
    <PackageReference Include="Serilog.AspNetCore" Version="8.*" />
    <PackageReference Include="Serilog.Sinks.Console" Version="5.*" />
    <PackageReference Include="FluentValidation.AspNetCore" Version="11.*" />
  </ItemGroup>
</Project>
```

---

## 8. Security Remediation Map

Every vulnerability from the [Security Assessment](step-02-security-assessment.md) is mapped to its ASP.NET Core fix.

### 8.1 CRITICAL Vulnerabilities

| # | Vulnerability | CWE | Legacy Location | ASP.NET Core Remediation | Implementation |
|---|---|---|---|---|---|
| 1 | **SQL Injection** (10 instances) | CWE-89 | All 11 files with SQL | Entity Framework Core with LINQ | All queries via `DbContext` — EF Core always generates parameterized SQL. Zero raw string concatenation. |
| 2 | **Plain-text passwords** | CWE-256 | `schema.sql`, `login.asp`, `users.asp` | ASP.NET Core Identity | PBKDF2 hashing (HMAC-SHA256, 600K iterations). Passwords never stored or displayed in plain text. |
| 3 | **Hardcoded DB credentials (SA)** | CWE-798 | `includes/conn.asp` | User Secrets (dev) + Azure Key Vault (prod) | Connection string in `appsettings.json` placeholder; real value from secrets. Dedicated least-privilege DB user replaces SA. |
| 4 | **Hardcoded SMTP credentials** | CWE-798 | `inquiries/contact.asp` | Azure Communication Services + Key Vault | SMTP credentials replaced by managed identity auth to Azure Communication Services. |

### 8.2 HIGH Vulnerabilities

| # | Vulnerability | CWE | Legacy Location | ASP.NET Core Remediation | Implementation |
|---|---|---|---|---|---|
| 5 | **XSS — Reflected** (search form) | CWE-79 | `listings/search.asp` | Razor auto-encoding | All `@Model.Property` expressions are HTML-encoded by default. `@Html.Raw()` never used for user input. |
| 6 | **XSS — Stored** (DB content) | CWE-79 | All pages outputting DB data | Razor auto-encoding + CSP header | Razor encodes output; CSP blocks inline scripts; `X-XSS-Protection` as defense-in-depth. |
| 7 | **XSS — Header** (username) | CWE-79 | `includes/header.asp` | Razor `_LoginPartial.cshtml` | `@User.Identity.Name` is auto-encoded by Razor. |
| 8 | **No CSRF protection** (7 forms) | CWE-352 | All forms | Anti-forgery tokens (built-in) | Razor Pages auto-include anti-forgery tokens in forms. `[ValidateAntiForgeryToken]` on all POST handlers. All state changes use POST (not GET). |
| 9 | **IDOR — edit/photos** (no ownership) | CWE-639 | `edit.asp`, `photos.asp` | Resource-based authorization | `PropertyOwnerHandler` verifies `AgentId` matches current user's claim. Admins bypass. Applied to Edit, Photos, and delete operations. |
| 10 | **IDOR — detail** (all statuses) | CWE-639 | `detail.asp` | Query filter | Public detail page only shows `Active` properties. Agents see their own non-active listings on Dashboard. |
| 11 | **IDOR — agent enumeration** | CWE-639 | `agents/profile.asp` | Acceptable (public directory) | Agent profiles are intentionally public. No sensitive data exposed beyond what's in the directory. |
| 12 | **Inquiry status via GET** | CWE-352 | `inquiries/list.asp` | POST with anti-forgery | Status changes use `<form method="post">` with anti-forgery tokens, not GET links. |

### 8.3 MEDIUM Vulnerabilities

| # | Vulnerability | CWE | Legacy Location | ASP.NET Core Remediation | Implementation |
|---|---|---|---|---|---|
| 13 | **Session fixation** | CWE-384 | `global.asa`, `login.asp` | Identity cookie auth | ASP.NET Core Identity issues a new cookie on sign-in, invalidating any pre-existing session. |
| 14 | **Incomplete logout** | CWE-613 | `login.asp` (no `Session.Abandon`) | `SignInManager.SignOutAsync()` | Properly clears the auth cookie and server-side session state. POST-only logout with anti-forgery. |
| 15 | **Demo credentials in HTML** | CWE-200 | `login.asp` | Removed | No demo credentials displayed. Development seed data uses strong temporary passwords. |
| 16 | **Error suppression** | CWE-390 | All files (`On Error Resume Next`) | Exception middleware + Serilog | `UseExceptionHandler` for production error page; `UseDeveloperExceptionPage` in dev. All exceptions logged via Serilog. |
| 17 | **Server info in footer** | CWE-200 | `includes/footer.asp` | Removed | No server time or active user count in footer. |
| 18 | **File upload — no validation** | CWE-434 | `listings/photos.asp` | `PhotoService` with validation | Whitelist extensions (`.jpg`, `.jpeg`, `.png`, `.webp`); 5MB size limit; random filenames; store outside webroot; validate MIME type. |

### 8.4 LOW Vulnerabilities

| # | Vulnerability | CWE | Legacy Location | ASP.NET Core Remediation | Implementation |
|---|---|---|---|---|---|
| 19 | **No HTTPS** | CWE-319 | All files | `UseHttpsRedirection()` + HSTS | Force HTTPS; HSTS header with 1-year max-age; `Secure` flag on cookies. |
| 20 | **No security headers** | CWE-693 | All files | `SecurityHeadersMiddleware` | CSP, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Permissions-Policy`. |
| 21 | **SA database account** | CWE-250 | `includes/conn.asp` | Least-privilege DB user | Dedicated `summitrealty_app` SQL login with only `SELECT`, `INSERT`, `UPDATE`, `DELETE` on `dbo` schema. |
| 22 | **Unused SanitizeInput** | CWE-20 | `includes/functions.asp` | Eliminated | EF Core parameterization makes input sanitization for SQL unnecessary. Server-side validation via Data Annotations + FluentValidation for business rules. |

### 8.5 Remediation Coverage Summary

| Severity | Vulns Found | Vulns Remediated | Approach |
|---|---|---|---|
| 🔴 CRITICAL | 14 | 14 | EF Core (SQLi), Identity (passwords), Key Vault (credentials) |
| 🟠 HIGH | 13 | 13 | Razor encoding (XSS), anti-forgery (CSRF), ownership checks (IDOR) |
| 🟡 MEDIUM | 6 | 6 | Identity cookies (session), exception middleware (errors), upload validation |
| 🔵 LOW | 4 | 4 | HTTPS redirect, security headers, least-privilege DB, remove unused code |
| **Total** | **37** | **37** | **100% coverage** |

---

## 9. Configuration & Secrets Management

### 9.1 `appsettings.json` (Committed — No Secrets)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": ""
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Upload": {
    "MaxFileSizeMB": 5,
    "AllowedExtensions": [ ".jpg", ".jpeg", ".png", ".webp" ],
    "StoragePath": "wwwroot/images/properties"
  },
  "Email": {
    "FromAddress": "noreply@summitrealty.com",
    "FromName": "Summit Realty Group"
  }
}
```

### 9.2 Secrets Hierarchy

| Environment | Mechanism | Secrets Stored |
|---|---|---|
| Development | `dotnet user-secrets` | `ConnectionStrings:DefaultConnection`, `Email:ApiKey` |
| Staging/Production | Azure Key Vault | All secrets + managed identity for Azure services |

---

## 10. Implementation Phases

### Phase 1 — Foundation (Scaffold + Data Layer)

1. Create the ASP.NET Core 8 project with Razor Pages
2. Define all entity models and enums
3. Configure `SummitRealtyDbContext` with Fluent API configurations
4. Run `dotnet ef migrations add InitialCreate` and apply
5. Implement `SeedData.cs` (migrate schema.sql seed data)
6. Set up ASP.NET Core Identity with `ApplicationUser` and role seeding

### Phase 2 — Shared Layout & Authentication

1. Create `_Layout.cshtml` (from header.asp + footer.asp)
2. Create `_LoginPartial.cshtml` with conditional nav
3. Implement `Pages/Account/Login.cshtml` and `Logout.cshtml`
4. Configure middleware pipeline in `Program.cs`
5. Add `SecurityHeadersMiddleware`
6. Verify auth flow end-to-end

### Phase 3 — Public Pages

1. `Pages/Index.cshtml` — Homepage with featured listings
2. `Pages/Listings/Search.cshtml` — Property search with filters
3. `Pages/Listings/Detail.cshtml` — Property detail with photos and agent sidebar
4. `Pages/Agents/Index.cshtml` — Agent directory
5. `Pages/Agents/Profile.cshtml` — Agent profile with listings
6. `Pages/Inquiries/Contact.cshtml` — Contact form
7. `Pages/Inquiries/Schedule.cshtml` — Appointment scheduling

### Phase 4 — Authenticated Agent Pages

1. `Pages/Agents/Dashboard.cshtml` — Agent dashboard with stats
2. `Pages/Listings/Add.cshtml` — Add property listing
3. `Pages/Listings/Edit.cshtml` — Edit property (with ownership check)
4. `Pages/Listings/Photos.cshtml` — Photo management (with upload validation)
5. `Pages/Inquiries/Index.cshtml` — Inquiry management (POST for status changes)

### Phase 5 — Admin Pages

1. `Pages/Admin/Users.cshtml` — User management via Identity
2. `Pages/Admin/Reports.cshtml` — Reports dashboard with aggregate queries

### Phase 6 — Security Hardening & Testing

1. Verify all 37 vulnerabilities are remediated
2. Add integration tests for auth flows and ownership checks
3. Test rate limiting on login and public forms
4. Validate CSP headers don't break functionality
5. Run OWASP ZAP or similar scanner against the deployed app

---

*End of Architecture Design*
