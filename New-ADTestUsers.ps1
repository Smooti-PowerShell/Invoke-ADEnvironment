#Getting information from the json file
$config = Get-Content "$($env:PSScriptRoot)\config.json" | ConvertFrom-Json

# Create test users
$adCreds = Import-Clixml "C:\tempCred.xml"
$testUsers = @("Robb Stark", "Theon Greyjoy", "Ned Stark", "Aria Stark")
foreach ($user in $testUsers) {
	New-ADUser -Name $user -Enabled $False -Credential $adCreds
}

# Cleanup
Remove-Item -Force "C:\tempCred.xml"
Unregister-ScheduledTask -TaskName $config.InvokeTask.TaskName -Confirm:$false