<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/auth.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next
Call RequireAuth()

Dim propertyID, message, messageClass
propertyID = Request.QueryString("id")
message = ""
messageClass = ""

If propertyID = "" Then
    Response.Write "<p class='error'>Invalid property ID.</p>"
    Response.End
End If

Dim conn
Set conn = GetConnection()

If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim address, city, state, zipCode, price, bedrooms, bathrooms, squareFeet, propertyType, description, status
    address = Request.Form("address")
    city = Request.Form("city")
    state = Request.Form("state")
    zipCode = Request.Form("zipCode")
    price = Request.Form("price")
    bedrooms = Request.Form("bedrooms")
    bathrooms = Request.Form("bathrooms")
    squareFeet = Request.Form("squareFeet")
    propertyType = Request.Form("propertyType")
    description = Request.Form("description")
    status = Request.Form("status")
    
    ' SQL injection vulnerable UPDATE
    Dim sql
    sql = "UPDATE Properties SET Address = '" & address & "', City = '" & city & "', State = '" & state & "', " & _
          "ZipCode = '" & zipCode & "', Price = " & price & ", Bedrooms = " & bedrooms & ", " & _
          "Bathrooms = " & bathrooms & ", SquareFeet = " & squareFeet & ", PropertyType = '" & propertyType & "', " & _
          "Description = '" & description & "', Status = '" & status & "' WHERE PropertyID = " & propertyID
    
    conn.Execute sql
    
    message = "Property updated successfully!"
    messageClass = "success"
End If

' Get property details
Dim rs, sql
sql = "SELECT * FROM Properties WHERE PropertyID = " & propertyID
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

<h1>Edit Property Listing</h1>

<% If message <> "" Then %>
    <p class="<%= messageClass %>"><%= message %></p>
<% End If %>

<form method="POST" action="edit.asp?id=<%= propertyID %>">
    <table border="1" cellpadding="8" cellspacing="0" width="100%" style="border-collapse: collapse;">
        <tr>
            <td bgcolor="#f0f0f0" width="20%"><strong>Address:</strong></td>
            <td><input type="text" name="address" size="50" value="<%= rs("Address") %>" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>City:</strong></td>
            <td><input type="text" name="city" size="30" value="<%= rs("City") %>" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>State:</strong></td>
            <td>
                <select name="state" required>
                    <option value="CA" <% If rs("State") = "CA" Then Response.Write "selected" %>>California</option>
                    <option value="TX" <% If rs("State") = "TX" Then Response.Write "selected" %>>Texas</option>
                    <option value="FL" <% If rs("State") = "FL" Then Response.Write "selected" %>>Florida</option>
                    <option value="NY" <% If rs("State") = "NY" Then Response.Write "selected" %>>New York</option>
                    <option value="WA" <% If rs("State") = "WA" Then Response.Write "selected" %>>Washington</option>
                </select>
            </td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Zip Code:</strong></td>
            <td><input type="text" name="zipCode" size="10" value="<%= rs("ZipCode") %>" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Price:</strong></td>
            <td><input type="text" name="price" size="15" value="<%= rs("Price") %>" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Bedrooms:</strong></td>
            <td><input type="text" name="bedrooms" size="5" value="<%= rs("Bedrooms") %>" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Bathrooms:</strong></td>
            <td><input type="text" name="bathrooms" size="5" value="<%= rs("Bathrooms") %>" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Square Feet:</strong></td>
            <td><input type="text" name="squareFeet" size="10" value="<%= rs("SquareFeet") %>" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Property Type:</strong></td>
            <td>
                <select name="propertyType" required>
                    <option value="Single Family" <% If rs("PropertyType") = "Single Family" Then Response.Write "selected" %>>Single Family</option>
                    <option value="Condo" <% If rs("PropertyType") = "Condo" Then Response.Write "selected" %>>Condo</option>
                    <option value="Townhouse" <% If rs("PropertyType") = "Townhouse" Then Response.Write "selected" %>>Townhouse</option>
                    <option value="Multi-Family" <% If rs("PropertyType") = "Multi-Family" Then Response.Write "selected" %>>Multi-Family</option>
                </select>
            </td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Status:</strong></td>
            <td>
                <select name="status" required>
                    <option value="Active" <% If rs("Status") = "Active" Then Response.Write "selected" %>>Active</option>
                    <option value="Pending" <% If rs("Status") = "Pending" Then Response.Write "selected" %>>Pending</option>
                    <option value="Sold" <% If rs("Status") = "Sold" Then Response.Write "selected" %>>Sold</option>
                </select>
            </td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0" valign="top"><strong>Description:</strong></td>
            <td><textarea name="description" rows="6" cols="60" required><%= rs("Description") %></textarea></td>
        </tr>
        <tr>
            <td colspan="2" align="center">
                <input type="submit" value="Update Property" style="background-color: #003366; color: white; padding: 10px 20px; font-weight: bold; border: none; cursor: pointer;">
                <input type="button" value="Cancel" onclick="window.location='/agents/dashboard.asp'" style="background-color: #666; color: white; padding: 10px 20px; font-weight: bold; border: none; cursor: pointer;">
            </td>
        </tr>
    </table>
</form>

<%
rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing
%>

<!-- #include file="../includes/footer.asp" -->
