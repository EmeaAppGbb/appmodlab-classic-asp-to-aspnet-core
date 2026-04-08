<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next

' Get search parameters - vulnerable to SQL injection
Dim searchCity, searchState, minPrice, maxPrice, bedrooms, propertyType
searchCity = Request.QueryString("city")
searchState = Request.QueryString("state")
minPrice = Request.QueryString("minPrice")
maxPrice = Request.QueryString("maxPrice")
bedrooms = Request.QueryString("bedrooms")
propertyType = Request.QueryString("propertyType")

Dim conn, rs, sql
Set conn = GetConnection()

' Build SQL query with string concatenation - SQL INJECTION VULNERABILITY
sql = "SELECT p.PropertyID, p.Address, p.City, p.State, p.Price, p.Bedrooms, p.Bathrooms, " & _
      "p.SquareFeet, p.PropertyType, p.Description, a.FirstName, a.LastName, " & _
      "(SELECT TOP 1 FilePath FROM PropertyPhotos WHERE PropertyID = p.PropertyID ORDER BY SortOrder) as PhotoPath " & _
      "FROM Properties p INNER JOIN Agents a ON p.AgentID = a.AgentID " & _
      "WHERE p.Status = 'Active'"

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

sql = sql & " ORDER BY p.ListingDate DESC"

Set rs = conn.Execute(sql)
%>

<h1>Property Search</h1>

<form method="GET" action="search.asp">
    <table border="0" cellpadding="5" cellspacing="0" width="100%" style="background-color: #f0f0f0; margin-bottom: 20px;">
        <tr>
            <td>City:</td>
            <td><input type="text" name="city" value="<%= searchCity %>" size="20"></td>
            <td>State:</td>
            <td>
                <select name="state">
                    <option value="">All States</option>
                    <option value="CA" <% If searchState = "CA" Then Response.Write "selected" %>>California</option>
                    <option value="TX" <% If searchState = "TX" Then Response.Write "selected" %>>Texas</option>
                    <option value="FL" <% If searchState = "FL" Then Response.Write "selected" %>>Florida</option>
                    <option value="NY" <% If searchState = "NY" Then Response.Write "selected" %>>New York</option>
                    <option value="WA" <% If searchState = "WA" Then Response.Write "selected" %>>Washington</option>
                </select>
            </td>
        </tr>
        <tr>
            <td>Min Price:</td>
            <td><input type="text" name="minPrice" value="<%= minPrice %>" size="15"></td>
            <td>Max Price:</td>
            <td><input type="text" name="maxPrice" value="<%= maxPrice %>" size="15"></td>
        </tr>
        <tr>
            <td>Bedrooms:</td>
            <td>
                <select name="bedrooms">
                    <option value="">Any</option>
                    <option value="1" <% If bedrooms = "1" Then Response.Write "selected" %>>1+</option>
                    <option value="2" <% If bedrooms = "2" Then Response.Write "selected" %>>2+</option>
                    <option value="3" <% If bedrooms = "3" Then Response.Write "selected" %>>3+</option>
                    <option value="4" <% If bedrooms = "4" Then Response.Write "selected" %>>4+</option>
                </select>
            </td>
            <td>Property Type:</td>
            <td>
                <select name="propertyType">
                    <option value="">All Types</option>
                    <option value="Single Family" <% If propertyType = "Single Family" Then Response.Write "selected" %>>Single Family</option>
                    <option value="Condo" <% If propertyType = "Condo" Then Response.Write "selected" %>>Condo</option>
                    <option value="Townhouse" <% If propertyType = "Townhouse" Then Response.Write "selected" %>>Townhouse</option>
                    <option value="Multi-Family" <% If propertyType = "Multi-Family" Then Response.Write "selected" %>>Multi-Family</option>
                </select>
            </td>
        </tr>
        <tr>
            <td colspan="4" align="center">
                <input type="submit" value="Search" style="background-color: #003366; color: white; padding: 8px 20px; font-weight: bold; border: none; cursor: pointer;">
                <input type="button" value="Clear" onclick="window.location='search.asp'" style="background-color: #666; color: white; padding: 8px 20px; font-weight: bold; border: none; cursor: pointer;">
            </td>
        </tr>
    </table>
</form>

<h2>Search Results</h2>

<%
Dim resultCount
resultCount = 0

If Not rs.EOF Then
%>
<table width="100%" border="0" cellpadding="10" cellspacing="0">
<%
    Dim counter
    counter = 0
    Do While Not rs.EOF
        If counter Mod 2 = 0 Then
            Response.Write "<tr>"
        End If
%>
    <td width="50%" valign="top" style="border: 1px solid #ccc; background-color: #fafafa;">
        <table width="100%" border="0">
            <tr>
                <td width="200" align="center">
                    <% If Not IsNull(rs("PhotoPath")) And rs("PhotoPath") <> "" Then %>
                        <img src="<%= rs("PhotoPath") %>" width="180" height="135" alt="Property Photo" style="border: 1px solid #999;">
                    <% Else %>
                        <img src="/images/no-photo.jpg" width="180" height="135" alt="No Photo Available" style="border: 1px solid #999;">
                    <% End If %>
                </td>
                <td valign="top">
                    <strong><%= rs("Address") %></strong><br>
                    <%= rs("City") %>, <%= rs("State") %><br>
                    <span style="color: #003366; font-size: 18px; font-weight: bold;"><%= FormatCurrency(rs("Price")) %></span><br>
                    <%= rs("Bedrooms") %> BD | <%= rs("Bathrooms") %> BA | <%= rs("SquareFeet") %> sq ft<br>
                    <%= rs("PropertyType") %><br>
                    <strong>Agent:</strong> <%= rs("FirstName") %> <%= rs("LastName") %><br>
                    <a href="detail.asp?id=<%= rs("PropertyID") %>" style="background-color: #003366; color: white; padding: 5px 10px; text-decoration: none; display: inline-block; margin-top: 5px;">View Details</a>
                </td>
            </tr>
        </table>
    </td>
<%
        counter = counter + 1
        resultCount = resultCount + 1
        If counter Mod 2 = 0 Then
            Response.Write "</tr>"
        End If
        rs.MoveNext
    Loop
    
    If counter Mod 2 <> 0 Then
        Response.Write "</tr>"
    End If
%>
</table>
<p><strong><%= resultCount %></strong> properties found.</p>
<%
Else
%>
    <p>No properties found matching your criteria. Please adjust your search parameters.</p>
<%
End If

rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing
%>

<!-- #include file="../includes/footer.asp" -->
