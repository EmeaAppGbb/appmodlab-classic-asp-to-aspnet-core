<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next

' Get property ID from querystring - SQL injection vulnerability
Dim propertyID
propertyID = Request.QueryString("id")

If propertyID = "" Then
    Response.Write "<p class='error'>Invalid property ID.</p>"
    Response.End
End If

Dim conn, rs, sql
Set conn = GetConnection()

' SQL injection vulnerable query
sql = "SELECT p.*, a.FirstName, a.LastName, a.Email, a.Phone, a.PhotoPath as AgentPhoto " & _
      "FROM Properties p INNER JOIN Agents a ON p.AgentID = a.AgentID " & _
      "WHERE p.PropertyID = " & propertyID

Set rs = conn.Execute(sql)

If rs.EOF Then
    Response.Write "<p class='error'>Property not found.</p>"
    rs.Close
    Set rs = Nothing
    conn.Close
    Set conn = Nothing
    Response.End
End If
%>

<h1><%= rs("Address") %></h1>
<h3><%= rs("City") %>, <%= rs("State") %> <%= rs("ZipCode") %></h3>

<table width="100%" border="0" cellpadding="10" cellspacing="0">
    <tr>
        <td width="60%" valign="top">
            <h2>Property Details</h2>
            <table border="1" cellpadding="5" cellspacing="0" width="100%" style="border-collapse: collapse;">
                <tr>
                    <td bgcolor="#f0f0f0"><strong>Price:</strong></td>
                    <td><span style="color: #003366; font-size: 20px; font-weight: bold;"><%= FormatCurrency(rs("Price")) %></span></td>
                </tr>
                <tr>
                    <td bgcolor="#f0f0f0"><strong>Property Type:</strong></td>
                    <td><%= rs("PropertyType") %></td>
                </tr>
                <tr>
                    <td bgcolor="#f0f0f0"><strong>Bedrooms:</strong></td>
                    <td><%= rs("Bedrooms") %></td>
                </tr>
                <tr>
                    <td bgcolor="#f0f0f0"><strong>Bathrooms:</strong></td>
                    <td><%= rs("Bathrooms") %></td>
                </tr>
                <tr>
                    <td bgcolor="#f0f0f0"><strong>Square Feet:</strong></td>
                    <td><%= rs("SquareFeet") %> sq ft</td>
                </tr>
                <tr>
                    <td bgcolor="#f0f0f0"><strong>Status:</strong></td>
                    <td><%= rs("Status") %></td>
                </tr>
                <tr>
                    <td bgcolor="#f0f0f0"><strong>Listed:</strong></td>
                    <td><%= FormatDate(rs("ListingDate")) %></td>
                </tr>
            </table>
            
            <h3>Description</h3>
            <p><%= rs("Description") %></p>
            
            <h3>Property Photos</h3>
            <%
            Dim rsPhotos, sqlPhotos
            sqlPhotos = "SELECT FilePath, Caption FROM PropertyPhotos WHERE PropertyID = " & propertyID & " ORDER BY SortOrder"
            Set rsPhotos = conn.Execute(sqlPhotos)
            
            If Not rsPhotos.EOF Then
            %>
                <table border="0" cellpadding="5" cellspacing="5">
                    <tr>
                    <%
                    Dim photoCount
                    photoCount = 0
                    Do While Not rsPhotos.EOF
                        If photoCount Mod 3 = 0 And photoCount > 0 Then
                            Response.Write "</tr><tr>"
                        End If
                    %>
                        <td align="center">
                            <img src="<%= rsPhotos("FilePath") %>" width="200" height="150" alt="<%= rsPhotos("Caption") %>" style="border: 1px solid #999;"><br>
                            <small><%= rsPhotos("Caption") %></small>
                        </td>
                    <%
                        photoCount = photoCount + 1
                        rsPhotos.MoveNext
                    Loop
                    %>
                    </tr>
                </table>
            <%
            Else
            %>
                <p>No photos available for this property.</p>
            <%
            End If
            rsPhotos.Close
            Set rsPhotos = Nothing
            %>
        </td>
        <td width="40%" valign="top" style="border-left: 2px solid #ccc; padding-left: 20px;">
            <h2>Contact Agent</h2>
            <table border="0" cellpadding="5" width="100%">
                <tr>
                    <td align="center" colspan="2">
                        <% If Not IsNull(rs("AgentPhoto")) And rs("AgentPhoto") <> "" Then %>
                            <img src="<%= rs("AgentPhoto") %>" width="150" height="150" alt="<%= rs("FirstName") %> <%= rs("LastName") %>" style="border: 2px solid #003366; border-radius: 75px;">
                        <% Else %>
                            <img src="/images/no-agent-photo.jpg" width="150" height="150" alt="Agent Photo" style="border: 2px solid #003366; border-radius: 75px;">
                        <% End If %>
                    </td>
                </tr>
                <tr>
                    <td colspan="2" align="center">
                        <h3 style="margin: 10px 0;"><%= rs("FirstName") %> <%= rs("LastName") %></h3>
                    </td>
                </tr>
                <tr>
                    <td><strong>Email:</strong></td>
                    <td><a href="mailto:<%= rs("Email") %>"><%= rs("Email") %></a></td>
                </tr>
                <tr>
                    <td><strong>Phone:</strong></td>
                    <td><%= rs("Phone") %></td>
                </tr>
            </table>
            
            <h3>Request Information</h3>
            <form method="POST" action="/inquiries/contact.asp">
                <input type="hidden" name="propertyID" value="<%= propertyID %>">
                <table border="0" cellpadding="5" width="100%">
                    <tr>
                        <td>Name:</td>
                    </tr>
                    <tr>
                        <td><input type="text" name="clientName" size="30" style="width: 100%;"></td>
                    </tr>
                    <tr>
                        <td>Email:</td>
                    </tr>
                    <tr>
                        <td><input type="text" name="clientEmail" size="30" style="width: 100%;"></td>
                    </tr>
                    <tr>
                        <td>Phone:</td>
                    </tr>
                    <tr>
                        <td><input type="text" name="clientPhone" size="30" style="width: 100%;"></td>
                    </tr>
                    <tr>
                        <td>Message:</td>
                    </tr>
                    <tr>
                        <td><textarea name="message" rows="5" cols="30" style="width: 100%;"></textarea></td>
                    </tr>
                    <tr>
                        <td align="center">
                            <input type="submit" value="Send Inquiry" style="background-color: #003366; color: white; padding: 10px 20px; font-weight: bold; border: none; cursor: pointer;">
                        </td>
                    </tr>
                </table>
            </form>
            
            <h3>Schedule Viewing</h3>
            <p align="center">
                <a href="/inquiries/schedule.asp?propertyID=<%= propertyID %>" style="background-color: #ffcc00; color: #003366; padding: 10px 15px; text-decoration: none; font-weight: bold; display: inline-block;">Schedule Appointment</a>
            </p>
        </td>
    </tr>
</table>

<%
rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing
%>

<!-- #include file="../includes/footer.asp" -->
