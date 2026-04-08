<%
' Database connection string - hardcoded credentials
Dim connStr
connStr = "Provider=SQLOLEDB;Data Source=localhost\SQLEXPRESS;Initial Catalog=SummitRealty;User ID=sa;Password=P@ssw0rd123;"

Function GetConnection()
    On Error Resume Next
    Dim conn
    Set conn = Server.CreateObject("ADODB.Connection")
    conn.Open connStr
    Set GetConnection = conn
End Function
%>
