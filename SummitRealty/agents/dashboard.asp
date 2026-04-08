<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/auth.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next
Call RequireAuth()

Dim conn, rs, sql
Set conn = GetConnection()

' Get agent stats
Dim agentID
agentID = Session("UserID")

' Get total listings
sql = "SELECT COUNT(*) as TotalListings FROM Properties WHERE AgentID = " & agentID
Set rs = conn.Execute(sql)
Dim totalListings
totalListings = rs("TotalListings")
rs.Close
Set rs = Nothing

' Get active listings
sql = "SELECT COUNT(*) as ActiveListings FROM Properties WHERE AgentID = " & agentID & " AND Status = 'Active'"
Set rs = conn.Execute(sql)
Dim activeListings
activeListings = rs("ActiveListings")
rs.Close
Set rs = Nothing

' Get pending inquiries
sql = "SELECT COUNT(*) as PendingInquiries FROM Inquiries WHERE AgentID = " & agentID & " AND Status = 'Pending'"
Set rs = conn.Execute(sql)
Dim pendingInquiries
pendingInquiries = rs("PendingInquiries")
rs.Close
Set rs = Nothing

' Get upcoming appointments
sql = "SELECT COUNT(*) as UpcomingAppointments FROM Appointments WHERE AgentID = " & agentID & " AND AppointmentDate >= GETDATE() AND Status = 'Scheduled'"
Set rs = conn.Execute(sql)
Dim upcomingAppointments
upcomingAppointments = rs("UpcomingAppointments")
rs.Close
Set rs = Nothing
%>

<h1>Agent Dashboard</h1>
<p>Welcome back, <%= Session("Username") %>!</p>

<table width="100%" border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; margin-bottom: 20px;">
    <tr>
        <td align="center" bgcolor="#e6f2ff" width="25%">
            <h2 style="margin: 0; color: #003366;"><%= totalListings %></h2>
            <p style="margin: 5px 0 0 0;">Total Listings</p>
        </td>
        <td align="center" bgcolor="#e6ffe6" width="25%">
            <h2 style="margin: 0; color: #006600;"><%= activeListings %></h2>
            <p style="margin: 5px 0 0 0;">Active Listings</p>
        </td>
        <td align="center" bgcolor="#fff0e6" width="25%">
            <h2 style="margin: 0; color: #cc6600;"><%= pendingInquiries %></h2>
            <p style="margin: 5px 0 0 0;">Pending Inquiries</p>
        </td>
        <td align="center" bgcolor="#ffe6f0" width="25%">
            <h2 style="margin: 0; color: #cc0066;"><%= upcomingAppointments %></h2>
            <p style="margin: 5px 0 0 0;">Upcoming Appointments</p>
        </td>
    </tr>
</table>

<h2>Quick Actions</h2>
<p>
    <a href="/listings/add.asp" style="background-color: #003366; color: white; padding: 10px 15px; text-decoration: none; font-weight: bold; margin-right: 10px;">Add New Listing</a>
    <a href="/inquiries/list.asp" style="background-color: #cc6600; color: white; padding: 10px 15px; text-decoration: none; font-weight: bold; margin-right: 10px;">View Inquiries</a>
    <a href="/admin/reports.asp" style="background-color: #006600; color: white; padding: 10px 15px; text-decoration: none; font-weight: bold;">View Reports</a>
</p>

<h2>My Active Listings</h2>

<%
sql = "SELECT p.PropertyID, p.Address, p.City, p.State, p.Price, p.Status, p.ListingDate, " & _
      "(SELECT COUNT(*) FROM Inquiries WHERE PropertyID = p.PropertyID) as InquiryCount " & _
      "FROM Properties p WHERE p.AgentID = " & agentID & " ORDER BY p.ListingDate DESC"
Set rs = conn.Execute(sql)

If Not rs.EOF Then
%>
    <table width="100%" border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse;">
        <tr bgcolor="#f0f0f0">
            <th>Address</th>
            <th>City</th>
            <th>State</th>
            <th>Price</th>
            <th>Status</th>
            <th>Listed</th>
            <th>Inquiries</th>
            <th>Actions</th>
        </tr>
        <%
        Do While Not rs.EOF
        %>
        <tr>
            <td><%= rs("Address") %></td>
            <td><%= rs("City") %></td>
            <td><%= rs("State") %></td>
            <td><%= FormatCurrency(rs("Price")) %></td>
            <td><%= rs("Status") %></td>
            <td><%= FormatDate(rs("ListingDate")) %></td>
            <td align="center"><%= rs("InquiryCount") %></td>
            <td>
                <a href="/listings/detail.asp?id=<%= rs("PropertyID") %>">View</a> |
                <a href="/listings/edit.asp?id=<%= rs("PropertyID") %>">Edit</a> |
                <a href="/listings/photos.asp?id=<%= rs("PropertyID") %>">Photos</a>
            </td>
        </tr>
        <%
            rs.MoveNext
        Loop
        %>
    </table>
<%
Else
%>
    <p>You have no listings yet. <a href="/listings/add.asp">Add your first listing</a>.</p>
<%
End If

rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing
%>

<!-- #include file="../includes/footer.asp" -->
