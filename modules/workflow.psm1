workflow setupADForrest {
	param (
		[Parameter (Mandatory = $True, HelpMessage = "ComputerName or IP address.")]
		[string]$computername,

		[Parameter (Mandatory = $True, HelpMessage = "Password for DSRM.")]
		[securestring]$password
	)

	# Get hostname for domain controller and rename
	$domConHostName = Read-Host "Hostname for Domain Controller"
	Write-Verbose "Renaming computer..."
	Rename-Computer -NewName $domConHostName -Force -PassThru
	Restart-Computer -Wait

	# Installing AD Domain Services
	Write-Verbose "Installing `"AD-Domain-Services`""
	Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

	# AD Forrest parameters
	$params = @{
		CreateDnsDelegation           = $false
		DatabasePath                  = 'C:\Windows\NTDS'
		DomainMode                    = 'WinThreshold'
		DomainName                    = 'testbed.local'
		ForestMode                    = 'WinThreshold'
		InstallDns                    = $true
		LogPath                       = 'C:\Windows\NTDS'
		NoRebootOnCompletion          = $true
		SafeModeAdministratorPassword = $password
		SysvolPath                    = 'C:\Windows\SYSVOL'
		Force                         = $true
	}

	# Create Forrest
	Install-ADDSForest @params
	Restart-Computer -Wait

	New-ADTestUsers

}

function New-ADTestUsers {
	$testUsers = @("Robb Stark", "Theon Greyjoy", "Ned Stark", "Aria Stark")
	foreach ($user in $testUsers){
		New-ADUser -Name $user -Enabled $False
	}
}