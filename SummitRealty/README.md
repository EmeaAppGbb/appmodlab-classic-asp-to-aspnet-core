# Summit Realty Group - Classic ASP Application

This is a legacy Classic ASP 3.0 application built with VBScript and ADO for the "Classic ASP to ASP.NET Core" modernization lab.

## Overview

Summit Realty Group is a real estate portal featuring property listings, agent profiles, client inquiries, and appointment scheduling. This application demonstrates typical early-2000s Classic ASP development patterns and anti-patterns.

## Technology Stack

- **Classic ASP 3.0** with VBScript
- **ADO 2.8** (ActiveX Data Objects) with inline SQL queries
- **SQL Server 2012 Express** database
- **IIS 6/7** style configuration
- **Server-side includes (SSI)** for code reuse
- **CDO** (Collaboration Data Objects) for email
- **FileSystemObject** for file uploads
- **Session-based authentication** (no modern token-based auth)
- **Table-based HTML layout** with inline CSS

## Features

### Public Pages
- **Homepage** (`default.asp`) - Featured property listings
- **Property Search** (`listings/search.asp`) - Search with filters
- **Property Details** (`listings/detail.asp`) - Full property information
- **Agent Directory** (`agents/directory.asp`) - Browse all agents
- **Agent Profile** (`agents/profile.asp`) - Individual agent page
- **Contact Form** (`inquiries/contact.asp`) - Submit inquiries
- **Schedule Viewing** (`inquiries/schedule.asp`) - Book appointments

### Agent/Admin Pages (Requires Login)
- **Login** (`admin/login.asp`) - Session-based authentication
- **Dashboard** (`agents/dashboard.asp`) - Agent statistics and listings
- **Add Listing** (`listings/add.asp`) - Create new property
- **Edit Listing** (`listings/edit.asp`) - Update existing property
- **Manage Photos** (`listings/photos.asp`) - Upload property photos
- **Inquiry Management** (`inquiries/list.asp`) - View and respond to inquiries
- **User Management** (`admin/users.asp`) - Manage user accounts (Admin only)
- **Reports** (`admin/reports.asp`) - Analytics and statistics

## Database Schema

Tables:
- **Agents** - Real estate agent profiles
- **Properties** - Property listings
- **Users** - Login credentials (plain text passwords!)
- **Inquiries** - Client inquiries
- **Appointments** - Scheduled viewings
- **PropertyPhotos** - Property images

## Legacy Anti-Patterns Present

⚠️ **This application intentionally contains security vulnerabilities for educational purposes:**

1. **SQL Injection** - String concatenation in queries (no parameterization)
2. **Plain Text Passwords** - Stored unencrypted in database
3. **Session-based Auth** - No token-based authentication, no CSRF protection
4. **Inline SQL** - No data access layer, queries embedded in pages
5. **Server-side Includes** - Only code reuse mechanism
6. **FileSystemObject** - No file validation or size limits
7. **CDO with Hardcoded Credentials** - Email credentials in code
8. **No Input Sanitization** - QueryString parameters used directly
9. **Global Error Suppression** - "On Error Resume Next" everywhere
10. **Table-based Layout** - Non-semantic HTML with inline styles

## Setup Instructions

### Prerequisites
- IIS with Classic ASP support enabled
- SQL Server 2012 Express or later
- Windows Server or Windows 10/11 with IIS features

### Database Setup
1. Open SQL Server Management Studio
2. Connect to your SQL Server instance
3. Run `database\schema.sql` to create database and seed data
4. Update connection string in `includes\conn.asp` with your SQL Server details

### IIS Configuration
1. Create a new website or virtual directory in IIS
2. Point to the `SummitRealty` folder
3. Ensure Classic ASP is enabled in IIS Features
4. Set application pool to "Classic .NET AppPool"
5. Grant appropriate permissions to IIS user

### Test Credentials
```
Username: admin
Password: password123

Username: sarah.j
Password: welcome1
```

## Sample Data

The database includes:
- **10 Agents** - Diverse team of real estate professionals
- **55 Properties** - Variety of homes across multiple states and price ranges
- **10 Users** - Agent and admin accounts (all with plain text passwords)
- **20 Inquiries** - Sample client inquiries
- **15 Appointments** - Scheduled property viewings

## File Structure

```
SummitRealty/
├── default.asp                 # Homepage
├── global.asa                  # Application/Session events
├── includes/
│   ├── conn.asp               # Database connection (hardcoded)
│   ├── header.asp             # HTML header with navigation
│   ├── footer.asp             # HTML footer
│   ├── functions.asp          # Utility functions
│   └── auth.asp               # Session-based authentication
├── listings/
│   ├── search.asp             # Property search
│   ├── detail.asp             # Property details
│   ├── add.asp                # Add listing (agent)
│   ├── edit.asp               # Edit listing (agent)
│   └── photos.asp             # Photo upload
├── agents/
│   ├── directory.asp          # Agent listing
│   ├── profile.asp            # Agent profile
│   └── dashboard.asp          # Agent dashboard
├── inquiries/
│   ├── contact.asp            # Contact form
│   ├── schedule.asp           # Appointment scheduling
│   └── list.asp               # Inquiry management (agent)
├── admin/
│   ├── login.asp              # Login page
│   ├── users.asp              # User management
│   └── reports.asp            # Reporting
├── images/                     # Property and agent photos
├── css/                        # Stylesheets (minimal)
└── database/
    └── schema.sql             # Database creation script
```

## Known Issues (By Design)

These are intentional legacy patterns for the modernization lab:

- SQL injection vulnerabilities in all database queries
- Passwords stored in plain text
- No CSRF protection on forms
- No input validation or sanitization
- Session fixation vulnerabilities
- Insecure file upload handling
- Hardcoded SMTP credentials
- No error handling (errors suppressed globally)
- Non-responsive table-based layout
- No separation of concerns (mixing HTML, VBScript, and SQL)

## Modernization Target

This application will be migrated to:
- **ASP.NET Core 9** with Razor Pages
- **Entity Framework Core 9** with LINQ
- **ASP.NET Core Identity** for authentication
- **Azure Blob Storage** for file uploads
- **Azure Communication Services** for email
- **Bootstrap 5** responsive design
- **Parameterized queries** and input validation
- **HTTPS, CSRF protection**, and security best practices

---

**⚠️ WARNING: This is a demonstration application for educational purposes only. Do NOT use this code in production. It contains known security vulnerabilities.**
