<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/auth.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next
Call RequireRole("Admin")

Dim conn
Set conn = GetConnection()

' Handle user addition
If Request.ServerVariables("REQUEST_METHOD") = "POST" And Request.Form("action") = "add" Then
    Dim username, password, role, agentID
    username = Request.Form("username")
    password = Request.Form("password")
    role = Request.Form("role")
    agentID = Request.Form("agentID")
    
    ' SQL injection vulnerable INSERT - plain text password
    Dim sql
    sql = "INSERT INTO Users (Username, Password, Role, AgentID, LastLogin) VALUES ('" & _
          username & "', '" & password & "', '" & role & "', " & agentID & ", NULL)"
    
    conn.Execute sql
End If

' Get all users
Dim rs, sql
sql = "SELECT u.UserID, u.Username, u.Password, u.Role, u.LastLogin, a.FirstName, a.LastName " & _
      "FROM Users u LEFT JOIN Agents a ON u.AgentID = a.AgentID ORDER BY u.Username"
Set rs = conn.Execute(sql)
%>

<h1>User Management</h1>

<h2>Current Users</h2>

<table width="100%" border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse;">
    <tr bgcolor="#f0f0f0">
        <th>Username</th>
        <th>Password</th>
        <th>Role</th>
        <th>Agent</th>
        <th>Last Login</th>
    </tr>
    <%
    Do While Not rs.EOF
    %>
    <tr>
        <td><%= rs("Username") %></td>
        <td><%= rs("Password") %></td>
        <td><%= rs("Role") %></td>
        <td>
            <% If Not IsNull(rs("FirstName")) Then %>
                <%= rs("FirstName") %> <%= rs("LastName") %>
            <% Else %>
                <em>N/A</em>
            <% End If %>
        </td>
        <td>
            <% If Not IsNull(rs("LastLogin")) Then %>
                <%= FormatDate(rs("LastLogin")) %>
            <% Else %>
                <em>Never</em>
            <% End If %>
        </td>
    </tr>
    <%
        rs.MoveNext
    Loop
    %>
</table>

<%
rs.Close
Set rs = Nothing
%>

<h2>Add New User</h2>

<form method="POST" action="users.asp">
    <input type="hidden" name="action" value="add">
    <table border="0" cellpadding="5" cellspacing="0">
        <tr>
            <td><strong>Username:</strong></td>
            <td><input type="text" name="username" size="30" required></td>
        </tr>
        <tr>
            <td><strong>Password:</strong></td>
            <td><input type="text" name="password" size="30" required> <em>(stored in plain text)</em></td>
        </tr>
        <tr>
            <td><strong>Role:</strong></td>
            <td>
                <select name="role" required>
                    <option value="Agent">Agent</option>
                    <option value="Admin">Admin</option>
                </select>
            </td>
        </tr>
        <tr>
            <td><strong>Agent:</strong></td>
            <td>
                <select name="agentID" required>
                    <option value="">Select Agent</option>
                    <%
                    Dim rsAgents, sqlAgents
                    sqlAgents = "SELECT AgentID, FirstName, LastName FROM Agents ORDER BY LastName, FirstName"
                    Set rsAgents = conn.Execute(sqlAgents)
                    Do While Not rsAgents.EOF
                    %>
                        <option value="<%= rsAgents("AgentID") %>"><%= rsAgents("FirstName") %> <%= rsAgents("LastName") %></option>
                    <%
                        rsAgents.MoveNext
                    Loop
                    rsAgents.Close
                    Set rsAgents = Nothing
                    %>
                </select>
            </td>
        </tr>
        <tr>
            <td colspan="2" align="center">
                <input type="submit" value="Add User" style="background-color: #003366; color: white; padding: 8px 15px; font-weight: bold; border: none; cursor: pointer;">
            </td>
        </tr>
    </table>
</form>

<%
conn.Close
Set conn = Nothing
%>

<p style="margin-top: 20px;">
    <a href="/agents/dashboard.asp" style="background-color: #666; color: white; padding: 8px 15px; text-decoration: none;">Back to Dashboard</a>
</p>

<!-- #include file="../includes/footer.asp" -->
