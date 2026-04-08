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

' Handle file upload using FileSystemObject - no validation
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim fso, uploadFolder, fileName, filePath, caption
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    
    uploadFolder = Server.MapPath("/images/properties/")
    
    ' Create folder if it doesn't exist
    If Not fso.FolderExists(uploadFolder) Then
        fso.CreateFolder(uploadFolder)
    End If
    
    ' Simplified file upload simulation (in real Classic ASP this would use a component)
    fileName = "property_" & propertyID & "_" & Year(Now()) & Month(Now()) & Day(Now()) & Hour(Now()) & Minute(Now()) & Second(Now()) & ".jpg"
    filePath = "/images/properties/" & fileName
    caption = Request.Form("caption")
    
    ' Insert photo record
    Dim conn, sql
    Set conn = GetConnection()
    
    ' Get max sort order
    Dim rs
    sql = "SELECT ISNULL(MAX(SortOrder), 0) + 1 as NextSort FROM PropertyPhotos WHERE PropertyID = " & propertyID
    Set rs = conn.Execute(sql)
    Dim sortOrder
    sortOrder = rs("NextSort")
    rs.Close
    Set rs = Nothing
    
    ' SQL injection vulnerable INSERT
    sql = "INSERT INTO PropertyPhotos (PropertyID, FilePath, Caption, SortOrder) VALUES (" & _
          propertyID & ", '" & filePath & "', '" & caption & "', " & sortOrder & ")"
    
    conn.Execute sql
    
    message = "Photo uploaded successfully! (Simulated)"
    messageClass = "success"
    
    conn.Close
    Set conn = Nothing
    Set fso = Nothing
End If

' Get property details
Dim conn, rs, sql
Set conn = GetConnection()

sql = "SELECT Address, City, State FROM Properties WHERE PropertyID = " & propertyID
Set rs = conn.Execute(sql)

If rs.EOF Then
    Response.Write "<p class='error'>Property not found.</p>"
    rs.Close
    Set rs = Nothing
    conn.Close
    Set conn = Nothing
    Response.End
End If

Dim propertyAddress
propertyAddress = rs("Address") & ", " & rs("City") & ", " & rs("State")
rs.Close
Set rs = Nothing
%>

<h1>Manage Property Photos</h1>
<h3><%= propertyAddress %></h3>

<% If message <> "" Then %>
    <p class="<%= messageClass %>"><%= message %></p>
<% End If %>

<h2>Upload New Photo</h2>
<form method="POST" action="photos.asp?id=<%= propertyID %>" enctype="multipart/form-data">
    <table border="0" cellpadding="5" cellspacing="0">
        <tr>
            <td>Photo File:</td>
            <td><input type="file" name="photoFile" accept="image/*"></td>
        </tr>
        <tr>
            <td>Caption:</td>
            <td><input type="text" name="caption" size="50"></td>
        </tr>
        <tr>
            <td colspan="2" align="center">
                <input type="submit" value="Upload Photo" style="background-color: #003366; color: white; padding: 8px 15px; font-weight: bold; border: none; cursor: pointer;">
            </td>
        </tr>
    </table>
</form>

<h2>Current Photos</h2>

<%
sql = "SELECT PhotoID, FilePath, Caption, SortOrder FROM PropertyPhotos WHERE PropertyID = " & propertyID & " ORDER BY SortOrder"
Set rs = conn.Execute(sql)

If Not rs.EOF Then
%>
    <table border="1" cellpadding="10" cellspacing="0" style="border-collapse: collapse;">
        <tr bgcolor="#f0f0f0">
            <th>Photo</th>
            <th>Caption</th>
            <th>Sort Order</th>
            <th>Actions</th>
        </tr>
        <%
        Do While Not rs.EOF
        %>
        <tr>
            <td align="center">
                <img src="<%= rs("FilePath") %>" width="150" height="100" alt="<%= rs("Caption") %>" style="border: 1px solid #999;">
            </td>
            <td><%= rs("Caption") %></td>
            <td align="center"><%= rs("SortOrder") %></td>
            <td align="center">
                <a href="?id=<%= propertyID %>&delete=<%= rs("PhotoID") %>" onclick="return confirm('Delete this photo?');" style="color: red;">Delete</a>
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
    <p>No photos uploaded for this property yet.</p>
<%
End If

' Handle photo deletion
If Request.QueryString("delete") <> "" Then
    Dim photoID
    photoID = Request.QueryString("delete")
    sql = "DELETE FROM PropertyPhotos WHERE PhotoID = " & photoID & " AND PropertyID = " & propertyID
    conn.Execute sql
    Response.Redirect "photos.asp?id=" & propertyID
End If

rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing
%>

<p>
    <a href="/agents/dashboard.asp" style="background-color: #666; color: white; padding: 8px 15px; text-decoration: none;">Back to Dashboard</a>
</p>

<!-- #include file="../includes/footer.asp" -->
