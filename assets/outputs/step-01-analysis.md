# Summit Realty Group — Classic ASP Application Analysis

> **Purpose:** Comprehensive analysis of the legacy Classic ASP real estate application to drive the modernization effort to ASP.NET Core 9.

---

## 1. Complete File Inventory

### Root Files

| File | Purpose |
|------|---------|
| `default.asp` | **Homepage** — displays 6 most recent active property listings in a 3-column grid with photos, price, agent name, and "View Details" links. |
| `global.asa` | **Application/Session lifecycle** — initializes `Application` variables (AppName, Version, StartTime, ActiveUsers counter) and `Session` variables (Authenticated, UserID, Username, Role). Sets 30-minute session timeout. |

### `/includes/` — Shared Server-Side Includes

| File | Purpose | Included By |
|------|---------|-------------|
| `conn.asp` | Database connection factory. Defines `connStr` with **hardcoded SA credentials** and provides `GetConnection()` function returning an `ADODB.Connection`. | Every `.asp` page |
| `header.asp` | HTML `<head>`, inline CSS, site header, and **navigation bar** (conditional links based on `Session("Authenticated")`). Opens `<div class="container">`. | Every `.asp` page |
| `footer.asp` | Closes `<div class="container">`, renders copyright, contact info, active user count, and server time. Closes `</body></html>`. | Every `.asp` page |
| `functions.asp` | Utility library: `FormatCurrency()`, `FormatDate()`, `SanitizeInput()` (weak — only escapes single quotes), `GetQueryString()`, `TruncateText()`. | Every `.asp` page |
| `auth.asp` | Authentication guards: `RequireAuth()` redirects unauthenticated users to login; `RequireRole(role)` enforces role-based access (Admin bypasses all role checks). | Protected pages only |

### `/listings/` — Property Listing Pages

| File | Auth Required | Purpose |
|------|:---:|---------|
| `search.asp` | No | Property search with filters (city, state, min/max price, bedrooms, property type). Builds SQL dynamically via string concatenation. Results in 2-column grid. |
| `detail.asp` | No | Full property detail page. Shows property info table, photo gallery, agent sidebar with contact form and "Schedule Appointment" link. |
| `add.asp` | Yes (any agent) | Form to add a new property listing. Assigns to `Session("UserID")` as agent. |
| `edit.asp` | Yes (any agent) | Pre-populated form to update an existing property (address, price, status, etc.). |
| `photos.asp` | Yes (any agent) | Upload photos for a property (simulated with `FileSystemObject`), manage existing photos (view/delete), auto-increment sort order. |

### `/agents/` — Agent Pages

| File | Auth Required | Purpose |
|------|:---:|---------|
| `directory.asp` | No | Public agent listing in 2-column grid with photo, bio excerpt, email, phone, and "View Profile" link. |
| `profile.asp` | No | Individual agent profile with full bio, license number, hire date, and their active property listings in a 3-column grid. |
| `dashboard.asp` | Yes (any agent) | Agent home after login. Shows stats (total/active listings, pending inquiries, upcoming appointments), quick action links, and a table of all their listings with View/Edit/Photos actions. |

### `/inquiries/` — Client Inquiry Pages

| File | Auth Required | Purpose |
|------|:---:|---------|
| `contact.asp` | No | General or property-specific contact form. Inserts into `Inquiries` table. Includes **CDO email sending** (commented out, with hardcoded SMTP credentials). |
| `schedule.asp` | No | Schedule a property viewing appointment. Inserts into `Appointments` table with date/time picker. |
| `list.asp` | Yes (any agent) | Inquiry management for the logged-in agent. Displays all inquiries with status badges and action links (Mark Contacted / Mark Closed / Reopen). Status updates via query string. |

### `/admin/` — Administration Pages

| File | Auth Required | Purpose |
|------|:---:|---------|
| `login.asp` | No | Login form (POST). Authenticates against `Users` table with **plain-text password comparison via SQL injection-vulnerable query**. Handles logout via `?action=logout`. Supports `returnUrl` redirect. |
| `users.asp` | Yes (**Admin only**) | User management. Lists all users (shows passwords in plain text!). Form to add new users linked to agent records. |
| `reports.asp` | Yes (any agent) | Reports dashboard with summary stats (total/active properties, agents, inquiries, total listing value), properties-by-agent breakdown, properties-by-type with averages, and 10 most recent inquiries. |

### `/database/`

| File | Purpose |
|------|---------|
| `schema.sql` | Complete SQL Server database creation script: 6 tables, 10 agents, 55 properties, 10 users, 20 inquiries, 15 appointments, 15 property photos. |

---

## 2. VBScript Patterns Used

### 2.1 Server-Side Includes (SSI)

All pages follow the same include pattern:

```asp
<!-- #include file="includes/conn.asp" -->
<!-- #include file="includes/functions.asp" -->
<!-- #include file="includes/auth.asp" -->   <%-- only on protected pages --%>
<!-- #include file="includes/header.asp" -->
<%
' Page logic here
%>
<!-- #include file="includes/footer.asp" -->
```

- Subdirectory pages use `../includes/` relative paths.
- `auth.asp` is only included on pages that call `RequireAuth()` or `RequireRole()`.

### 2.2 ADO Database Access Pattern

Every page follows this inline pattern — no data access layer:

```vbscript
Dim conn, rs, sql
Set conn = GetConnection()                         ' ADODB.Connection via conn.asp
sql = "SELECT ... WHERE col = '" & userInput & "'" ' String concatenation (SQL injection)
Set rs = conn.Execute(sql)                         ' Execute returns ADODB.Recordset

Do While Not rs.EOF
    Response.Write rs("ColumnName")
    rs.MoveNext
Loop

rs.Close : Set rs = Nothing
conn.Close : Set conn = Nothing
```

**Key observations:**
- **No parameterized queries** anywhere — all queries use string concatenation.
- `conn.Execute(sql)` is used for both SELECT and INSERT/UPDATE/DELETE operations.
- Multiple connections are sometimes opened per page (e.g., `schedule.asp` uses `conn` and `conn2`).
- No connection pooling management — connections opened/closed per page.
- **No transactions** — multi-step operations have no rollback capability.
- Correlated subqueries used for photo paths: `(SELECT TOP 1 FilePath FROM PropertyPhotos WHERE PropertyID = p.PropertyID ORDER BY SortOrder)`.

### 2.3 Session Management

Defined in `global.asa`:

| Session Variable | Type | Purpose |
|-----------------|------|---------|
| `Session("Authenticated")` | Boolean | Login state flag |
| `Session("UserID")` | Integer | Maps to `Agents.AgentID` (not `Users.UserID`) |
| `Session("Username")` | String | Display name for UI |
| `Session("Role")` | String | `"Admin"` or `"Agent"` |

- **Session timeout:** 30 minutes.
- **Active user tracking:** `Application("ActiveUsers")` incremented/decremented with `Application.Lock`/`Application.Unlock`.
- **No session token rotation** — susceptible to session fixation.
- **Logout** clears session variables but does not call `Session.Abandon`.

### 2.4 Error Handling

Every page begins with `On Error Resume Next` — errors are silently swallowed. No error logging, no user-facing error messages for database failures.

### 2.5 Utility Functions (`functions.asp`)

| Function | Purpose | Notes |
|----------|---------|-------|
| `FormatCurrency(value)` | Formats number as `$X,XXX` | Shadows VBScript built-in |
| `FormatDate(dt)` | Returns `M/D/YYYY` format | US-only format |
| `SanitizeInput(str)` | Replaces `'` with `''` | Intentionally weak — doesn't prevent SQL injection |
| `GetQueryString(param, default)` | Safe QueryString read with default | Used sparingly — most pages read Request directly |
| `TruncateText(text, maxLen)` | Truncates with `...` | Used for descriptions in grids |

### 2.6 Email (CDO)

`contact.asp` configures `CDO.Message` with hardcoded SMTP credentials:
- Server: `smtp.summitrealty.com:25`
- Auth: `smtp_user` / `smtp_pass123`
- Sending is commented out (`' objCDO.Send`).

### 2.7 File Upload

`photos.asp` uses `Scripting.FileSystemObject` for a simulated file upload:
- No actual binary upload processing (would require a 3rd-party component like Persits.Upload in real Classic ASP).
- Generates filenames from property ID + timestamp.
- No file type validation, no size limits.
- Photos stored at `/images/properties/`.

---

## 3. Page-by-Page Functionality Mapping

### Public Pages

| Page | HTTP Methods | Database Operations | Key Behavior |
|------|:---:|---|---|
| `default.asp` | GET | `SELECT TOP 6` from Properties + Agents + PropertyPhotos | Featured listings grid (3 columns); links to detail and search |
| `listings/search.asp` | GET | Dynamic `SELECT` with up to 6 WHERE clauses | Search form + results grid (2 columns); filters: city, state, price range, bedrooms, property type |
| `listings/detail.asp` | GET | `SELECT *` from Properties + Agents; `SELECT` from PropertyPhotos | Full property details; photo gallery; agent sidebar; inline inquiry form (posts to `contact.asp`); schedule link |
| `agents/directory.asp` | GET | `SELECT` from Agents | Agent cards grid (2 columns) with photo, bio excerpt, contact info |
| `agents/profile.asp` | GET | `SELECT *` from Agents; `SELECT` from Properties + PropertyPhotos | Full agent bio + their active listings grid (3 columns) |
| `inquiries/contact.asp` | GET, POST | `SELECT` AgentID from Properties; `INSERT` into Inquiries | Contact form; optional `propertyID` pre-fill; CDO email (disabled) |
| `inquiries/schedule.asp` | GET, POST | `SELECT` AgentID from Properties; `SELECT` address; `INSERT` into Appointments | Appointment scheduling with date/time picker; 9 AM–5 PM hourly slots |

### Authenticated Pages

| Page | HTTP Methods | Auth Level | Database Operations | Key Behavior |
|------|:---:|:---:|---|---|
| `admin/login.asp` | GET, POST | None | `SELECT` from Users (SQL injection); `UPDATE` LastLogin | Login/logout; `returnUrl` support |
| `agents/dashboard.asp` | GET | Agent | 4× `SELECT COUNT(*)` + 1× listing `SELECT` | Stats cards + listings table with action links |
| `listings/add.asp` | GET, POST | Agent | `INSERT` into Properties | New listing form; assigns to current agent |
| `listings/edit.asp` | GET, POST | Agent | `SELECT` + `UPDATE` Properties | Edit form pre-populated with current values |
| `listings/photos.asp` | GET, POST | Agent | `SELECT MAX(SortOrder)`; `INSERT` into PropertyPhotos; `SELECT` photos; `DELETE` photo | Upload + manage photo gallery |
| `inquiries/list.asp` | GET | Agent | `UPDATE` Inquiries status; `SELECT` Inquiries + Properties | Inquiry list with status workflow (Pending → Contacted → Closed) |
| `admin/reports.asp` | GET | Agent | 5× summary `SELECT`; agents report; type report; recent inquiries | Analytics dashboard |
| `admin/users.asp` | GET, POST | **Admin** | `SELECT` Users + Agents; `INSERT` Users; `SELECT` Agents for dropdown | User CRUD; displays passwords in plain text |

---

## 4. Database Schema Analysis

### 4.1 Tables

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│     Agents       │     │   Properties     │     │ PropertyPhotos   │
├──────────────────┤     ├──────────────────┤     ├──────────────────┤
│ AgentID (PK)     │◄──┐ │ PropertyID (PK)  │◄──┐ │ PhotoID (PK)     │
│ FirstName        │   │ │ Address          │   │ │ PropertyID (FK)  │
│ LastName         │   │ │ City             │   │ │ FilePath         │
│ Email            │   │ │ State            │   │ │ Caption          │
│ Phone            │   ├─│ AgentID (FK)     │   │ │ SortOrder        │
│ LicenseNumber    │   │ │ Price            │   │ └──────────────────┘
│ Bio              │   │ │ Bedrooms         │   │
│ PhotoPath        │   │ │ Bathrooms        │   │
│ HireDate         │   │ │ SquareFeet       │   │
└──────────────────┘   │ │ PropertyType     │   │
                       │ │ Description      │   │
┌──────────────────┐   │ │ ListingDate      │   │
│     Users        │   │ │ Status           │   │
├──────────────────┤   │ │ ZipCode          │   │
│ UserID (PK)      │   │ └──────────────────┘   │
│ Username (UQ)    │   │                         │
│ Password (plain!)│   │ ┌──────────────────┐   │
│ Role             │   │ │   Inquiries      │   │
│ AgentID (FK)     │───┤ ├──────────────────┤   │
│ LastLogin        │   │ │ InquiryID (PK)   │   │
└──────────────────┘   │ │ PropertyID (FK)  │───┘
                       │ │ ClientName       │
                       │ │ ClientEmail      │
                       │ │ ClientPhone      │
                       │ │ Message          │
                       │ │ InquiryDate      │
                       │ │ Status           │
                       │ │ AgentID (FK)     │───┐
                       │ └──────────────────┘   │
                       │                         │
                       │ ┌──────────────────┐   │
                       │ │  Appointments    │   │
                       │ ├──────────────────┤   │
                       │ │ AppointmentID(PK)│   │
                       └─│ AgentID (FK)     │───┘
                         │ PropertyID (FK)  │
                         │ ClientName       │
                         │ ClientEmail      │
                         │ AppointmentDate  │
                         │ Notes            │
                         │ Status           │
                         └──────────────────┘
```

### 4.2 Table Details

| Table | PK | Identity | Rows (Seed) | Key Columns |
|-------|-----|:---:|:---:|---|
| **Agents** | `AgentID` | Yes (1,1) | 10 | FirstName, LastName, Email, Phone, LicenseNumber, Bio, PhotoPath, HireDate |
| **Properties** | `PropertyID` | Yes (1,1) | 55 | Address, City, State(2), ZipCode, Price(18,2), Bedrooms, Bathrooms(3,1), SquareFeet, PropertyType, Description, ListingDate, Status, AgentID(FK) |
| **Users** | `UserID` | Yes (1,1) | 10 | Username(UQ), **Password(plain text!)**, Role, AgentID(FK), LastLogin(nullable) |
| **Inquiries** | `InquiryID` | Yes (1,1) | 20 | PropertyID(FK, **nullable**), ClientName, ClientEmail, ClientPhone, Message, InquiryDate, Status, AgentID(FK) |
| **Appointments** | `AppointmentID` | Yes (1,1) | 15 | PropertyID(FK), AgentID(FK), ClientName, ClientEmail, AppointmentDate, Notes, Status |
| **PropertyPhotos** | `PhotoID` | Yes (1,1) | 15 | PropertyID(FK), FilePath, Caption, SortOrder |

### 4.3 Relationships (Foreign Keys)

| Child Table | FK Column | Parent Table | Nullable | Cascade |
|-------------|-----------|--------------|:---:|:---:|
| Properties | AgentID | Agents | No | No |
| Users | AgentID | Agents | No | No |
| Inquiries | PropertyID | Properties | **Yes** | No |
| Inquiries | AgentID | Agents | No | No |
| Appointments | PropertyID | Properties | No | No |
| Appointments | AgentID | Agents | No | No |
| PropertyPhotos | PropertyID | Properties | No | No |

**Note:** `Inquiries.PropertyID` is nullable — supports "general inquiries" not tied to a specific property.

### 4.4 Status Enumerations (Implicit)

| Table | Column | Values |
|-------|--------|--------|
| Properties | Status | `Active`, `Pending`, `Sold` |
| Inquiries | Status | `Pending`, `Contacted`, `Closed` |
| Appointments | Status | `Scheduled`, `Completed` |
| Users | Role | `Admin`, `Agent` |

### 4.5 Seed Data Summary

- **10 agents** across CA, TX, FL, NY, WA — diverse specializations
- **55 properties** spanning 5 states: CA (16), TX (7), FL (7), NY (9), WA (8), other CA cities (8) — prices range from $395K to $7.25M
- **10 users** — 1 admin (AgentID=1) + 9 agents, all with **plain-text passwords**
- **20 inquiries** — mix of Pending/Contacted/Closed, 2 are general (NULL PropertyID)
- **15 appointments** — mix of Scheduled/Completed
- **15 property photos** — only for properties 1, 2, 3, 5, 7, 10, 15, 20, 25, 30

---

## 5. Navigation Flow and User Journeys

### 5.1 Site Navigation (from `header.asp`)

```
┌─────────────────────────────────────────────────────────────────────┐
│  Home  │  Search Properties  │  Our Agents  │  Contact Us  │       │
│                                                                     │
│  [If authenticated]:  Dashboard  │  Logout (username)               │
│  [If not authenticated]:  Agent Login                               │
└─────────────────────────────────────────────────────────────────────┘
```

### 5.2 Public User Journey — Property Browsing

```
Homepage (default.asp)
  ├── Browse All Properties → Search (listings/search.asp)
  │     └── View Details → Detail (listings/detail.asp)
  │           ├── Send Inquiry → Contact (inquiries/contact.asp) [POST]
  │           └── Schedule Appointment → Schedule (inquiries/schedule.asp) [POST]
  ├── View Details (featured listing) → Detail (listings/detail.asp)
  ├── Our Agents → Directory (agents/directory.asp)
  │     └── View Profile → Profile (agents/profile.asp)
  │           └── View Details (agent's listing) → Detail (listings/detail.asp)
  └── Contact Us → Contact (inquiries/contact.asp)
```

### 5.3 Agent Journey — Authenticated

```
Login (admin/login.asp)
  └── Dashboard (agents/dashboard.asp)
        ├── Add New Listing → Add (listings/add.asp)
        ├── View Inquiries → List (inquiries/list.asp)
        │     └── Mark Contacted / Mark Closed / Reopen [GET with query params]
        ├── View Reports → Reports (admin/reports.asp)
        ├── View (listing) → Detail (listings/detail.asp)
        ├── Edit (listing) → Edit (listings/edit.asp)
        └── Photos (listing) → Photos (listings/photos.asp)
              ├── Upload Photo [POST]
              └── Delete Photo [GET with query param]
```

### 5.4 Admin Journey — Superset of Agent

```
Dashboard (agents/dashboard.asp)
  └── (All agent actions, plus):
      └── User Management → Users (admin/users.asp)
            └── Add New User [POST]
```

---

## 6. Authentication and Authorization Model

### 6.1 Authentication Flow

```
                    POST /admin/login.asp
                    username + password (plain text)
                           │
                           ▼
              ┌─────────────────────────┐
              │ SQL: SELECT FROM Users  │
              │ WHERE Username='X'      │  ◄── SQL INJECTION VULNERABLE
              │ AND Password='Y'        │
              └────────────┬────────────┘
                           │
                    ┌──────┴──────┐
                    │  Match?     │
                    └──────┬──────┘
                   Yes     │     No
                    │      │      │
                    ▼      │      ▼
         Set Session vars  │  Show error message
         ┌─────────────┐   │
         │ Authenticated│   │
         │ = True       │   │
         │ UserID =     │   │
         │  AgentID     │   │
         │ Username     │   │
         │ Role         │   │
         └──────┬──────┘   │
                │           │
                ▼           │
         Redirect to        │
         returnUrl or       │
         /agents/dashboard  │
```

### 6.2 Authorization Levels

| Level | Mechanism | Protected Pages |
|-------|-----------|-----------------|
| **Public** | None | `default.asp`, `search.asp`, `detail.asp`, `directory.asp`, `profile.asp`, `contact.asp`, `schedule.asp` |
| **Authenticated** | `RequireAuth()` — checks `Session("Authenticated") = True` | `dashboard.asp`, `add.asp`, `edit.asp`, `photos.asp`, `list.asp`, `reports.asp` |
| **Admin** | `RequireRole("Admin")` — checks `Session("Role") = "Admin"` (Admin role bypasses) | `users.asp` |

### 6.3 Security Vulnerabilities

| Vulnerability | Location | Description |
|--------------|----------|-------------|
| **SQL Injection** | `login.asp` line 30 | Login query uses raw string concatenation — trivially exploitable (e.g., `' OR 1=1 --`) |
| **SQL Injection** | `search.asp` lines 27–48 | All 6 search filters concatenated directly into SQL |
| **SQL Injection** | `detail.asp` line 22, `profile.asp` line 19 | QueryString `id` injected directly into `WHERE` clause |
| **SQL Injection** | `add.asp`, `edit.asp`, `photos.asp`, `contact.asp`, `schedule.asp`, `list.asp`, `users.asp` | All INSERT/UPDATE operations use string concatenation |
| **Plain-text passwords** | `users.asp` line 31, `schema.sql` | Passwords stored and displayed unencrypted |
| **No CSRF protection** | All forms | No anti-forgery tokens on any form |
| **Insecure status updates** | `list.asp` line 19 | Inquiry status changed via GET request (no CSRF, no ownership validation beyond agent) |
| **No XSS protection** | All pages | User input rendered without HTML encoding (`<%= rs("...") %>`) |
| **Session fixation** | `login.asp` | No `Session.Abandon` or session ID regeneration on login |
| **Hardcoded credentials** | `conn.asp`, `contact.asp` | DB connection as `sa`; SMTP credentials in code |
| **Path traversal risk** | `photos.asp` | No file extension or content-type validation on uploads |
| **IDOR** | `edit.asp`, `photos.asp` | No ownership check — any authenticated agent can edit/delete any property's data |
| **Error suppression** | All pages | `On Error Resume Next` hides all errors including security-relevant ones |

---

## 7. Shared Include Dependencies

### Dependency Matrix

| Page | `conn.asp` | `functions.asp` | `auth.asp` | `header.asp` | `footer.asp` |
|------|:---:|:---:|:---:|:---:|:---:|
| `default.asp` | ✅ | ✅ | ❌ | ✅ | ✅ |
| `listings/search.asp` | ✅ | ✅ | ❌ | ✅ | ✅ |
| `listings/detail.asp` | ✅ | ✅ | ❌ | ✅ | ✅ |
| `listings/add.asp` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `listings/edit.asp` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `listings/photos.asp` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `agents/directory.asp` | ✅ | ✅ | ❌ | ✅ | ✅ |
| `agents/profile.asp` | ✅ | ✅ | ❌ | ✅ | ✅ |
| `agents/dashboard.asp` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `inquiries/contact.asp` | ✅ | ✅ | ❌ | ✅ | ✅ |
| `inquiries/schedule.asp` | ✅ | ✅ | ❌ | ✅ | ✅ |
| `inquiries/list.asp` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `admin/login.asp` | ✅ | ✅ | ❌ | ✅ | ✅ |
| `admin/users.asp` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `admin/reports.asp` | ✅ | ✅ | ✅ | ✅ | ✅ |

### Include Categories

- **Universal (all 15 pages):** `conn.asp`, `functions.asp`, `header.asp`, `footer.asp`
- **Protected pages only (7 pages):** `auth.asp` — `add.asp`, `edit.asp`, `photos.asp`, `dashboard.asp`, `list.asp`, `users.asp`, `reports.asp`
- **Public pages (8 pages):** No `auth.asp` — `default.asp`, `search.asp`, `detail.asp`, `directory.asp`, `profile.asp`, `contact.asp`, `schedule.asp`, `login.asp`

### Include → ASP.NET Core Mapping

| Classic ASP Include | ASP.NET Core Equivalent |
|--------------------|-----------------------|
| `conn.asp` | `DbContext` + dependency injection + `appsettings.json` connection string |
| `functions.asp` | Static helper class or extension methods; `FormatCurrency` → `string.Format("C0")` |
| `auth.asp` | ASP.NET Core Identity + `[Authorize]` attribute + policy-based authorization |
| `header.asp` | Razor `_Layout.cshtml` (top portion) + `_LoginPartial.cshtml` |
| `footer.asp` | Razor `_Layout.cshtml` (bottom portion) |
| `global.asa` | `Program.cs` service configuration + middleware pipeline |

---

## 8. Modernization Considerations

### 8.1 Page-to-Razor Mapping (Recommended)

| Classic ASP | Razor Page | Notes |
|------------|------------|-------|
| `default.asp` | `Pages/Index.cshtml` | Use `PageModel.OnGetAsync()` with EF Core |
| `listings/search.asp` | `Pages/Listings/Search.cshtml` | Bind filters to model; parameterized queries |
| `listings/detail.asp` | `Pages/Listings/Detail.cshtml` | Route: `{id:int}`; include anti-forgery on inline form |
| `listings/add.asp` | `Pages/Listings/Add.cshtml` | `[Authorize]`; model validation; `OnPostAsync()` |
| `listings/edit.asp` | `Pages/Listings/Edit.cshtml` | `[Authorize]`; ownership check; concurrency handling |
| `listings/photos.asp` | `Pages/Listings/Photos.cshtml` | `IFormFile` upload; Azure Blob Storage; validation |
| `agents/directory.asp` | `Pages/Agents/Index.cshtml` | Paginated agent list |
| `agents/profile.asp` | `Pages/Agents/Profile.cshtml` | Route: `{id:int}` |
| `agents/dashboard.asp` | `Pages/Agents/Dashboard.cshtml` | `[Authorize]`; scoped to current user |
| `inquiries/contact.asp` | `Pages/Inquiries/Contact.cshtml` | Anti-forgery; email via Azure Communication Services |
| `inquiries/schedule.asp` | `Pages/Inquiries/Schedule.cshtml` | DateTime validation; anti-forgery |
| `inquiries/list.asp` | `Pages/Inquiries/Index.cshtml` | `[Authorize]`; POST for status changes |
| `admin/login.asp` | ASP.NET Core Identity `/Account/Login` | Built-in scaffolded pages |
| `admin/users.asp` | `Pages/Admin/Users.cshtml` | `[Authorize(Roles = "Admin")]`; Identity user management |
| `admin/reports.asp` | `Pages/Admin/Reports.cshtml` | `[Authorize]`; aggregate queries via EF Core |

### 8.2 Entity Framework Core Models (6 Entities)

```
Agent (AgentID, FirstName, LastName, Email, Phone, LicenseNumber, Bio, PhotoPath, HireDate)
  └── has many: Properties, Users, Inquiries, Appointments

Property (PropertyID, Address, City, State, ZipCode, Price, Bedrooms, Bathrooms, SquareFeet, PropertyType, Description, ListingDate, Status, AgentID)
  └── has many: PropertyPhotos, Inquiries, Appointments

User (via ASP.NET Core Identity — migrate Username, Role, AgentID linkage)

Inquiry (InquiryID, PropertyID?, ClientName, ClientEmail, ClientPhone, Message, InquiryDate, Status, AgentID)

Appointment (AppointmentID, PropertyID, AgentID, ClientName, ClientEmail, AppointmentDate, Notes, Status)

PropertyPhoto (PhotoID, PropertyID, FilePath, Caption, SortOrder)
```

### 8.3 Key Migration Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Data migration with plain-text passwords | Users cannot log in after migration | Hash existing passwords during migration or force password reset |
| SQL Server ↔ EF Core query parity | 55 inline SQL queries to rewrite | Map each query to LINQ; verify with integration tests |
| Session → Identity migration | Authentication flow completely changes | Implement Identity with cookie auth; map Roles |
| File upload mechanism | No real upload component in Classic ASP | Implement `IFormFile` + Azure Blob Storage |
| Email sending | CDO → modern email service | Use Azure Communication Services or SendGrid |
| `On Error Resume Next` → structured exceptions | Hidden bugs may surface | Add comprehensive error handling and logging |
| No CSRF → anti-forgery tokens | Forms need `@Html.AntiForgeryToken()` | Default in Razor Pages; ensure all forms POST |
| IDOR vulnerabilities | Edit/delete any property | Add ownership checks in page handlers |

---

## 9. Summary Statistics

| Metric | Count |
|--------|-------|
| Total `.asp` files | 15 |
| Include files | 5 |
| Database tables | 6 |
| Foreign key relationships | 7 |
| Seed data rows | 125 (10+55+10+20+15+15) |
| SQL injection points | 20+ (every query) |
| Pages requiring authentication | 7 |
| Pages requiring Admin role | 1 |
| Public pages | 8 (including login) |
| Unique VBScript functions | 5 (in functions.asp) + 2 (in auth.asp) + 1 (in conn.asp) |
| Lines of VBScript/HTML | ~1,800 (across all .asp files) |
