Add-Type -AssemblyName PresentationFramework # term:jira

$Window = New-Object Windows.Window
$Window.Height = "670"
$Window.Width = "700"
$Window.Title = "JIRA UI"
$window.WindowStartupLocation="CenterScreen"

# Create a grid container with 2 rows, one for the buttons, one for the datagrid
$Grid =  New-Object Windows.Controls.Grid
$Row1 = New-Object Windows.Controls.RowDefinition
$Row2 = New-Object Windows.Controls.RowDefinition
$Row1.Height = "70"
$Row2.Height = "100*"
$Grid.RowDefinitions.Add($Row1)
$Grid.RowDefinitions.Add($Row2)


# Create a button to get running Processes
$BtnJira = New-Object Windows.Controls.Button
$BtnJira.SetValue([Windows.Controls.Grid]::RowProperty, 0)
$BtnJira.Height = "50"
$BtnJira.Width = "150"
$BtnJira.Margin = "10,10,10,10"
$BtnJira.HorizontalAlignment = "Left"
$BtnJira.VerticalAlignment = "Top"
$BtnJira.Content = "Get Issues"
$BtnJira.Background = "Aquamarine"
 
# Create a DataGrid
$DataGrid = New-Object Windows.Controls.DataGrid
$DataGrid.SetValue([Windows.Controls.Grid]::RowProperty, 1)
$DataGrid.MinHeight = "100"
$DataGrid.MinWidth = "100"
$DataGrid.Margin = "10,0,10,10"
$DataGrid.HorizontalAlignment = "Stretch"
$DataGrid.VerticalAlignment = "Stretch"
$DataGrid.VerticalScrollBarVisibility = "Auto"
$DataGrid.GridLinesVisibility = "none"
$DataGrid.IsReadOnly = $true
 
# Add the elements to the relevant parent control
$Grid.AddChild($DataGrid)
$Grid.AddChild($BtnJira)
$window.Content = $Grid


# Add an event on the Get Processes button
$BtnJira.Add_Click({
    $e = (Get-KPEntry -Title 'jira-token' -AsPlainText)
    $jql = $(
        'assignee=currentuser()'
        "status not in ('Closed')"
    ) -join ' and '
    $jql = UrlEncode $jql

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $e.username,$e.password)))
    $r = Invoke-RestMethod -Uri https://mypinpad.atlassian.net/rest/api/2/search?jql=$jql -Method Get -Headers @{ Authorization=("Basic {0}" -f $base64AuthInfo) }
    $DataGrid.ItemsSource = $r.issues | select key,@{n='Status';e={$_.fields.status.Name}},@{n='Priority';e={$_.fields.priority.name}},@{n='summary';e={$_.fields.summary}},@{n='LastComment';e={Get-JiraIssueLastComment $_.id}}
})

$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0) 
 
$app = [Windows.Application]::new()

$app.Run($Window) # term:jira