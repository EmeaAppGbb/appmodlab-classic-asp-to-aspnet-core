<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next

Dim conn, rs, sql
Set conn = GetConnection()

sql = "SELECT AgentID, FirstName, LastName, Email, Phone, PhotoPath, Bio FROM Agents ORDER BY LastName, FirstName"
Set rs = conn.Execute(sql)
%>

<h1>Our Real Estate Agents</h1>
<p>Meet our team of experienced real estate professionals dedicated to helping you find your dream home.</p>

<table width="100%" border="0" cellpadding="15" cellspacing="0">
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
                <td width="180" align="center" valign="top">
                    <% If Not IsNull(rs("PhotoPath")) And rs("PhotoPath") <> "" Then %>
                        <img src="<%= rs("PhotoPath") %>" width="150" height="150" alt="<%= rs("FirstName") %> <%= rs("LastName") %>" style="border: 2px solid #003366; border-radius: 75px;">
                    <% Else %>
                        <img src="/images/no-agent-photo.jpg" width="150" height="150" alt="Agent Photo" style="border: 2px solid #003366; border-radius: 75px;">
                    <% End If %>
                </td>
                <td valign="top">
                    <h2 style="margin: 0 0 10px 0;"><%= rs("FirstName") %> <%= rs("LastName") %></h2>
                    <p style="margin: 5px 0;">
                        <strong>Email:</strong> <a href="mailto:<%= rs("Email") %>"><%= rs("Email") %></a><br>
                        <strong>Phone:</strong> <%= rs("Phone") %>
                    </p>
                    <p><%= TruncateText(rs("Bio"), 150) %></p>
                    <p>
                        <a href="profile.asp?id=<%= rs("AgentID") %>" style="background-color: #003366; color: white; padding: 6px 12px; text-decoration: none; display: inline-block;">View Profile</a>
                    </p>
                </td>
            </tr>
        </table>
    </td>
<%
    counter = counter + 1
    If counter Mod 2 = 0 Then
        Response.Write "</tr>"
    End If
    rs.MoveNext
Loop

If counter Mod 2 <> 0 Then
    Response.Write "</tr>"
End If

rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing
%>
</table>

<!-- #include file="../includes/footer.asp" -->
