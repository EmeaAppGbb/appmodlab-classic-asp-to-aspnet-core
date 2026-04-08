<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
    <title><%= Application("AppName") %></title>
    <style type="text/css">
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4; }
        .header { background-color: #003366; color: white; padding: 20px; }
        .header h1 { margin: 0; font-size: 28px; }
        .header p { margin: 5px 0 0 0; font-size: 14px; }
        .nav { background-color: #004080; padding: 0; }
        .nav table { width: 100%; border-collapse: collapse; }
        .nav td { padding: 10px 20px; border-right: 1px solid #003366; }
        .nav a { color: white; text-decoration: none; font-weight: bold; }
        .nav a:hover { color: #ffcc00; }
        .container { width: 95%; margin: 20px auto; background-color: white; padding: 20px; }
        .error { color: red; font-weight: bold; }
        .success { color: green; font-weight: bold; }
    </style>
</head>
<body>
<div class="header">
    <h1>Summit Realty Group</h1>
    <p>Your Premier Real Estate Partner Since 1985</p>
</div>
<div class="nav">
    <table>
        <tr>
            <td><a href="/default.asp">Home</a></td>
            <td><a href="/listings/search.asp">Search Properties</a></td>
            <td><a href="/agents/directory.asp">Our Agents</a></td>
            <td><a href="/inquiries/contact.asp">Contact Us</a></td>
            <% If Session("Authenticated") = True Then %>
                <td><a href="/agents/dashboard.asp">Dashboard</a></td>
                <td><a href="/admin/login.asp?action=logout">Logout (<%= Session("Username") %>)</a></td>
            <% Else %>
                <td><a href="/admin/login.asp">Agent Login</a></td>
            <% End If %>
        </tr>
    </table>
</div>
<div class="container">
