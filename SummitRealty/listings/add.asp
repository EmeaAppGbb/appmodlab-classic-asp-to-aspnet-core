<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/auth.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next
Call RequireAuth()

Dim message, messageClass
message = ""
messageClass = ""

If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim address, city, state, zipCode, price, bedrooms, bathrooms, squareFeet, propertyType, description
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
    
    ' SQL injection vulnerable INSERT
    Dim conn, sql
    Set conn = GetConnection()
    
    sql = "INSERT INTO Properties (Address, City, State, ZipCode, Price, Bedrooms, Bathrooms, SquareFeet, " & _
          "PropertyType, Description, ListingDate, Status, AgentID) VALUES ('" & _
          address & "', '" & city & "', '" & state & "', '" & zipCode & "', " & price & ", " & _
          bedrooms & ", " & bathrooms & ", " & squareFeet & ", '" & propertyType & "', '" & _
          description & "', GETDATE(), 'Active', " & Session("UserID") & ")"
    
    conn.Execute sql
    
    message = "Property listing added successfully!"
    messageClass = "success"
    
    conn.Close
    Set conn = Nothing
End If
%>

<h1>Add New Property Listing</h1>

<% If message <> "" Then %>
    <p class="<%= messageClass %>"><%= message %></p>
<% End If %>

<form method="POST" action="add.asp">
    <table border="1" cellpadding="8" cellspacing="0" width="100%" style="border-collapse: collapse;">
        <tr>
            <td bgcolor="#f0f0f0" width="20%"><strong>Address:</strong></td>
            <td><input type="text" name="address" size="50" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>City:</strong></td>
            <td><input type="text" name="city" size="30" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>State:</strong></td>
            <td>
                <select name="state" required>
                    <option value="">Select State</option>
                    <option value="CA">California</option>
                    <option value="TX">Texas</option>
                    <option value="FL">Florida</option>
                    <option value="NY">New York</option>
                    <option value="WA">Washington</option>
                </select>
            </td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Zip Code:</strong></td>
            <td><input type="text" name="zipCode" size="10" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Price:</strong></td>
            <td><input type="text" name="price" size="15" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Bedrooms:</strong></td>
            <td><input type="text" name="bedrooms" size="5" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Bathrooms:</strong></td>
            <td><input type="text" name="bathrooms" size="5" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Square Feet:</strong></td>
            <td><input type="text" name="squareFeet" size="10" required></td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0"><strong>Property Type:</strong></td>
            <td>
                <select name="propertyType" required>
                    <option value="">Select Type</option>
                    <option value="Single Family">Single Family</option>
                    <option value="Condo">Condo</option>
                    <option value="Townhouse">Townhouse</option>
                    <option value="Multi-Family">Multi-Family</option>
                </select>
            </td>
        </tr>
        <tr>
            <td bgcolor="#f0f0f0" valign="top"><strong>Description:</strong></td>
            <td><textarea name="description" rows="6" cols="60" required></textarea></td>
        </tr>
        <tr>
            <td colspan="2" align="center">
                <input type="submit" value="Add Property" style="background-color: #003366; color: white; padding: 10px 20px; font-weight: bold; border: none; cursor: pointer;">
                <input type="button" value="Cancel" onclick="window.location='/agents/dashboard.asp'" style="background-color: #666; color: white; padding: 10px 20px; font-weight: bold; border: none; cursor: pointer;">
            </td>
        </tr>
    </table>
</form>

<!-- #include file="../includes/footer.asp" -->
