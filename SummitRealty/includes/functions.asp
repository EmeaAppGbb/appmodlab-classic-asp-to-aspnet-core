<%
Function FormatCurrency(value)
    On Error Resume Next
    FormatCurrency = "$" & FormatNumber(value, 0)
End Function

Function FormatDate(dt)
    On Error Resume Next
    FormatDate = Month(dt) & "/" & Day(dt) & "/" & Year(dt)
End Function

Function SanitizeInput(str)
    ' Intentionally poor sanitization - just replace single quotes with two single quotes
    On Error Resume Next
    If IsNull(str) Or str = "" Then
        SanitizeInput = ""
    Else
        SanitizeInput = Replace(str, "'", "''")
    End If
End Function

Function GetQueryString(paramName, defaultValue)
    On Error Resume Next
    Dim val
    val = Request.QueryString(paramName)
    If val = "" Or IsNull(val) Then
        GetQueryString = defaultValue
    Else
        GetQueryString = val
    End If
End Function

Function TruncateText(text, maxLen)
    On Error Resume Next
    If Len(text) > maxLen Then
        TruncateText = Left(text, maxLen) & "..."
    Else
        TruncateText = text
    End If
End Function
%>
