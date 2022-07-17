# Create test users
$adCreds = Import-Clixml "C:\tempCred.xml"
$testUsers = @("Robb Stark", "Theon Greyjoy", "Ned Stark", "Aria Stark")
foreach ($user in $testUsers) {
	New-ADUser -Name $user -Enabled $False -Credential $adCreds
}

# Cleanup temporary credential
Remove-Item -Force "C:\tempCred.xml"