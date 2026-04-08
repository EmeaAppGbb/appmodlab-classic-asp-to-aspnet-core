<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next

Dim message, messageClass, propertyID
message = ""
messageClass = ""
propertyID = Request.Form("propertyID")

If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim clientName, clientEmail, clientPhone, messageText, agentID
    clientName = Request.Form("clientName")
    clientEmail = Request.Form("clientEmail")
    clientPhone = Request.Form("clientPhone")
    messageText = Request.Form("message")
    
    ' Get agent ID for the property
    Dim conn, rs, sql
    Set conn = GetConnection()
    
    If propertyID <> "" Then
        sql = "SELECT AgentID FROM Properties WHERE PropertyID = " & propertyID
        Set rs = conn.Execute(sql)
        If Not rs.EOF Then
            agentID = rs("AgentID")
        Else
            agentID = 1 ' Default to first agent
        End If
        rs.Close
        Set rs = Nothing
    Else
        agentID = 1 ' Default to first agent
    End If
    
    ' SQL injection vulnerable INSERT
    sql = "INSERT INTO Inquiries (PropertyID, ClientName, ClientEmail, ClientPhone, Message, InquiryDate, Status, AgentID) " & _
          "VALUES ("
    
    If propertyID <> "" Then
        sql = sql & propertyID & ", "
    Else
        sql = sql & "NULL, "
    End If
    
    sql = sql & "'" & clientName & "', '" & clientEmail & "', '" & clientPhone & "', '" & messageText & "', " & _
          "GETDATE(), 'Pending', " & agentID & ")"
    
    conn.Execute sql
    
    ' Send email using CDO - hardcoded SMTP credentials
    Dim objCDO
    Set objCDO = Server.CreateObject("CDO.Message")
    objCDO.From = "noreply@summitrealty.com"
    objCDO.To = clientEmail
    objCDO.Subject = "Inquiry Received - Summit Realty Group"
    objCDO.TextBody = "Dear " & clientName & "," & vbCrLf & vbCrLf & _
                      "Thank you for your inquiry. One of our agents will contact you shortly." & vbCrLf & vbCrLf & _
                      "Best regards," & vbCrLf & "Summit Realty Group"
    
    objCDO.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2
    objCDO.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "smtp.summitrealty.com"
    objCDO.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25
    objCDO.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = 1
    objCDO.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusername") = "smtp_user"
    objCDO.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendpassword") = "smtp_pass123"
    objCDO.Configuration.Fields.Update
    
    ' Don't actually send in this demo
    ' objCDO.Send
    
    Set objCDO = Nothing
    
    message = "Thank you for your inquiry! We will contact you shortly."
    messageClass = "success"
    
    conn.Close
    Set conn = Nothing
End If
%>

<h1>Contact Us</h1>

<% If message <> "" Then %>
    <p class="<%= messageClass %>"><%= message %></p>
<% Else %>
    <p>Have a question about a property or our services? Fill out the form below and one of our agents will get back to you.</p>
<% End If %>

<form method="POST" action="contact.asp">
    <input type="hidden" name="propertyID" value="<%= Request.QueryString("propertyID") %>">
    <table border="0" cellpadding="8" cellspacing="0" width="600">
        <tr>
            <td width="150"><strong>Your Name:</strong></td>
            <td><input type="text" name="clientName" size="40" required></td>
        </tr>
        <tr>
            <td><strong>Email:</strong></td>
            <td><input type="email" name="clientEmail" size="40" required></td>
        </tr>
        <tr>
            <td><strong>Phone:</strong></td>
            <td><input type="text" name="clientPhone" size="40"></td>
        </tr>
        <tr>
            <td valign="top"><strong>Message:</strong></td>
            <td><textarea name="message" rows="8" cols="38" required></textarea></td>
        </tr>
        <tr>
            <td colspan="2" align="center">
                <input type="submit" value="Send Inquiry" style="background-color: #003366; color: white; padding: 10px 20px; font-weight: bold; border: none; cursor: pointer;">
                <input type="reset" value="Clear Form" style="background-color: #666; color: white; padding: 10px 20px; font-weight: bold; border: none; cursor: pointer;">
            </td>
        </tr>
    </table>
</form>

<!-- #include file="../includes/footer.asp" -->
