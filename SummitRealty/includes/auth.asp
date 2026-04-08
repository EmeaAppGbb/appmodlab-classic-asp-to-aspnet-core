<%
Sub RequireAuth()
    On Error Resume Next
    If Session("Authenticated") <> True Then
        Response.Redirect "/admin/login.asp?returnUrl=" & Server.URLEncode(Request.ServerVariables("SCRIPT_NAME"))
        Response.End
    End If
End Sub

Sub RequireRole(requiredRole)
    On Error Resume Next
    Call RequireAuth()
    If Session("Role") <> requiredRole And Session("Role") <> "Admin" Then
        Response.Write "<p class='error'>Access denied. Insufficient privileges.</p>"
        Response.End
    End If
End Sub
%>
