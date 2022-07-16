function New-ADTestUsers {
	$testUsers = @("Robb Stark", "Theon Greyjoy", "Ned Stark", "Aria Stark")
	foreach ($user in $testUsers){
		New-ADUser -Name $user -Enabled $False
	}
}