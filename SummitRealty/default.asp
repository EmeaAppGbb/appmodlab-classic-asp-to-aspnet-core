<!-- #include file="includes/conn.asp" -->
<!-- #include file="includes/functions.asp" -->
<!-- #include file="includes/header.asp" -->
<%
On Error Resume Next

' Get featured listings - SQL injection vulnerable
Dim conn, rs, sql
Set conn = GetConnection()

sql = "SELECT TOP 6 p.PropertyID, p.Address, p.City, p.State, p.Price, p.Bedrooms, p.Bathrooms, " & _
      "p.SquareFeet, p.PropertyType, p.Description, a.FirstName, a.LastName, " & _
      "(SELECT TOP 1 FilePath FROM PropertyPhotos WHERE PropertyID = p.PropertyID ORDER BY SortOrder) as PhotoPath " & _
      "FROM Properties p INNER JOIN Agents a ON p.AgentID = a.AgentID " & _
      "WHERE p.Status = 'Active' ORDER BY p.ListingDate DESC"

Set rs = conn.Execute(sql)
%>

<h1>Welcome to Summit Realty Group</h1>
<p>Discover your dream home from our exclusive collection of premium properties.</p>

<h2>Featured Properties</h2>

<table width="100%" border="0" cellpadding="10" cellspacing="0">
<%
Dim counter
counter = 0
Do While Not rs.EOF
    If counter Mod 3 = 0 Then
        Response.Write "<tr>"
    End If
%>
    <td width="33%" valign="top" style="border: 1px solid #ccc; background-color: #fafafa;">
        <table width="100%" border="0">
            <tr>
                <td colspan="2" align="center" style="padding: 10px;">
                    <% If Not IsNull(rs("PhotoPath")) And rs("PhotoPath") <> "" Then %>
                        <img src="<%= rs("PhotoPath") %>" width="200" height="150" alt="Property Photo" style="border: 1px solid #999;">
                    <% Else %>
                        <img src="/images/no-photo.jpg" width="200" height="150" alt="No Photo Available" style="border: 1px solid #999;">
                    <% End If %>
                </td>
            </tr>
            <tr>
                <td colspan="2"><strong><%= rs("Address") %></strong></td>
            </tr>
            <tr>
                <td colspan="2"><%= rs("City") %>, <%= rs("State") %></td>
            </tr>
            <tr>
                <td colspan="2" style="color: #003366; font-size: 18px; font-weight: bold;">
                    <%= FormatCurrency(rs("Price")) %>
                </td>
            </tr>
            <tr>
                <td><%= rs("Bedrooms") %> BD</td>
                <td><%= rs("Bathrooms") %> BA</td>
            </tr>
            <tr>
                <td colspan="2"><%= rs("SquareFeet") %> sq ft | <%= rs("PropertyType") %></td>
            </tr>
            <tr>
                <td colspan="2">
                    <%= TruncateText(rs("Description"), 100) %>
                </td>
            </tr>
            <tr>
                <td colspan="2">
                    <strong>Agent:</strong> <%= rs("FirstName") %> <%= rs("LastName") %>
                </td>
            </tr>
            <tr>
                <td colspan="2" align="center">
                    <a href="/listings/detail.asp?id=<%= rs("PropertyID") %>" style="background-color: #003366; color: white; padding: 8px 15px; text-decoration: none; display: inline-block;">View Details</a>
                </td>
            </tr>
        </table>
    </td>
<%
    counter = counter + 1
    If counter Mod 3 = 0 Then
        Response.Write "</tr>"
    End If
    rs.MoveNext
Loop

If counter Mod 3 <> 0 Then
    Response.Write "</tr>"
End If

rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing
%>
</table>

<p align="center" style="margin-top: 20px;">
    <a href="/listings/search.asp" style="background-color: #ffcc00; color: #003366; padding: 12px 25px; text-decoration: none; font-size: 16px; font-weight: bold;">Browse All Properties</a>
</p>

<!-- #include file="includes/footer.asp" -->
