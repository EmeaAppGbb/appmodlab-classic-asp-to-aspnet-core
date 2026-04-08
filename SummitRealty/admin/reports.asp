<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/auth.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next
Call RequireAuth()

Dim conn, rs, sql
Set conn = GetConnection()

' Get summary statistics
sql = "SELECT COUNT(*) as TotalProperties FROM Properties"
Set rs = conn.Execute(sql)
Dim totalProperties
totalProperties = rs("TotalProperties")
rs.Close
Set rs = Nothing

sql = "SELECT COUNT(*) as ActiveProperties FROM Properties WHERE Status = 'Active'"
Set rs = conn.Execute(sql)
Dim activeProperties
activeProperties = rs("ActiveProperties")
rs.Close
Set rs = Nothing

sql = "SELECT COUNT(*) as TotalAgents FROM Agents"
Set rs = conn.Execute(sql)
Dim totalAgents
totalAgents = rs("TotalAgents")
rs.Close
Set rs = Nothing

sql = "SELECT COUNT(*) as TotalInquiries FROM Inquiries"
Set rs = conn.Execute(sql)
Dim totalInquiries
totalInquiries = rs("TotalInquiries")
rs.Close
Set rs = Nothing

sql = "SELECT SUM(Price) as TotalValue FROM Properties WHERE Status = 'Active'"
Set rs = conn.Execute(sql)
Dim totalValue
If Not IsNull(rs("TotalValue")) Then
    totalValue = rs("TotalValue")
Else
    totalValue = 0
End If
rs.Close
Set rs = Nothing
%>

<h1>Reports & Analytics</h1>

<h2>Summary Statistics</h2>

<table width="100%" border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse;">
    <tr>
        <td align="center" bgcolor="#e6f2ff" width="25%">
            <h2 style="margin: 0; color: #003366;"><%= totalProperties %></h2>
            <p style="margin: 5px 0 0 0;">Total Properties</p>
        </td>
        <td align="center" bgcolor="#e6ffe6" width="25%">
            <h2 style="margin: 0; color: #006600;"><%= activeProperties %></h2>
            <p style="margin: 5px 0 0 0;">Active Listings</p>
        </td>
        <td align="center" bgcolor="#fff0e6" width="25%">
            <h2 style="margin: 0; color: #cc6600;"><%= totalAgents %></h2>
            <p style="margin: 5px 0 0 0;">Total Agents</p>
        </td>
        <td align="center" bgcolor="#ffe6f0" width="25%">
            <h2 style="margin: 0; color: #cc0066;"><%= totalInquiries %></h2>
            <p style="margin: 5px 0 0 0;">Total Inquiries</p>
        </td>
    </tr>
</table>

<h3>Total Active Listing Value: <%= FormatCurrency(totalValue) %></h3>

<h2>Properties by Agent</h2>

<%
sql = "SELECT a.AgentID, a.FirstName, a.LastName, " & _
      "COUNT(p.PropertyID) as PropertyCount, " & _
      "SUM(CASE WHEN p.Status = 'Active' THEN 1 ELSE 0 END) as ActiveCount, " & _
      "SUM(CASE WHEN p.Status = 'Sold' THEN 1 ELSE 0 END) as SoldCount " & _
      "FROM Agents a LEFT JOIN Properties p ON a.AgentID = p.AgentID " & _
      "GROUP BY a.AgentID, a.FirstName, a.LastName " & _
      "ORDER BY PropertyCount DESC"
Set rs = conn.Execute(sql)
%>

<table width="100%" border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse;">
    <tr bgcolor="#f0f0f0">
        <th>Agent Name</th>
        <th>Total Listings</th>
        <th>Active</th>
        <th>Sold</th>
    </tr>
    <%
    Do While Not rs.EOF
    %>
    <tr>
        <td><%= rs("FirstName") %> <%= rs("LastName") %></td>
        <td align="center"><%= rs("PropertyCount") %></td>
        <td align="center"><%= rs("ActiveCount") %></td>
        <td align="center"><%= rs("SoldCount") %></td>
    </tr>
    <%
        rs.MoveNext
    Loop
    rs.Close
    Set rs = Nothing
    %>
</table>

<h2>Properties by Type</h2>

<%
sql = "SELECT PropertyType, COUNT(*) as Count, AVG(Price) as AvgPrice " & _
      "FROM Properties WHERE Status = 'Active' " & _
      "GROUP BY PropertyType ORDER BY Count DESC"
Set rs = conn.Execute(sql)
%>

<table width="60%" border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse;">
    <tr bgcolor="#f0f0f0">
        <th>Property Type</th>
        <th>Count</th>
        <th>Average Price</th>
    </tr>
    <%
    Do While Not rs.EOF
    %>
    <tr>
        <td><%= rs("PropertyType") %></td>
        <td align="center"><%= rs("Count") %></td>
        <td align="right"><%= FormatCurrency(rs("AvgPrice")) %></td>
    </tr>
    <%
        rs.MoveNext
    Loop
    rs.Close
    Set rs = Nothing
    %>
</table>

<h2>Recent Inquiries</h2>

<%
sql = "SELECT TOP 10 i.InquiryDate, i.ClientName, p.Address, p.City, a.FirstName, a.LastName, i.Status " & _
      "FROM Inquiries i " & _
      "LEFT JOIN Properties p ON i.PropertyID = p.PropertyID " & _
      "INNER JOIN Agents a ON i.AgentID = a.AgentID " & _
      "ORDER BY i.InquiryDate DESC"
Set rs = conn.Execute(sql)
%>

<table width="100%" border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse;">
    <tr bgcolor="#f0f0f0">
        <th>Date</th>
        <th>Client</th>
        <th>Property</th>
        <th>Agent</th>
        <th>Status</th>
    </tr>
    <%
    Do While Not rs.EOF
    %>
    <tr>
        <td><%= FormatDate(rs("InquiryDate")) %></td>
        <td><%= rs("ClientName") %></td>
        <td>
            <% If Not IsNull(rs("Address")) Then %>
                <%= rs("Address") %>, <%= rs("City") %>
            <% Else %>
                <em>General Inquiry</em>
            <% End If %>
        </td>
        <td><%= rs("FirstName") %> <%= rs("LastName") %></td>
        <td><%= rs("Status") %></td>
    </tr>
    <%
        rs.MoveNext
    Loop
    rs.Close
    Set rs = Nothing
    %>
</table>

<%
conn.Close
Set conn = Nothing
%>

<p style="margin-top: 20px;">
    <a href="/agents/dashboard.asp" style="background-color: #666; color: white; padding: 8px 15px; text-decoration: none;">Back to Dashboard</a>
</p>

<!-- #include file="../includes/footer.asp" -->
