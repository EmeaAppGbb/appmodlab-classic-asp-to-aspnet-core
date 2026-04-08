<!-- #include file="../includes/conn.asp" -->
<!-- #include file="../includes/functions.asp" -->
<!-- #include file="../includes/header.asp" -->
<%
On Error Resume Next

Dim message, messageClass, propertyID
message = ""
messageClass = ""
propertyID = Request.QueryString("propertyID")

If propertyID = "" Then
    propertyID = Request.Form("propertyID")
End If

If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim clientName, clientEmail, appointmentDate, appointmentTime, notes, agentID
    clientName = Request.Form("clientName")
    clientEmail = Request.Form("clientEmail")
    appointmentDate = Request.Form("appointmentDate")
    appointmentTime = Request.Form("appointmentTime")
    notes = Request.Form("notes")
    
    ' Get agent ID for the property
    Dim conn, rs, sql
    Set conn = GetConnection()
    
    sql = "SELECT AgentID FROM Properties WHERE PropertyID = " & propertyID
    Set rs = conn.Execute(sql)
    If Not rs.EOF Then
        agentID = rs("AgentID")
    Else
        agentID = 1
    End If
    rs.Close
    Set rs = Nothing
    
    ' Combine date and time
    Dim fullDateTime
    fullDateTime = appointmentDate & " " & appointmentTime
    
    ' SQL injection vulnerable INSERT
    sql = "INSERT INTO Appointments (PropertyID, AgentID, ClientName, ClientEmail, AppointmentDate, Notes, Status) " & _
          "VALUES (" & propertyID & ", " & agentID & ", '" & clientName & "', '" & clientEmail & "', " & _
          "'" & fullDateTime & "', '" & notes & "', 'Scheduled')"
    
    conn.Execute sql
    
    message = "Your appointment has been scheduled! We will send you a confirmation email shortly."
    messageClass = "success"
    
    conn.Close
    Set conn = Nothing
End If

' Get property details
If propertyID <> "" Then
    Dim conn2, rs2, sql2
    Set conn2 = GetConnection()
    
    sql2 = "SELECT Address, City, State FROM Properties WHERE PropertyID = " & propertyID
    Set rs2 = conn2.Execute(sql2)
    
    If Not rs2.EOF Then
        Dim propertyAddress
        propertyAddress = rs2("Address") & ", " & rs2("City") & ", " & rs2("State")
    Else
        propertyAddress = "Unknown Property"
    End If
    
    rs2.Close
    Set rs2 = Nothing
    conn2.Close
    Set conn2 = Nothing
End If
%>

<h1>Schedule a Property Viewing</h1>

<% If propertyID <> "" Then %>
    <h3>Property: <%= propertyAddress %></h3>
<% End If %>

<% If message <> "" Then %>
    <p class="<%= messageClass %>"><%= message %></p>
<% Else %>
    <p>Schedule an appointment to view this property. One of our agents will confirm your appointment.</p>
<% End If %>

<form method="POST" action="schedule.asp">
    <input type="hidden" name="propertyID" value="<%= propertyID %>">
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
            <td><strong>Preferred Date:</strong></td>
            <td><input type="date" name="appointmentDate" required></td>
        </tr>
        <tr>
            <td><strong>Preferred Time:</strong></td>
            <td>
                <select name="appointmentTime" required>
                    <option value="">Select Time</option>
                    <option value="09:00:00">9:00 AM</option>
                    <option value="10:00:00">10:00 AM</option>
                    <option value="11:00:00">11:00 AM</option>
                    <option value="12:00:00">12:00 PM</option>
                    <option value="13:00:00">1:00 PM</option>
                    <option value="14:00:00">2:00 PM</option>
                    <option value="15:00:00">3:00 PM</option>
                    <option value="16:00:00">4:00 PM</option>
                    <option value="17:00:00">5:00 PM</option>
                </select>
            </td>
        </tr>
        <tr>
            <td valign="top"><strong>Notes:</strong></td>
            <td><textarea name="notes" rows="4" cols="38"></textarea></td>
        </tr>
        <tr>
            <td colspan="2" align="center">
                <input type="submit" value="Schedule Appointment" style="background-color: #003366; color: white; padding: 10px 20px; font-weight: bold; border: none; cursor: pointer;">
                <input type="button" value="Cancel" onclick="history.back()" style="background-color: #666; color: white; padding: 10px 20px; font-weight: bold; border: none; cursor: pointer;">
            </td>
        </tr>
    </table>
</form>

<!-- #include file="../includes/footer.asp" -->
