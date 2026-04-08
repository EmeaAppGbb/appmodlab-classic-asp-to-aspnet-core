<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/auth.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next
Call RequireAuth()

Dim conn, rs, sql, agentID
Set conn = GetConnection()
agentID = Session("UserID")

' Handle status update
If Request.QueryString("action") = "update" And Request.QueryString("id") <> "" Then
    Dim inquiryID, newStatus
    inquiryID = Request.QueryString("id")
    newStatus = Request.QueryString("status")
    
    sql = "UPDATE Inquiries SET Status = '" & newStatus & "' WHERE InquiryID = " & inquiryID & " AND AgentID = " & agentID
    conn.Execute sql
End If

' Get all inquiries for this agent
sql = "SELECT i.InquiryID, i.PropertyID, i.ClientName, i.ClientEmail, i.ClientPhone, i.Message, " & _
      "i.InquiryDate, i.Status, p.Address, p.City, p.State " & _
      "FROM Inquiries i LEFT JOIN Properties p ON i.PropertyID = p.PropertyID " & _
      "WHERE i.AgentID = " & agentID & " ORDER BY i.InquiryDate DESC"
Set rs = conn.Execute(sql)
%>

<h1>Client Inquiries</h1>

<%
If Not rs.EOF Then
%>
    <table width="100%" border="1" cellpadding="10" cellspacing="0" style="border-collapse: collapse;">
        <tr bgcolor="#f0f0f0">
            <th>Date</th>
            <th>Client</th>
            <th>Property</th>
            <th>Message</th>
            <th>Status</th>
            <th>Actions</th>
        </tr>
        <%
        Do While Not rs.EOF
            Dim statusColor
            Select Case rs("Status")
                Case "Pending"
                    statusColor = "#ff9900"
                Case "Contacted"
                    statusColor = "#3366cc"
                Case "Closed"
                    statusColor = "#009900"
                Case Else
                    statusColor = "#666666"
            End Select
        %>
        <tr>
            <td><%= FormatDate(rs("InquiryDate")) %></td>
            <td>
                <strong><%= rs("ClientName") %></strong><br>
                <small>
                    <a href="mailto:<%= rs("ClientEmail") %>"><%= rs("ClientEmail") %></a><br>
                    <%= rs("ClientPhone") %>
                </small>
            </td>
            <td>
                <% If Not IsNull(rs("PropertyID")) Then %>
                    <%= rs("Address") %><br>
                    <small><%= rs("City") %>, <%= rs("State") %></small><br>
                    <a href="/listings/detail.asp?id=<%= rs("PropertyID") %>">View Property</a>
                <% Else %>
                    <em>General Inquiry</em>
                <% End If %>
            </td>
            <td><%= TruncateText(rs("Message"), 100) %></td>
            <td align="center">
                <span style="background-color: <%= statusColor %>; color: white; padding: 4px 8px; font-weight: bold; border-radius: 3px;">
                    <%= rs("Status") %>
                </span>
            </td>
            <td align="center">
                <% If rs("Status") = "Pending" Then %>
                    <a href="?action=update&id=<%= rs("InquiryID") %>&status=Contacted">Mark Contacted</a>
                <% ElseIf rs("Status") = "Contacted" Then %>
                    <a href="?action=update&id=<%= rs("InquiryID") %>&status=Closed">Mark Closed</a>
                <% Else %>
                    <a href="?action=update&id=<%= rs("InquiryID") %>&status=Pending">Reopen</a>
                <% End If %>
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
    <p>No inquiries found.</p>
<%
End If

rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing
%>

<p style="margin-top: 20px;">
    <a href="/agents/dashboard.asp" style="background-color: #666; color: white; padding: 8px 15px; text-decoration: none;">Back to Dashboard</a>
</p>

<!-- #include file="../includes/footer.asp" -->
