<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next

Dim agentID
agentID = Request.QueryString("id")

If agentID = "" Then
    Response.Write "<p class='error'>Invalid agent ID.</p>"
    Response.End
End If

Dim conn, rs, sql
Set conn = GetConnection()

' SQL injection vulnerability
sql = "SELECT * FROM Agents WHERE AgentID = " & agentID
Set rs = conn.Execute(sql)

If rs.EOF Then
    Response.Write "<p class='error'>Agent not found.</p>"
    rs.Close
    Set rs = Nothing
    conn.Close
    Set conn = Nothing
    Response.End
End If
%>

<table width="100%" border="0" cellpadding="0" cellspacing="0">
    <tr>
        <td width="250" valign="top">
            <% If Not IsNull(rs("PhotoPath")) And rs("PhotoPath") <> "" Then %>
                <img src="<%= rs("PhotoPath") %>" width="200" height="200" alt="<%= rs("FirstName") %> <%= rs("LastName") %>" style="border: 3px solid #003366; border-radius: 100px;">
            <% Else %>
                <img src="/images/no-agent-photo.jpg" width="200" height="200" alt="Agent Photo" style="border: 3px solid #003366; border-radius: 100px;">
            <% End If %>
        </td>
        <td valign="top" style="padding-left: 30px;">
            <h1><%= rs("FirstName") %> <%= rs("LastName") %></h1>
            <table border="0" cellpadding="5" cellspacing="0">
                <tr>
                    <td><strong>Email:</strong></td>
                    <td><a href="mailto:<%= rs("Email") %>"><%= rs("Email") %></a></td>
                </tr>
                <tr>
                    <td><strong>Phone:</strong></td>
                    <td><%= rs("Phone") %></td>
                </tr>
                <tr>
                    <td><strong>License #:</strong></td>
                    <td><%= rs("LicenseNumber") %></td>
                </tr>
                <tr>
                    <td><strong>With Summit Since:</strong></td>
                    <td><%= FormatDate(rs("HireDate")) %></td>
                </tr>
            </table>
            
            <h3>About <%= rs("FirstName") %></h3>
            <p><%= rs("Bio") %></p>
        </td>
    </tr>
</table>

<h2>Current Listings</h2>

<%
Dim rsListings, sqlListings
sqlListings = "SELECT PropertyID, Address, City, State, Price, Bedrooms, Bathrooms, SquareFeet, PropertyType, " & _
              "(SELECT TOP 1 FilePath FROM PropertyPhotos WHERE PropertyID = p.PropertyID ORDER BY SortOrder) as PhotoPath " & _
              "FROM Properties p WHERE AgentID = " & agentID & " AND Status = 'Active' ORDER BY ListingDate DESC"
Set rsListings = conn.Execute(sqlListings)

If Not rsListings.EOF Then
%>
    <table width="100%" border="0" cellpadding="10" cellspacing="0">
    <%
    Dim counter
    counter = 0
    Do While Not rsListings.EOF
        If counter Mod 3 = 0 Then
            Response.Write "<tr>"
        End If
    %>
        <td width="33%" valign="top" style="border: 1px solid #ccc; background-color: #fafafa;">
            <table width="100%" border="0">
                <tr>
                    <td align="center">
                        <% If Not IsNull(rsListings("PhotoPath")) And rsListings("PhotoPath") <> "" Then %>
                            <img src="<%= rsListings("PhotoPath") %>" width="180" height="135" alt="Property Photo" style="border: 1px solid #999;">
                        <% Else %>
                            <img src="/images/no-photo.jpg" width="180" height="135" alt="No Photo Available" style="border: 1px solid #999;">
                        <% End If %>
                    </td>
                </tr>
                <tr>
                    <td><strong><%= rsListings("Address") %></strong></td>
                </tr>
                <tr>
                    <td><%= rsListings("City") %>, <%= rsListings("State") %></td>
                </tr>
                <tr>
                    <td style="color: #003366; font-size: 18px; font-weight: bold;">
                        <%= FormatCurrency(rsListings("Price")) %>
                    </td>
                </tr>
                <tr>
                    <td><%= rsListings("Bedrooms") %> BD | <%= rsListings("Bathrooms") %> BA | <%= rsListings("SquareFeet") %> sq ft</td>
                </tr>
                <tr>
                    <td><%= rsListings("PropertyType") %></td>
                </tr>
                <tr>
                    <td align="center">
                        <a href="/listings/detail.asp?id=<%= rsListings("PropertyID") %>" style="background-color: #003366; color: white; padding: 6px 12px; text-decoration: none; display: inline-block;">View Details</a>
                    </td>
                </tr>
            </table>
        </td>
    <%
        counter = counter + 1
        If counter Mod 3 = 0 Then
            Response.Write "</tr>"
        End If
        rsListings.MoveNext
    Loop
    
    If counter Mod 3 <> 0 Then
        Response.Write "</tr>"
    End If
    %>
    </table>
<%
Else
%>
    <p>This agent currently has no active listings.</p>
<%
End If

rsListings.Close
Set rsListings = Nothing
rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing
%>

<!-- #include file="../includes/footer.asp" -->
