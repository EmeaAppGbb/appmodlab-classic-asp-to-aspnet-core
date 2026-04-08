<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next

' Handle logout
If Request.QueryString("action") = "logout" Then
    Session("Authenticated") = False
    Session("UserID") = 0
    Session("Username") = ""
    Session("Role") = ""
    Response.Redirect "/default.asp"
    Response.End
End If

Dim message, messageClass
message = ""
messageClass = ""

If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim username, password
    username = Request.Form("username")
    password = Request.Form("password")
    
    ' SQL injection vulnerability - passwords in plain text
    Dim conn, rs, sql
    Set conn = GetConnection()
    
    sql = "SELECT u.UserID, u.Username, u.Role, u.AgentID, u.Password FROM Users u WHERE u.Username = '" & username & "' AND u.Password = '" & password & "'"
    
    Set rs = conn.Execute(sql)
    
    If Not rs.EOF Then
        ' Update last login
        Dim updateSql
        updateSql = "UPDATE Users SET LastLogin = GETDATE() WHERE UserID = " & rs("UserID")
        conn.Execute updateSql
        
        Session("Authenticated") = True
        Session("UserID") = rs("AgentID")
        Session("Username") = rs("Username")
        Session("Role") = rs("Role")
        
        Dim returnUrl
        returnUrl = Request.QueryString("returnUrl")
        If returnUrl <> "" Then
            Response.Redirect returnUrl
        Else
            Response.Redirect "/agents/dashboard.asp"
        End If
        Response.End
    Else
        message = "Invalid username or password. Please try again."
        messageClass = "error"
    End If
    
    rs.Close
    Set rs = Nothing
    conn.Close
    Set conn = Nothing
End If
%>

<h1>Agent Login</h1>

<% If message <> "" Then %>
    <p class="<%= messageClass %>"><%= message %></p>
<% End If %>

<form method="POST" action="login.asp">
    <table border="0" cellpadding="10" cellspacing="0" width="400" style="margin: 0 auto; background-color: #f0f0f0; border: 2px solid #003366;">
        <tr>
            <td colspan="2" align="center" bgcolor="#003366" style="color: white; font-weight: bold; font-size: 16px;">
                Agent Login
            </td>
        </tr>
        <tr>
            <td width="120"><strong>Username:</strong></td>
            <td><input type="text" name="username" size="25" required autofocus></td>
        </tr>
        <tr>
            <td><strong>Password:</strong></td>
            <td><input type="password" name="password" size="25" required></td>
        </tr>
        <tr>
            <td colspan="2" align="center">
                <input type="submit" value="Login" style="background-color: #003366; color: white; padding: 10px 30px; font-weight: bold; border: none; cursor: pointer;">
            </td>
        </tr>
        <tr>
            <td colspan="2" align="center" style="font-size: 11px; color: #666;">
                Demo credentials: admin / password123
            </td>
        </tr>
    </table>
</form>

<!-- #include file="../includes/footer.asp" -->
